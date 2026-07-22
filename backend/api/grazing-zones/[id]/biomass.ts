import type { NextApiResponse } from 'next';
import { query } from '../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../lib/middleware';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['GET', 'POST'])) return;

  const paddockId = req.query.id as string;

  // Ownership verification
  const check = await query(
    `SELECT p.id, p.area_ha FROM paddocks p 
     JOIN farms f ON p.farm_id = f.id 
     WHERE p.id = $1 AND f.user_id = $2`,
    [paddockId, req.user.userId]
  );

  if (check.rowCount === 0) {
    return res.status(404).json({ error: 'zone_not_found', message: 'Grazing zone not found or access denied.' });
  }

  const areaHa = parseFloat(check.rows[0].area_ha);

  // GET /api/grazing-zones/{id}/biomass
  if (req.method === 'GET') {
    const result = await query(
      `SELECT id, estimate_date, biomass_kg_per_ha, total_available_forage_kg, confidence_level, created_at
       FROM biomass_estimates
       WHERE grazing_zone_id = $1
       ORDER BY estimate_date DESC LIMIT 1`,
      [paddockId]
    );

    return res.status(200).json({
      latestEstimate: result.rows[0] ? {
        id: result.rows[0].id,
        estimateDate: result.rows[0].estimate_date,
        biomassKgPerHa: parseFloat(result.rows[0].biomass_kg_per_ha),
        totalAvailableForageKg: parseFloat(result.rows[0].total_available_forage_kg),
        confidenceLevel: result.rows[0].confidence_level,
        createdAt: result.rows[0].created_at,
      } : null,
    });
  }

  // POST /api/grazing-zones/{id}/biomass (Calculate biomass from latest satellite obs)
  if (req.method === 'POST') {
    const satResult = await query(
      `SELECT biomass_kg_per_ha, observation_date FROM satellite_observations 
       WHERE grazing_zone_id = $1 
       ORDER BY observation_date DESC LIMIT 1`,
      [paddockId]
    );

    const biomassKgPerHa = satResult.rowCount > 0 
      ? parseFloat(satResult.rows[0].biomass_kg_per_ha)
      : 2200.0; // Fallback to baseline
    
    const totalAvailableForageKg = biomassKgPerHa * areaHa;

    const insertResult = await query(
      `INSERT INTO biomass_estimates (grazing_zone_id, estimate_date, biomass_kg_per_ha, total_available_forage_kg)
       VALUES ($1, CURRENT_DATE, $2, $3)
       RETURNING id, estimate_date, biomass_kg_per_ha, total_available_forage_kg, confidence_level`,
      [paddockId, biomassKgPerHa, totalAvailableForageKg]
    );

    const rec = insertResult.rows[0];

    return res.status(200).json({
      message: 'Biomass estimated successfully.',
      biomassEstimate: {
        id: rec.id,
        estimateDate: rec.estimate_date,
        biomassKgPerHa: parseFloat(rec.biomass_kg_per_ha),
        totalAvailableForageKg: parseFloat(rec.total_available_forage_kg),
        confidenceLevel: rec.confidence_level,
      },
    });
  }
}

export default withErrorHandler(withAuth(handler));
