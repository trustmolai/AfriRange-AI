import type { NextApiResponse } from 'next';
import { query } from '../../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../../lib/middleware';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['PUT'])) return;

  const { id } = req.query;

  const result = await query(
    `UPDATE plant_observations_ai 
     SET user_confirmed = TRUE, user_correction = NULL 
     WHERE id = $1 AND user_id = $2
     RETURNING id, user_confirmed`,
    [id, req.user.userId]
  );

  if (result.rowCount === 0) {
    return res.status(404).json({ error: 'observation_not_found', message: 'Observation not found or access denied.' });
  }

  return res.status(200).json({
    message: 'AI identification successfully confirmed by user.',
    observationId: id,
    confirmed: true,
  });
}

export default withErrorHandler(withAuth(handler));
