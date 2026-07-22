import type { NextApiRequest, NextApiResponse } from 'next';
import { query } from '../../lib/db';
import { withErrorHandler, allowMethods, getClientIp } from '../../lib/middleware';

async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['GET', 'POST'])) return;

  const token = (req.method === 'GET' ? req.query.token : req.body.token) as string;

  if (!token) {
    return res.status(400).json({ error: 'missing_token', message: 'Verification token is required.' });
  }

  const verifyResult = await query(
    `SELECT id, user_id FROM email_verifications 
     WHERE token = $1 AND used_at IS NULL AND expires_at > CURRENT_TIMESTAMP`,
    [token]
  );

  if (verifyResult.rowCount === 0) {
    return res.status(400).json({ error: 'invalid_token', message: 'Verification token is invalid or has expired.' });
  }

  const record = verifyResult.rows[0];

  // Mark user email verified
  await query(
    `UPDATE users SET email_verified = TRUE, email_verified_at = CURRENT_TIMESTAMP WHERE id = $1`,
    [record.user_id]
  );

  // Mark token used
  await query('UPDATE email_verifications SET used_at = CURRENT_TIMESTAMP WHERE id = $1', [record.id]);

  const clientIp = getClientIp(req);
  await query(
    `INSERT INTO audit_logs (user_id, action, ip_address, user_agent) VALUES ($1, 'email_verify_success', $2, $3)`,
    [record.user_id, clientIp, req.headers['user-agent']]
  );

  return res.status(200).json({ message: 'Email successfully verified.' });
}

export default withErrorHandler(handler);
