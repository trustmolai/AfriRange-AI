import type { NextApiResponse } from 'next';
import { query } from '../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../lib/middleware';
import { getPaddockSatelliteData } from '../../../lib/satellite-service';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['GET'])) return;

  const paddockId = req.query.id as string;

  // Ownership verification via paddock->farm->user relationship
  const ownershipCheck = await query(
    `SELECT p.id FROM paddocks p 
     JOIN farms f ON p.farm_id = f.id 
     WHERE p.id = $1 AND f.user_id = $2`,
    [paddockId, req.user.userId]
  );

  if (ownershipCheck.rowCount === 0) {
    return res.status(404).json({ error: 'zone_not_found', message: 'Grazing zone not found or access denied.' });
  }

  // Check if DB already has records
  let obsResult = await query(
    `SELECT id, observation_date, ndvi_value, evi_value, biomass_kg_per_ha, data_source
     FROM satellite_observations
     WHERE grazing_zone_id = $1
     ORDER BY observation_date DESC LIMIT 6`,
    [paddockId]
  );

  // Seed simulated data if empty
  if (obsResult.rowCount === 0) {
    const seedRecords = await getPaddockSatelliteData(paddockId);
    
    for (const rec of seedRecords) {
      await query(
        `INSERT INTO satellite_observations (grazing_zone_id, observation_date, ndvi_value, evi_value, biomass_kg_per_ha, data_source)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT (grazing_zone_id, observation_date) DO NOTHING`,
        [paddockId, rec.observationDate, rec.ndviValue, rec.eviValue, rec.biomassKgPerHa, rec.dataSource]
      );
    }

    obsResult = await query(
      `SELECT id, observation_date, ndvi_value, evi_value, biomass_kg_per_ha, data_source
       FROM satellite_observations
       WHERE grazing_zone_id = $1
       ORDER BY observation_date DESC LIMIT 6`,
      [paddockId]
    );
  }

  return res.status(200).json({
    satelliteObservations: obsResult.rows.map(o => ({
      id: o.id,
      observationDate: o.observation_date,
      ndviValue: parseFloat(o.ndvi_value),
      eviValue: o.evi_value ? parseFloat(o.evi_value) : null,
      biomassKgPerHa: parseFloat(o.biomass_kg_per_ha),
      dataSource: o.data_source,
    })),
  });
}

export default withErrorHandler(withAuth(handler));
