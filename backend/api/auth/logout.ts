import type { NextApiResponse } from 'next';
import { query } from '../../lib/db';
import { hashToken } from '../../lib/auth';
import { withAuth, withErrorHandler, allowMethods, getClientIp, AuthenticatedRequest } from '../../lib/middleware';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['POST'])) return;

  const { refreshToken } = req.body || {};
  const clientIp = getClientIp(req);

  if (refreshToken) {
    const tokenHash = hashToken(refreshToken);
    await query(
      `UPDATE refresh_tokens SET revoked_at = CURRENT_TIMESTAMP WHERE token_hash = $1 AND user_id = $2`,
      [tokenHash, req.user.userId]
    );
  }

  // Audit log
  await query(
    `INSERT INTO audit_logs (user_id, action, ip_address, user_agent)
     VALUES ($1, 'logout', $2, $3)`,
    [req.user.userId, clientIp, req.headers['user-agent']]
  );

  return res.status(200).json({ message: 'Successfully logged out.' });
}

export default withErrorHandler(withAuth(handler));
