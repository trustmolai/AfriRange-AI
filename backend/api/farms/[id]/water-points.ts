import type { NextApiResponse } from 'next';
import { query } from '../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../lib/middleware';
import { isValidGeoJSONPoint, geoJsonToPostGISParam } from '../../../lib/geojson';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['GET', 'POST'])) return;

  const farmId = req.query.id as string;

  // Ownership check
  const farmCheck = await query('SELECT id FROM farms WHERE id = $1 AND user_id = $2', [farmId, req.user.userId]);
  if (farmCheck.rowCount === 0) {
    return res.status(404).json({ error: 'farm_not_found', message: 'Farm not found or access denied.' });
  }

  // GET /api/farms/{id}/water-points
  if (req.method === 'GET') {
    const result = await query(
      `SELECT id, farm_id, name, water_type, status, flow_rate_lph,
              ST_AsGeoJSON(location)::json AS location_geojson,
              created_at, updated_at
       FROM water_points
       WHERE farm_id = $1
       ORDER BY name ASC`,
      [farmId]
    );

    return res.status(200).json({
      waterPoints: result.rows.map(w => ({
        id: w.id,
        farmId: w.farm_id,
        name: w.name,
        waterType: w.water_type,
        status: w.status,
        flowRateLph: w.flow_rate_lph ? parseFloat(w.flow_rate_lph) : null,
        location: w.location_geojson,
        createdAt: w.created_at,
        updatedAt: w.updated_at,
      })),
    });
  }

  // POST /api/farms/{id}/water-points
  if (req.method === 'POST') {
    const { name, location, waterType, status, flowRateLph } = req.body || {};

    if (!name || !location) {
      return res.status(400).json({ error: 'missing_fields', message: 'Water point name and location point are required.' });
    }

    if (!isValidGeoJSONPoint(location)) {
      return res.status(400).json({ error: 'invalid_geojson', message: 'Location must be a valid GeoJSON Point [lng, lat].' });
    }

    const geoJsonStr = geoJsonToPostGISParam(location);

    const insertResult = await query(
      `INSERT INTO water_points (farm_id, name, location, water_type, status, flow_rate_lph)
       VALUES ($1, $2, ST_SetSRID(ST_GeomFromGeoJSON($3), 4326), $4, $5, $6)
       RETURNING id, farm_id, name, water_type, status, flow_rate_lph, ST_AsGeoJSON(location)::json AS location_geojson, created_at`,
      [farmId, name, geoJsonStr, waterType || 'borehole', status || 'functional', flowRateLph || null]
    );

    const newPoint = insertResult.rows[0];

    return res.status(201).json({
      message: 'Water point created successfully.',
      waterPoint: {
        id: newPoint.id,
        farmId: newPoint.farm_id,
        name: newPoint.name,
        waterType: newPoint.water_type,
        status: newPoint.status,
        flowRateLph: newPoint.flow_rate_lph ? parseFloat(newPoint.flow_rate_lph) : null,
        location: newPoint.location_geojson,
        createdAt: newPoint.created_at,
      },
    });
  }
}

export default withErrorHandler(withAuth(handler));
