import type { NextApiResponse } from 'next';
import { query } from '../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../lib/middleware';
import { isValidGeoJSONPoint, geoJsonToPostGISParam } from '../../../lib/geojson';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['PUT', 'DELETE'])) return;

  const pointId = req.query.id as string;

  const ownershipCheck = await query(
    `SELECT w.id FROM water_points w 
     JOIN farms f ON w.farm_id = f.id 
     WHERE w.id = $1 AND f.user_id = $2`,
    [pointId, req.user.userId]
  );

  if (ownershipCheck.rowCount === 0) {
    return res.status(404).json({ error: 'water_point_not_found', message: 'Water point not found or access denied.' });
  }

  // PUT /api/water-points/{id}
  if (req.method === 'PUT') {
    const { name, location, waterType, status, flowRateLph } = req.body || {};

    let locationSql = '';
    const params: any[] = [name, waterType, status, flowRateLph, pointId];

    if (location) {
      if (!isValidGeoJSONPoint(location)) {
        return res.status(400).json({ error: 'invalid_geojson', message: 'Location must be a valid GeoJSON Point [lng, lat].' });
      }
      params.push(geoJsonToPostGISParam(location));
      locationSql = `, location = ST_SetSRID(ST_GeomFromGeoJSON($6), 4326)`;
    }

    const updateResult = await query(
      `UPDATE water_points 
       SET name = COALESCE($1, name),
           water_type = COALESCE($2, water_type),
           status = COALESCE($3, status),
           flow_rate_lph = COALESCE($4, flow_rate_lph)
           ${locationSql}
       WHERE id = $5
       RETURNING id, farm_id, name, water_type, status, flow_rate_lph, ST_AsGeoJSON(location)::json AS location_geojson`,
      params
    );

    const updated = updateResult.rows[0];
    return res.status(200).json({
      message: 'Water point updated successfully.',
      waterPoint: {
        id: updated.id,
        farmId: updated.farm_id,
        name: updated.name,
        waterType: updated.water_type,
        status: updated.status,
        flowRateLph: updated.flow_rate_lph ? parseFloat(updated.flow_rate_lph) : null,
        location: updated.location_geojson,
      },
    });
  }

  // DELETE /api/water-points/{id}
  if (req.method === 'DELETE') {
    await query('DELETE FROM water_points WHERE id = $1', [pointId]);
    return res.status(200).json({ message: 'Water point deleted successfully.' });
  }
}

export default withErrorHandler(withAuth(handler));
