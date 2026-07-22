-- ===================================================================
-- AfriRange AI - Neon PostgreSQL + PostGIS Schema
-- Target DB: Serverless PostgreSQL with PostGIS Spatial Extensions
-- ===================================================================

-- Enable PostGIS extension for spatial polygon/point geometry queries
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -------------------------------------------------------------------
-- 1. USERS & SUBSCRIPTIONS
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255),
    phone_number VARCHAR(50),
    country_code VARCHAR(10) DEFAULT 'ZA',
    
    -- Billing & Compliance
    subscription_tier VARCHAR(50) DEFAULT 'free', -- 'free', 'pro', 'enterprise'
    subscription_status VARCHAR(50) DEFAULT 'active', -- 'active', 'cancelled', 'grace_period'
    google_play_purchase_token TEXT,
    google_play_subscription_id VARCHAR(255),
    ai_credit_balance INT DEFAULT 5, -- Free tier grants 5 AI scans/month
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -------------------------------------------------------------------
-- 2. FARMS (Property Boundaries)
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS farms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    boundary GEOMETRY(Polygon, 4326) NOT NULL, -- EPSG:4326 WGS84
    total_area_ha NUMERIC(10, 2) NOT NULL,
    biome VARCHAR(100), -- e.g. 'Savanna', 'Karoo Shrubland', 'Highveld Grassland'
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for spatial bounding queries
CREATE INDEX IF NOT EXISTS idx_farms_boundary ON farms USING GIST(boundary);

-- -------------------------------------------------------------------
-- 3. PADDOCKS (Camps / Rotational Grazing Units)
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS paddocks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    boundary GEOMETRY(Polygon, 4326) NOT NULL,
    area_ha NUMERIC(10, 2) NOT NULL,
    
    -- Ecological & Grazing Parameters
    target_rest_days INT DEFAULT 45, -- Default 45-60 days rest period
    baseline_lsu_per_ha NUMERIC(6, 3) DEFAULT 0.200, -- Large Stock Units per hectare
    water_point_available BOOLEAN DEFAULT TRUE,
    fence_condition VARCHAR(50) DEFAULT 'good', -- 'good', 'needs_repair', 'none'
    
    current_status VARCHAR(50) DEFAULT 'rested', -- 'grazing', 'rested', 'overgrazed', 'recovering'
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_paddocks_boundary ON paddocks USING GIST(boundary);
CREATE INDEX IF NOT EXISTS idx_paddocks_farm_id ON paddocks(farm_id);

-- -------------------------------------------------------------------
-- 4. PLANT SPECIES CATALOG (Botanical Taxonomy & Veld Score Metrics)
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS plant_species (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scientific_name VARCHAR(255) UNIQUE NOT NULL,
    common_names JSONB NOT NULL, -- {"en": "Rooigras", "af": "Rooigras", "zu": "Insinde"}
    family VARCHAR(100),
    plant_type VARCHAR(50) NOT NULL, -- 'grass', 'shrub', 'tree', 'forb', 'sedge', 'weed'
    
    -- Veld Condition & Grazing Parameters
    ecological_status VARCHAR(50) NOT NULL, -- 'Decreaser', 'Increaser I', 'Increaser II', 'Increaser III', 'Invader'
    palatability VARCHAR(50) NOT NULL, -- 'High', 'Medium', 'Low', 'Unpalatable'
    forage_yield_value VARCHAR(50) DEFAULT 'Medium',
    
    -- Risk Profile
    is_poisonous BOOLEAN DEFAULT FALSE,
    toxicity_level VARCHAR(50) DEFAULT 'None', -- 'None', 'Mild', 'Severe', 'Lethal'
    poison_category VARCHAR(100), -- 'Cardiotoxic', 'Hepatotoxic', 'Cyanogenic'
    is_invasive BOOLEAN DEFAULT FALSE,
    
    -- Management
    management_advice TEXT,
    image_url TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_plant_species_scientific ON plant_species(scientific_name);
CREATE INDEX IF NOT EXISTS idx_plant_species_poisonous ON plant_species(is_poisonous) WHERE is_poisonous = TRUE;

-- -------------------------------------------------------------------
-- 5. FIELD PLANT OBSERVATIONS (Survey & Vision AI Logs)
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS plant_observations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    paddock_id UUID REFERENCES paddocks(id) ON DELETE SET NULL,
    plant_species_id UUID REFERENCES plant_species(id) ON DELETE SET NULL,
    
    location GEOMETRY(Point, 4326) NOT NULL,
    photo_url TEXT,
    ai_confidence_score NUMERIC(4, 3), -- e.g. 0.945
    identified_name_raw VARCHAR(255),
    
    user_notes TEXT,
    is_verified_by_user BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_plant_obs_location ON plant_observations USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_plant_obs_paddock ON plant_observations(paddock_id);

-- -------------------------------------------------------------------
-- 6. SATELLITE NDVI & CLIMATE HISTORY (Pre-Aggregated JSON Time-Series)
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS satellite_ndvi_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    paddock_id UUID NOT NULL REFERENCES paddocks(id) ON DELETE CASCADE,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    
    ndvi_mean NUMERIC(5, 4) NOT NULL, -- Normalized Difference Vegetation Index (-1 to +1)
    ndvi_min NUMERIC(5, 4),
    ndvi_max NUMERIC(5, 4),
    
    rainfall_mm NUMERIC(7, 2), -- CHIRPS monthly accumulated rainfall
    cloud_cover_pct NUMERIC(5, 2) DEFAULT 0.0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_paddock_period UNIQUE (paddock_id, period_start)
);

CREATE INDEX IF NOT EXISTS idx_satellite_history_paddock ON satellite_ndvi_history(paddock_id, period_start DESC);

-- -------------------------------------------------------------------
-- 7. GRAZING ROTATION LOGS
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS grazing_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    paddock_id UUID NOT NULL REFERENCES paddocks(id) ON DELETE CASCADE,
    herd_name VARCHAR(100) DEFAULT 'Main Herd',
    lsu_count NUMERIC(8, 2) NOT NULL, -- Total Large Stock Units currently grazing
    entry_date DATE NOT NULL,
    exit_date DATE,
    
    planned_duration_days INT NOT NULL,
    actual_duration_days INT,
    
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_grazing_logs_paddock ON grazing_logs(paddock_id, entry_date DESC);
