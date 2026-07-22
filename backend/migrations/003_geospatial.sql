-- ===================================================================
-- AfriRange AI — Migration 003: Geospatial Tables & PostGIS Functions
-- ===================================================================

-- 1. Extend FARMS table with location metadata
ALTER TABLE farms ADD COLUMN IF NOT EXISTS country VARCHAR(100) DEFAULT 'South Africa';
ALTER TABLE farms ADD COLUMN IF NOT EXISTS region VARCHAR(100);
ALTER TABLE farms ADD COLUMN IF NOT EXISTS district VARCHAR(100);

-- 2. WATER POINTS TABLE
CREATE TABLE IF NOT EXISTS water_points (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    location GEOMETRY(Point, 4326) NOT NULL,
    water_type VARCHAR(50) DEFAULT 'borehole', -- 'borehole', 'dam', 'trough', 'river', 'spring'
    status VARCHAR(50) DEFAULT 'functional', -- 'functional', 'maintenance_needed', 'dry'
    flow_rate_lph NUMERIC(10, 2), -- Liters per hour flow rate
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_water_points_location ON water_points USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_water_points_farm ON water_points(farm_id);

-- 3. GEOSPATIAL AUDIT LOGS TABLE
CREATE TABLE IF NOT EXISTS geospatial_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    entity_type VARCHAR(50) NOT NULL, -- 'farm', 'paddock', 'water_point'
    entity_id UUID NOT NULL,
    action VARCHAR(50) NOT NULL, -- 'create', 'update_boundary', 'delete'
    geometry_before GEOMETRY,
    geometry_after GEOMETRY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_geo_audit_entity ON geospatial_audit_logs(entity_type, entity_id);

-- 4. POSTGIS HELPER FUNCTION: Calculate True Geodesic Hectare Area
CREATE OR REPLACE FUNCTION calculate_ha_area(geom GEOMETRY)
RETURNS NUMERIC AS $$
BEGIN
    RETURN ROUND((ST_Area(geom::geography) / 10000.0)::numeric, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 5. POSTGIS HELPER FUNCTION: Check Polygon Overlap (>5% threshold)
CREATE OR REPLACE FUNCTION check_paddock_overlap(new_geom GEOMETRY, p_farm_id UUID, exclude_paddock_id UUID DEFAULT NULL)
RETURNS TABLE (overlapping_paddock_id UUID, overlapping_name VARCHAR, overlap_pct NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id AS overlapping_paddock_id,
        p.name AS overlapping_name,
        ROUND(((ST_Area(ST_Intersection(p.boundary, new_geom)::geography) / ST_Area(new_geom::geography)) * 100.0)::numeric, 2) AS overlap_pct
    FROM paddocks p
    WHERE p.farm_id = p_farm_id
      AND (exclude_paddock_id IS NULL OR p.id != exclude_paddock_id)
      AND ST_Intersects(p.boundary, new_geom)
      AND (ST_Area(ST_Intersection(p.boundary, new_geom)::geography) / ST_Area(new_geom::geography)) > 0.05;
END;
$$ LANGUAGE plpgsql STABLE;
