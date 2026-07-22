import type { NextApiResponse } from 'next';
import { query } from '../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../lib/middleware';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['GET'])) return;

  const paddockId = req.query.id as string;

  // Ownership check
  const ownershipCheck = await query(
    `SELECT p.id FROM paddocks p 
     JOIN farms f ON p.farm_id = f.id 
     WHERE p.id = $1 AND f.user_id = $2`,
    [paddockId, req.user.userId]
  );

  if (ownershipCheck.rowCount === 0) {
    return res.status(404).json({ error: 'zone_not_found', message: 'Grazing zone not found or access denied.' });
  }

  // Fetch comparative vegetation trend index (NDVI & EVI)
  const result = await query(
    `SELECT observation_date, ndvi_value, evi_value 
     FROM satellite_observations 
     WHERE grazing_zone_id = $1 
     ORDER BY observation_date ASC`,
    [paddockId]
  );

  return res.status(200).json({
    trends: result.rows.map(t => ({
      date: t.observation_date,
      ndvi: parseFloat(t.ndvi_value),
      evi: t.evi_value ? parseFloat(t.evi_value) : null,
    })),
  });
}

export default withErrorHandler(withAuth(handler));
