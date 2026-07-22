import type { NextApiResponse } from 'next';
import { query } from '../../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../../lib/middleware';
import { sanitizeString } from '../../../../lib/validators';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['PUT'])) return;

  const { id } = req.query;
  const { correctedName } = req.body || {};

  const cleanName = sanitizeString(correctedName);

  if (!cleanName) {
    return res.status(400).json({ error: 'missing_correction', message: 'Corrected species name is required.' });
  }

  const result = await query(
    `UPDATE plant_observations_ai 
     SET user_confirmed = FALSE, user_correction = $1 
     WHERE id = $2 AND user_id = $3
     RETURNING id, user_correction`,
    [cleanName, id, req.user.userId]
  );

  if (result.rowCount === 0) {
    return res.status(404).json({ error: 'observation_not_found', message: 'Observation not found or access denied.' });
  }

  return res.status(200).json({
    message: 'User species correction logged successfully.',
    observationId: id,
    correction: cleanName,
  });
}

export default withErrorHandler(withAuth(handler));
