import type { NextApiRequest, NextApiResponse } from 'next';
import { query } from '../../lib/db';
import { verifyPassword, generateAccessToken, generateRefreshToken, hashToken } from '../../lib/auth';
import { withErrorHandler, allowMethods, checkRateLimit, getClientIp } from '../../lib/middleware';
import { sanitizeString } from '../../lib/validators';

async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['POST'])) return;

  const clientIp = getClientIp(req);
  if (!checkRateLimit(`login_${clientIp}`, 10, 60_000)) {
    return res.status(429).json({ error: 'too_many_requests', message: 'Too many login attempts. Please try again later.' });
  }

  const { email, password } = req.body || {};
  const cleanEmail = sanitizeString(email).toLowerCase();

  if (!cleanEmail || !password) {
    return res.status(400).json({ error: 'missing_fields', message: 'Email and password are required.' });
  }

  // Fetch user
  const result = await query(
    `SELECT id, email, password_hash, full_name, role, subscription_tier, ai_credit_balance, email_verified, deleted_at
     FROM users WHERE email = $1`,
    [cleanEmail]
  );

  if (result.rowCount === 0) {
    // Audit failed attempt
    await query(
      `INSERT INTO audit_logs (action, ip_address, user_agent, metadata, success)
       VALUES ($1, $2, $3, $4, FALSE)`,
      ['login_failed', clientIp, req.headers['user-agent'], JSON.stringify({ email: cleanEmail, reason: 'user_not_found' })]
    );
    return res.status(401).json({ error: 'invalid_credentials', message: 'Invalid email or password.' });
  }

  const user = result.rows[0];

  if (user.deleted_at) {
    return res.status(403).json({ error: 'account_deleted', message: 'This account has been deleted.' });
  }

  const isPasswordValid = await verifyPassword(password, user.password_hash);
  if (!isPasswordValid) {
    await query(
      `INSERT INTO audit_logs (user_id, action, ip_address, user_agent, metadata, success)
       VALUES ($1, $2, $3, $4, $5, FALSE)`,
      [user.id, 'login_failed', clientIp, req.headers['user-agent'], JSON.stringify({ reason: 'wrong_password' })]
    );
    return res.status(401).json({ error: 'invalid_credentials', message: 'Invalid email or password.' });
  }

  // Update last_login_at
  await query('UPDATE users SET last_login_at = CURRENT_TIMESTAMP WHERE id = $1', [user.id]);

  // Issue Tokens
  const tokenPayload = { userId: user.id, email: user.email, role: user.role };
  const accessToken = generateAccessToken(tokenPayload);
  const refreshToken = generateRefreshToken(tokenPayload);

  // Save Refresh Token Hash
  const refreshTokenHash = hashToken(refreshToken);
  const refreshExpiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

  await query(
    `INSERT INTO refresh_tokens (user_id, token_hash, device_info, ip_address, expires_at)
     VALUES ($1, $2, $3, $4, $5)`,
    [user.id, refreshTokenHash, req.headers['user-agent'] || 'unknown', clientIp, refreshExpiresAt]
  );

  // Audit Log
  await query(
    `INSERT INTO audit_logs (user_id, action, ip_address, user_agent)
     VALUES ($1, 'login', $2, $3)`,
    [user.id, clientIp, req.headers['user-agent']]
  );

  return res.status(200).json({
    message: 'Login successful.',
    accessToken,
    refreshToken,
    user: {
      id: user.id,
      email: user.email,
      fullName: user.full_name,
      role: user.role,
      subscriptionTier: user.subscription_tier,
      aiCreditBalance: user.ai_credit_balance,
      emailVerified: user.email_verified,
    },
  });
}

export default withErrorHandler(handler);
