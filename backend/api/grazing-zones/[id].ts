import type { NextApiResponse } from 'next';
import { query } from '../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../lib/middleware';
import { isValidGeoJSONPolygon, geoJsonToPostGISParam } from '../../../lib/geojson';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['GET', 'PUT', 'DELETE'])) return;

  const paddockId = req.query.id as string;

  // Ownership verification via farm relationship
  const ownershipCheck = await query(
    `SELECT p.id, p.farm_id FROM paddocks p 
     JOIN farms f ON p.farm_id = f.id 
     WHERE p.id = $1 AND f.user_id = $2`,
    [paddockId, req.user.userId]
  );

  if (ownershipCheck.rowCount === 0) {
    return res.status(404).json({ error: 'zone_not_found', message: 'Grazing zone not found or access denied.' });
  }

  // GET /api/grazing-zones/{id}
  if (req.method === 'GET') {
    const result = await query(
      `SELECT id, farm_id, name, area_ha, target_rest_days, baseline_lsu_per_ha,
              water_point_available, fence_condition, current_status,
              ST_AsGeoJSON(boundary)::json AS boundary_geojson,
              created_at, updated_at
       FROM paddocks WHERE id = $1`,
      [paddockId]
    );

    const p = result.rows[0];
    return res.status(200).json({
      grazingZone: {
        id: p.id,
        farmId: p.farm_id,
        name: p.name,
        areaHa: parseFloat(p.area_ha),
        targetRestDays: p.target_rest_days,
        baselineLsuPerHa: parseFloat(p.baseline_lsu_per_ha),
        waterPointAvailable: p.water_point_available,
        fenceCondition: p.fence_condition,
        currentStatus: p.current_status,
        boundary: p.boundary_geojson,
        createdAt: p.created_at,
        updatedAt: p.updated_at,
      },
    });
  }

  // PUT /api/grazing-zones/{id}
  if (req.method === 'PUT') {
    const { name, boundary, targetRestDays, baselineLsuPerHa, currentStatus, fenceCondition } = req.body || {};

    let boundarySql = '';
    const params: any[] = [name, targetRestDays, baselineLsuPerHa, currentStatus, fenceCondition, paddockId];

    if (boundary) {
      if (!isValidGeoJSONPolygon(boundary)) {
        return res.status(400).json({ error: 'invalid_geojson', message: 'Boundary must be a valid GeoJSON Polygon.' });
      }
      params.push(geoJsonToPostGISParam(boundary));
      boundarySql = `, boundary = ST_SetSRID(ST_GeomFromGeoJSON($7), 4326), area_ha = calculate_ha_area(ST_SetSRID(ST_GeomFromGeoJSON($7), 4326))`;
    }

    const updateResult = await query(
      `UPDATE paddocks 
       SET name = COALESCE($1, name),
           target_rest_days = COALESCE($2, target_rest_days),
           baseline_lsu_per_ha = COALESCE($3, baseline_lsu_per_ha),
           current_status = COALESCE($4, current_status),
           fence_condition = COALESCE($5, fence_condition)
           ${boundarySql}
       WHERE id = $6
       RETURNING id, farm_id, name, area_ha, target_rest_days, baseline_lsu_per_ha, current_status, fence_condition, ST_AsGeoJSON(boundary)::json AS boundary_geojson`,
      params
    );

    const updated = updateResult.rows[0];
    return res.status(200).json({
      message: 'Grazing zone updated successfully.',
      grazingZone: {
        id: updated.id,
        farmId: updated.farm_id,
        name: updated.name,
        areaHa: parseFloat(updated.area_ha),
        targetRestDays: updated.target_rest_days,
        baselineLsuPerHa: parseFloat(updated.baseline_lsu_per_ha),
        currentStatus: updated.current_status,
        fenceCondition: updated.fence_condition,
        boundary: updated.boundary_geojson,
      },
    });
  }

  // DELETE /api/grazing-zones/{id}
  if (req.method === 'DELETE') {
    await query('DELETE FROM paddocks WHERE id = $1', [paddockId]);
    return res.status(200).json({ message: 'Grazing zone deleted successfully.' });
  }
}

export default withErrorHandler(withAuth(handler));
