import type { NextApiRequest, NextApiResponse } from 'next';
import { query } from '../../lib/db';
import { generateSecureToken } from '../../lib/auth';
import { withErrorHandler, allowMethods, checkRateLimit, getClientIp } from '../../lib/middleware';
import { sanitizeString, isValidEmail } from '../../lib/validators';
import { sendPasswordResetEmail } from '../../lib/email';

async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['POST'])) return;

  const clientIp = getClientIp(req);
  if (!checkRateLimit(`forgot_password_${clientIp}`, 5, 60_000)) {
    return res.status(429).json({ error: 'too_many_requests', message: 'Too many password reset requests. Please wait a minute.' });
  }

  const { email } = req.body || {};
  const cleanEmail = sanitizeString(email).toLowerCase();

  if (!isValidEmail(cleanEmail)) {
    return res.status(400).json({ error: 'invalid_email', message: 'Please provide a valid email address.' });
  }

  // Lookup user
  const userResult = await query('SELECT id FROM users WHERE email = $1 AND deleted_at IS NULL', [cleanEmail]);

  // Always return 200 to prevent email enumeration attacks
  if (userResult.rowCount > 0) {
    const userId = userResult.rows[0].id;
    const token = generateSecureToken();
    const expiresAt = new Date(Date.now() + 1 * 60 * 60 * 1000); // 1 hour

    await query(
      `INSERT INTO password_resets (user_id, token, expires_at) VALUES ($1, $2, $3)`,
      [userId, token, expiresAt]
    );

    await sendPasswordResetEmail(cleanEmail, token);

    await query(
      `INSERT INTO audit_logs (user_id, action, ip_address, user_agent) VALUES ($1, 'password_reset_request', $2, $3)`,
      [userId, clientIp, req.headers['user-agent']]
    );
  }

  return res.status(200).json({
    message: 'If an account exists with that email address, a password reset link has been sent.',
  });
}

export default withErrorHandler(handler);
