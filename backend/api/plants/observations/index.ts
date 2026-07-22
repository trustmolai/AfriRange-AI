import type { NextApiResponse } from 'next';
import { query } from '../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../lib/middleware';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['GET', 'POST'])) return;

  // GET /api/plants/observations — Fetch list of user plant observation history
  if (req.method === 'GET') {
    const result = await query(
      `SELECT id, farm_id, grazing_zone_id, ai_identification, confidence_score,
              user_confirmed, user_correction, ST_AsGeoJSON(location)::json AS location_geojson,
              observation_date, created_at
       FROM plant_observations_ai
       WHERE user_id = $1
       ORDER BY created_at DESC`,
      [req.user.userId]
    );

    return res.status(200).json({
      observations: result.rows.map(o => ({
        id: o.id,
        farmId: o.farm_id,
        grazingZoneId: o.grazing_zone_id,
        aiIdentification: o.ai_identification,
        confidenceScore: parseFloat(o.confidence_score),
        userConfirmed: o.user_confirmed,
        userCorrection: o.user_correction,
        location: o.location_geojson,
        observationDate: o.observation_date,
        createdAt: o.created_at,
      })),
    });
  }

  // POST /api/plants/observations — Offline batch sync observation creator
  if (req.method === 'POST') {
    const { farmId, grazingZoneId, aiIdentification, confidenceScore, location, userConfirmed, userCorrection } = req.body || {};

    if (!aiIdentification || !confidenceScore) {
      return res.status(400).json({ error: 'missing_fields', message: 'AI identification payload and confidence score are required.' });
    }

    const insertResult = await query(
      `INSERT INTO plant_observations_ai (user_id, farm_id, grazing_zone_id, ai_identification, confidence_score, user_confirmed, user_correction, location)
       VALUES ($1, $2, $3, $4, $5, $6, $7, ST_SetSRID(ST_Point($8, $9), 4326))
       RETURNING id, created_at`,
      [
        req.user.userId,
        farmId || null,
        grazingZoneId || null,
        JSON.stringify(aiIdentification),
        confidenceScore,
        userConfirmed || false,
        userCorrection || null,
        location?.longitude || 0.0,
        location?.latitude || 0.0,
      ]
    );

    return res.status(201).json({
      message: 'Plant observation logged successfully.',
      observationId: insertResult.rows[0].id,
    });
  }
}

export default withErrorHandler(withAuth(handler));
