import type { NextApiResponse } from 'next';
import { query } from '../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../lib/middleware';
import { isValidGeoJSONPolygon, geoJsonToPostGISParam } from '../../../lib/geojson';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['GET', 'POST'])) return;

  const farmId = req.query.id as string;

  // Ownership verification
  const farmCheck = await query('SELECT id FROM farms WHERE id = $1 AND user_id = $2', [farmId, req.user.userId]);
  if (farmCheck.rowCount === 0) {
    return res.status(404).json({ error: 'farm_not_found', message: 'Farm not found or access denied.' });
  }

  // GET /api/farms/{id}/grazing-zones
  if (req.method === 'GET') {
    const result = await query(
      `SELECT id, farm_id, name, area_ha, target_rest_days, baseline_lsu_per_ha,
              water_point_available, fence_condition, current_status,
              ST_AsGeoJSON(boundary)::json AS boundary_geojson,
              created_at, updated_at
       FROM paddocks
       WHERE farm_id = $1
       ORDER BY name ASC`,
      [farmId]
    );

    return res.status(200).json({
      grazingZones: result.rows.map(p => ({
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
      })),
    });
  }

  // POST /api/farms/{id}/grazing-zones
  if (req.method === 'POST') {
    const { name, boundary, targetRestDays, baselineLsuPerHa, currentStatus } = req.body || {};

    if (!name || !boundary) {
      return res.status(400).json({ error: 'missing_fields', message: 'Zone name and boundary polygon are required.' });
    }

    if (!isValidGeoJSONPolygon(boundary)) {
      return res.status(400).json({ error: 'invalid_geojson', message: 'Boundary must be a valid GeoJSON Polygon.' });
    }

    const geoJsonStr = geoJsonToPostGISParam(boundary);

    // Overlap check via PostGIS check_paddock_overlap
    const overlapResult = await query(
      `SELECT * FROM check_paddock_overlap(ST_SetSRID(ST_GeomFromGeoJSON($1), 4326), $2)`,
      [geoJsonStr, farmId]
    );

    const warnings: string[] = [];
    if (overlapResult.rowCount > 0) {
      overlapResult.rows.forEach(r => {
        warnings.push(`Overlaps with paddock "${r.overlapping_name}" by ${r.overlap_pct}%.`);
      });
    }

    // Insert paddock
    const insertResult = await query(
      `INSERT INTO paddocks (farm_id, name, boundary, area_ha, target_rest_days, baseline_lsu_per_ha, current_status)
       VALUES ($1, $2, ST_SetSRID(ST_GeomFromGeoJSON($3), 4326), calculate_ha_area(ST_SetSRID(ST_GeomFromGeoJSON($3), 4326)), $4, $5, $6)
       RETURNING id, farm_id, name, area_ha, target_rest_days, baseline_lsu_per_ha, current_status, ST_AsGeoJSON(boundary)::json AS boundary_geojson, created_at`,
      [farmId, name, geoJsonStr, targetRestDays || 45, baselineLsuPerHa || 0.200, currentStatus || 'rested']
    );

    const newZone = insertResult.rows[0];

    return res.status(201).json({
      message: 'Grazing zone created successfully.',
      warnings: warnings.length > 0 ? warnings : undefined,
      grazingZone: {
        id: newZone.id,
        farmId: newZone.farm_id,
        name: newZone.name,
        areaHa: parseFloat(newZone.area_ha),
        targetRestDays: newZone.target_rest_days,
        baselineLsuPerHa: parseFloat(newZone.baseline_lsu_per_ha),
        currentStatus: newZone.current_status,
        boundary: newZone.boundary_geojson,
        createdAt: newZone.created_at,
      },
    });
  }
}

export default withErrorHandler(withAuth(handler));
