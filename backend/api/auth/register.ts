import type { NextApiRequest, NextApiResponse } from 'next';
import { query } from '../../lib/db';
import { hashPassword, generateAccessToken, generateRefreshToken, generateSecureToken, hashToken } from '../../lib/auth';
import { withErrorHandler, allowMethods, checkRateLimit, getClientIp } from '../../lib/middleware';
import { isValidEmail, isValidPassword, sanitizeString } from '../../lib/validators';
import { sendVerificationEmail, sendWelcomeEmail } from '../../lib/email';

async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['POST'])) return;

  const clientIp = getClientIp(req);
  if (!checkRateLimit(`register_${clientIp}`, 10, 60_000)) {
    return res.status(429).json({ error: 'too_many_requests', message: 'Too many registration attempts. Please try again later.' });
  }

  const { email, password, fullName, countryCode, farmingType } = req.body || {};

  const cleanEmail = sanitizeString(email).toLowerCase();
  const cleanName = sanitizeString(fullName);

  if (!isValidEmail(cleanEmail)) {
    return res.status(400).json({ error: 'invalid_email', message: 'Please provide a valid email address.' });
  }

  const passwordCheck = isValidPassword(password || '');
  if (!passwordCheck.valid) {
    return res.status(400).json({ error: 'weak_password', message: passwordCheck.message });
  }

  // Check if user already exists
  const existing = await query('SELECT id FROM users WHERE email = $1', [cleanEmail]);
  if (existing.rowCount > 0) {
    return res.status(409).json({ error: 'email_exists', message: 'An account with this email address already exists.' });
  }

  const passwordHash = await hashPassword(password);

  // Insert User
  const insertResult = await query(
    `INSERT INTO users (email, password_hash, full_name, country_code, farming_type)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING id, email, full_name, role, subscription_tier, ai_credit_balance, created_at`,
    [cleanEmail, passwordHash, cleanName || null, countryCode || 'ZA', farmingType || 'livestock']
  );

  const user = insertResult.rows[0];

  // Generate Email Verification Token
  const verificationToken = generateSecureToken();
  const tokenExpiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24h

  await query(
    `INSERT INTO email_verifications (user_id, token, expires_at) VALUES ($1, $2, $3)`,
    [user.id, verificationToken, tokenExpiresAt]
  );

  // Send Verification & Welcome Emails
  await sendVerificationEmail(cleanEmail, verificationToken);
  await sendWelcomeEmail(cleanEmail, cleanName || 'Farmer');

  // Issue Tokens
  const tokenPayload = { userId: user.id, email: user.email, role: user.role };
  const accessToken = generateAccessToken(tokenPayload);
  const refreshToken = generateRefreshToken(tokenPayload);

  // Store hashed refresh token
  const refreshTokenHash = hashToken(refreshToken);
  const refreshExpiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30d

  await query(
    `INSERT INTO refresh_tokens (user_id, token_hash, device_info, ip_address, expires_at)
     VALUES ($1, $2, $3, $4, $5)`,
    [user.id, refreshTokenHash, req.headers['user-agent'] || 'unknown', clientIp, refreshExpiresAt]
  );

  // Audit Log
  await query(
    `INSERT INTO audit_logs (user_id, action, ip_address, user_agent, metadata)
     VALUES ($1, $2, $3, $4, $5)`,
    [user.id, 'register', clientIp, req.headers['user-agent'], JSON.stringify({ email: cleanEmail })]
  );

  return res.status(201).json({
    message: 'User registered successfully. Verification email sent.',
    accessToken,
    refreshToken,
    user: {
      id: user.id,
      email: user.email,
      fullName: user.full_name,
      role: user.role,
      subscriptionTier: user.subscription_tier,
      aiCreditBalance: user.ai_credit_balance,
      emailVerified: false,
    },
  });
}

export default withErrorHandler(handler);
