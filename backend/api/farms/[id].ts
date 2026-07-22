import type { NextApiResponse } from 'next';
import { query } from '../../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../../lib/middleware';
import { isValidGeoJSONPolygon, geoJsonToPostGISParam } from '../../../lib/geojson';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['GET', 'PUT', 'DELETE'])) return;

  const { id } = req.query;

  // Ownership verification helper
  const checkOwnership = async () => {
    const check = await query('SELECT id FROM farms WHERE id = $1 AND user_id = $2', [id, req.user.userId]);
    return check.rowCount > 0;
  };

  if (!(await checkOwnership())) {
    return res.status(404).json({ error: 'farm_not_found', message: 'Farm not found or access denied.' });
  }

  // GET /api/farms/{id}
  if (req.method === 'GET') {
    const result = await query(
      `SELECT id, name, description, country, region, district, biome, total_area_ha,
              ST_AsGeoJSON(boundary)::json AS boundary_geojson,
              created_at, updated_at
       FROM farms WHERE id = $1`,
      [id]
    );

    const f = result.rows[0];
    return res.status(200).json({
      farm: {
        id: f.id,
        name: f.name,
        description: f.description,
        country: f.country,
        region: f.region,
        district: f.district,
        biome: f.biome,
        totalAreaHa: parseFloat(f.total_area_ha),
        boundary: f.boundary_geojson,
        createdAt: f.created_at,
        updatedAt: f.updated_at,
      },
    });
  }

  // PUT /api/farms/{id}
  if (req.method === 'PUT') {
    const { name, description, boundary, country, region, district, biome } = req.body || {};

    let boundarySql = '';
    const params: any[] = [name, description, country, region, district, biome, id];

    if (boundary) {
      if (!isValidGeoJSONPolygon(boundary)) {
        return res.status(400).json({ error: 'invalid_geojson', message: 'Boundary must be a valid GeoJSON Polygon.' });
      }
      params.push(geoJsonToPostGISParam(boundary));
      boundarySql = `, boundary = ST_SetSRID(ST_GeomFromGeoJSON($8), 4326), total_area_ha = calculate_ha_area(ST_SetSRID(ST_GeomFromGeoJSON($8), 4326))`;
    }

    const updateResult = await query(
      `UPDATE farms 
       SET name = COALESCE($1, name),
           description = COALESCE($2, description),
           country = COALESCE($3, country),
           region = COALESCE($4, region),
           district = COALESCE($5, district),
           biome = COALESCE($6, biome)
           ${boundarySql}
       WHERE id = $7
       RETURNING id, name, description, country, region, district, biome, total_area_ha, ST_AsGeoJSON(boundary)::json AS boundary_geojson`,
      params
    );

    const updated = updateResult.rows[0];
    return res.status(200).json({
      message: 'Farm updated successfully.',
      farm: {
        id: updated.id,
        name: updated.name,
        description: updated.description,
        country: updated.country,
        region: updated.region,
        district: updated.district,
        biome: updated.biome,
        totalAreaHa: parseFloat(updated.total_area_ha),
        boundary: updated.boundary_geojson,
      },
    });
  }

  // DELETE /api/farms/{id}
  if (req.method === 'DELETE') {
    await query('DELETE FROM farms WHERE id = $1', [id]);
    return res.status(200).json({ message: 'Farm deleted successfully.' });
  }
}

export default withErrorHandler(withAuth(handler));
