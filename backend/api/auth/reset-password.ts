import type { NextApiRequest, NextApiResponse } from 'next';
import { query } from '../../lib/db';
import { hashPassword } from '../../lib/auth';
import { withErrorHandler, allowMethods, getClientIp } from '../../lib/middleware';
import { isValidPassword } from '../../lib/validators';

async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['POST'])) return;

  const { token, newPassword } = req.body || {};

  if (!token || !newPassword) {
    return res.status(400).json({ error: 'missing_fields', message: 'Token and new password are required.' });
  }

  const passwordCheck = isValidPassword(newPassword);
  if (!passwordCheck.valid) {
    return res.status(400).json({ error: 'weak_password', message: passwordCheck.message });
  }

  // Find valid token
  const resetResult = await query(
    `SELECT id, user_id FROM password_resets 
     WHERE token = $1 AND used_at IS NULL AND expires_at > CURRENT_TIMESTAMP`,
    [token]
  );

  if (resetResult.rowCount === 0) {
    return res.status(400).json({ error: 'invalid_token', message: 'Password reset token is invalid or has expired.' });
  }

  const resetRecord = resetResult.rows[0];
  const newPasswordHash = await hashPassword(newPassword);

  // Update password & mark token used
  await query('UPDATE users SET password_hash = $1 WHERE id = $2', [newPasswordHash, resetRecord.user_id]);
  await query('UPDATE password_resets SET used_at = CURRENT_TIMESTAMP WHERE id = $1', [resetRecord.id]);

  // Revoke all active refresh tokens for security
  await query('UPDATE refresh_tokens SET revoked_at = CURRENT_TIMESTAMP WHERE user_id = $1', [resetRecord.user_id]);

  const clientIp = getClientIp(req);
  await query(
    `INSERT INTO audit_logs (user_id, action, ip_address, user_agent) VALUES ($1, 'password_reset_success', $2, $3)`,
    [resetRecord.user_id, clientIp, req.headers['user-agent']]
  );

  return res.status(200).json({ message: 'Password successfully reset. Please log in with your new password.' });
}

export default withErrorHandler(handler);
