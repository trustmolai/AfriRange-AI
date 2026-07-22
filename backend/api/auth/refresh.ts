import type { NextApiRequest, NextApiResponse } from 'next';
import { query } from '../../lib/db';
import { verifyRefreshToken, generateAccessToken, generateRefreshToken, hashToken } from '../../lib/auth';
import { withErrorHandler, allowMethods, getClientIp } from '../../lib/middleware';

async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['POST'])) return;

  const { refreshToken } = req.body || {};
  if (!refreshToken) {
    return res.status(400).json({ error: 'missing_token', message: 'Refresh token is required.' });
  }

  const payload = verifyRefreshToken(refreshToken);
  if (!payload) {
    return res.status(401).json({ error: 'invalid_token', message: 'Invalid or expired refresh token.' });
  }

  const currentTokenHash = hashToken(refreshToken);

  // Check DB for existing non-revoked token
  const tokenResult = await query(
    `SELECT id, user_id FROM refresh_tokens 
     WHERE token_hash = $1 AND revoked_at IS NULL AND expires_at > CURRENT_TIMESTAMP`,
    [currentTokenHash]
  );

  if (tokenResult.rowCount === 0) {
    return res.status(401).json({ error: 'token_revoked', message: 'Refresh token has been revoked or expired.' });
  }

  const tokenId = tokenResult.rows[0].id;
  const clientIp = getClientIp(req);

  // Revoke old refresh token (One-time use token rotation)
  await query('UPDATE refresh_tokens SET revoked_at = CURRENT_TIMESTAMP WHERE id = $1', [tokenId]);

  // Generate new pair
  const newPayload = { userId: payload.userId, email: payload.email, role: payload.role };
  const newAccessToken = generateAccessToken(newPayload);
  const newRefreshToken = generateRefreshToken(newPayload);

  // Save new refresh token
  const newHash = hashToken(newRefreshToken);
  const refreshExpiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

  await query(
    `INSERT INTO refresh_tokens (user_id, token_hash, device_info, ip_address, expires_at)
     VALUES ($1, $2, $3, $4, $5)`,
    [payload.userId, newHash, req.headers['user-agent'] || 'unknown', clientIp, refreshExpiresAt]
  );

  return res.status(200).json({
    accessToken: newAccessToken,
    refreshToken: newRefreshToken,
  });
}

export default withErrorHandler(handler);
