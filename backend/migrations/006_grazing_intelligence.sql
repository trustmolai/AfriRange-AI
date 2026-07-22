-- ===================================================================
-- AfriRange AI — Migration 006: Satellite Biomass & Grazing Intelligence
-- ===================================================================

-- 1. SATELLITE OBSERVATIONS TABLE
CREATE TABLE IF NOT EXISTS satellite_observations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    grazing_zone_id UUID NOT NULL REFERENCES paddocks(id) ON DELETE CASCADE,
    observation_date DATE NOT NULL,
    ndvi_value NUMERIC(5, 4) NOT NULL, -- -1.0 to 1.0
    evi_value NUMERIC(5, 4), -- Enhanced Vegetation Index
    biomass_kg_per_ha NUMERIC(10, 2) NOT NULL, -- Estimated Dry Matter forage yield
    data_source VARCHAR(100) DEFAULT 'Sentinel-2',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_zone_obs_date UNIQUE (grazing_zone_id, observation_date)
);

CREATE INDEX IF NOT EXISTS idx_sat_obs_zone ON satellite_observations(grazing_zone_id, observation_date DESC);

-- 2. BIOMASS ESTIMATES AUDIT TABLE
CREATE TABLE IF NOT EXISTS biomass_estimates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    grazing_zone_id UUID NOT NULL REFERENCES paddocks(id) ON DELETE CASCADE,
    estimate_date DATE NOT NULL,
    biomass_kg_per_ha NUMERIC(10, 2) NOT NULL,
    total_available_forage_kg NUMERIC(12, 2) NOT NULL,
    confidence_level VARCHAR(50) DEFAULT 'high', -- 'high', 'medium', 'low'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_biomass_est_zone ON biomass_estimates(grazing_zone_id, estimate_date DESC);

-- 3. GRAZING RECOMMENDATIONS (AI Output Storage)
CREATE TABLE IF NOT EXISTS grazing_recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    grazing_zone_id UUID REFERENCES paddocks(id) ON DELETE CASCADE, -- Recommended paddock
    recommendation_date DATE DEFAULT CURRENT_DATE,
    recommended_action VARCHAR(255) NOT NULL,
    grazing_days_remaining INT DEFAULT 0,
    recommended_stocking_rate NUMERIC(6, 2), -- LSU/ha target
    rest_period_days INT DEFAULT 45,
    risk_level VARCHAR(50) DEFAULT 'low',
    ai_explanation TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_grazing_rec_farm ON grazing_recommendations(farm_id, recommendation_date DESC);

-- 4. ROTATIONAL GRAZING PLANS
CREATE TABLE IF NOT EXISTS rotational_grazing_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    plan_name VARCHAR(255) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. ROTATIONAL PLAN PADDOCKS (Junction table with sequence)
CREATE TABLE IF NOT EXISTS rotational_plan_paddocks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_id UUID NOT NULL REFERENCES rotational_grazing_plans(id) ON DELETE CASCADE,
    paddock_id UUID NOT NULL REFERENCES paddocks(id) ON DELETE CASCADE,
    grazing_start_date DATE NOT NULL,
    grazing_end_date DATE,
    rest_days INT DEFAULT 45,
    sequence_order INT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_rot_plan_paddocks_plan ON rotational_plan_paddocks(plan_id, sequence_order);
CREATE UNIQUE INDEX IF NOT EXISTS uq_rot_plan_sequence ON rotational_plan_paddocks(plan_id, sequence_order);

-- 6. WATER POINTS FOR GRAZING PLANNING
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

-- Update triggers for updated_at columns
DROP TRIGGER IF EXISTS update_farms_updatedat ON farms;
CREATE TRIGGER update_farms_updatedat
    BEFORE UPDATE ON farms
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_paddocks_updatedat ON paddocks;
CREATE TRIGGER update_paddocks_updatedat
    BEFORE UPDATE ON paddocks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_rotational_grazing_plans_updatedat ON rotational_grazing_plans;
CREATE TRIGGER update_rotational_grazing_plans_updatedat
    BEFORE UPDATE ON rotational_grazing_plans
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_water_points_updatedat ON water_points;
CREATE TRIGGER update_water_points_updatedat
    BEFORE UPDATE ON water_points
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();