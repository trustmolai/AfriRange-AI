-- ===================================================================
-- AfriRange AI — Migration 002.5: Farms & Paddocks Base Tables
-- ===================================================================

CREATE TABLE IF NOT EXISTS farms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    boundary GEOMETRY(Polygon, 4326) NOT NULL,
    total_area_ha NUMERIC(10, 2) NOT NULL,
    biome VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_farms_boundary ON farms USING GIST(boundary);

CREATE TABLE IF NOT EXISTS paddocks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    boundary GEOMETRY(Polygon, 4326) NOT NULL,
    area_ha NUMERIC(10, 2) NOT NULL,
    target_rest_days INT DEFAULT 45,
    baseline_lsu_per_ha NUMERIC(6, 3) DEFAULT 0.200,
    water_point_available BOOLEAN DEFAULT TRUE,
    fence_condition VARCHAR(50) DEFAULT 'good',
    current_status VARCHAR(50) DEFAULT 'rested',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_paddocks_boundary ON paddocks USING GIST(boundary);
CREATE INDEX IF NOT EXISTS idx_paddocks_farm_id ON paddocks(farm_id);
