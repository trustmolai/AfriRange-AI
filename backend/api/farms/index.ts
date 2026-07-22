import type { NextApiResponse } from 'next';
import { query } from '../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../lib/middleware';
import { isValidGeoJSONPolygon, geoJsonToPostGISParam } from '../../lib/geojson';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['GET', 'POST'])) return;

  // -----------------------------------------------------------------
  // GET /api/farms — List User's Farms with GeoJSON Boundaries
  // -----------------------------------------------------------------
  if (req.method === 'GET') {
    const result = await query(
      `SELECT id, name, description, country, region, district, biome, total_area_ha,
              ST_AsGeoJSON(boundary)::json AS boundary_geojson,
              created_at, updated_at
       FROM farms
       WHERE user_id = $1
       ORDER BY created_at DESC`,
      [req.user.userId]
    );

    return res.status(200).json({
      farms: result.rows.map(f => ({
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
      })),
    });
  }

  // -----------------------------------------------------------------
  // POST /api/farms — Create Farm with Polygon & PostGIS Area
  // -----------------------------------------------------------------
  if (req.method === 'POST') {
    const { name, description, boundary, country, region, district, biome } = req.body || {};

    if (!name || !boundary) {
      return res.status(400).json({ error: 'missing_fields', message: 'Farm name and boundary polygon are required.' });
    }

    if (!isValidGeoJSONPolygon(boundary)) {
      return res.status(400).json({ error: 'invalid_geojson', message: 'Boundary must be a valid GeoJSON Polygon with a closed ring.' });
    }

    const geoJsonStr = geoJsonToPostGISParam(boundary);

    // Insert with PostGIS ST_GeomFromGeoJSON & calculate_ha_area
    const insertResult = await query(
      `INSERT INTO farms (user_id, name, description, boundary, total_area_ha, country, region, district, biome)
       VALUES ($1, $2, $3, ST_SetSRID(ST_GeomFromGeoJSON($4), 4326), calculate_ha_area(ST_SetSRID(ST_GeomFromGeoJSON($4), 4326)), $5, $6, $7, $8)
       RETURNING id, name, description, country, region, district, biome, total_area_ha, ST_AsGeoJSON(boundary)::json AS boundary_geojson, created_at`,
      [req.user.userId, name, description || null, geoJsonStr, country || 'South Africa', region || null, district || null, biome || 'Savanna']
    );

    const newFarm = insertResult.rows[0];

    // Audit log
    await query(
      `INSERT INTO geospatial_audit_logs (user_id, entity_type, entity_id, action, geometry_after)
       VALUES ($1, 'farm', $2, 'create', ST_SetSRID(ST_GeomFromGeoJSON($3), 4326))`,
      [req.user.userId, newFarm.id, geoJsonStr]
    );

    return res.status(201).json({
      message: 'Farm created successfully.',
      farm: {
        id: newFarm.id,
        name: newFarm.name,
        description: newFarm.description,
        country: newFarm.country,
        region: newFarm.region,
        district: newFarm.district,
        biome: newFarm.biome,
        totalAreaHa: parseFloat(newFarm.total_area_ha),
        boundary: newFarm.boundary_geojson,
        createdAt: newFarm.created_at,
      },
    });
  }
}

export default withErrorHandler(withAuth(handler));
