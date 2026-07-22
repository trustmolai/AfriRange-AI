import type { NextApiResponse } from 'next';
import { query } from '../../lib/db';
import { withAuth, withErrorHandler, allowMethods, getClientIp, AuthenticatedRequest } from '../../lib/middleware';
import { sendAccountDeletionEmail } from '../../lib/email';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['DELETE'])) return;

  const userId = req.user.userId;
  const clientIp = getClientIp(req);

  // Soft delete user record & mark deletion requested timestamp
  const userResult = await query(
    `UPDATE users 
     SET deleted_at = CURRENT_TIMESTAMP, deletion_requested_at = CURRENT_TIMESTAMP 
     WHERE id = $1 AND deleted_at IS NULL
     RETURNING email`,
    [userId]
  );

  if (userResult.rowCount === 0) {
    return res.status(404).json({ error: 'user_not_found', message: 'User account not found or already deleted.' });
  }

  const userEmail = userResult.rows[0].email;

  // Revoke all active refresh tokens immediately
  await query('UPDATE refresh_tokens SET revoked_at = CURRENT_TIMESTAMP WHERE user_id = $1', [userId]);

  // Audit log
  await query(
    `INSERT INTO audit_logs (user_id, action, ip_address, user_agent, metadata)
     VALUES ($1, 'account_delete_requested', $2, $3, $4)`,
    [userId, clientIp, req.headers['user-agent'], JSON.stringify({ email: userEmail })]
  );

  // Send confirmation email
  await sendAccountDeletionEmail(userEmail);

  return res.status(200).json({
    message: 'Account deletion request received. Pursuant to Google Play Policy, your data will be permanently purged within 7 days.',
  });
}

export default withErrorHandler(withAuth(handler));
