-- ===================================================================
-- AfriRange AI — Migration 005: Plant species catalog & observations
-- ===================================================================

-- 1. PLANT SPECIES CATALOG TABLE (detailed attributes)
CREATE TABLE IF NOT EXISTS plant_species_catalog (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scientific_name VARCHAR(255) UNIQUE NOT NULL,
    common_name VARCHAR(255) NOT NULL,
    local_names JSONB DEFAULT '{}'::jsonb, -- {"af": "Gifblaar", "zu": "insinde"}
    family VARCHAR(100),
    plant_type VARCHAR(50) DEFAULT 'grass', -- 'grass', 'shrub', 'tree', 'forb', 'sedge', 'weed'
    palatability_rating VARCHAR(50) DEFAULT 'medium', -- 'high', 'medium', 'low', 'unpalatable'
    grazing_value VARCHAR(50) DEFAULT 'medium', -- 'high', 'medium', 'low', 'none'
    nutritional_value JSONB DEFAULT '{}'::jsonb, -- {"protein": "12%", "fiber": "28%"}
    
    -- Safety & Invasive Profile
    toxicity_level VARCHAR(50) DEFAULT 'safe', -- 'safe', 'caution', 'poisonous', 'highly_poisonous'
    toxicity_description TEXT,
    veld_indicator_value INT DEFAULT 5, -- 0 to 10 ecological health weight
    invasive_status BOOLEAN DEFAULT FALSE,
    bush_encroachment_status BOOLEAN DEFAULT FALSE,
    management_recommendation TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_species_toxicity ON plant_species_catalog(toxicity_level);

-- Seed top target species (e.g. Gifblaarcardiotoxic, Insindegrass)
INSERT INTO plant_species_catalog (scientific_name, common_name, local_names, family, plant_type, palatability_rating, grazing_value, toxicity_level, toxicity_description, veld_indicator_value, management_recommendation) VALUES
('Dichapetalum cymosum', 'Gifblaar', '{"af": "Gifblaar", "ts": "Tshiluvhari"}'::jsonb, 'Dichapetalaceae', 'shrub', 'unpalatable', 'none', 'highly_poisonous', 'Contains monofluoroacetate. Causes sudden cardiac arrest in livestock. Leaves are extremely lethal even in small quantities.', 1, 'Fence off infested areas. Avoid grazing in early spring when plant is green but grass is dry. Apply selective herbicide if necessary.'),
('Lantana camara', 'Lantana', '{"af": "Lantana", "zu": "Umuziwama"}'::jsonb, 'Verbenaceae', 'shrub', 'unpalatable', 'none', 'poisonous', 'Causes hepatogenous photosensitisation and liver damage in cattle and sheep.', 2, 'Uproot mechanically or apply chemical foliar sprays to prevent encroachment.'),
('Themeda triandra', 'Red Grass', '{"af": "Rooigras", "zu": "Insinde"}'::jsonb, 'Poaceae', 'grass', 'high', 'high', 'safe', NULL, 10, 'Excellent forage grass. Managed via rotational grazing to ensure seed production and root rest.')
ON CONFLICT (scientific_name) DO NOTHING;

-- 2. PLANT OBSERVATIONS TABLE
CREATE TABLE IF NOT EXISTS plant_observations_ai (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    farm_id UUID REFERENCES farms(id) ON DELETE CASCADE,
    grazing_zone_id UUID REFERENCES paddocks(id) ON DELETE SET NULL,
    photo_url TEXT,
    ai_identification JSONB NOT NULL, -- Full model output schema
    confidence_score NUMERIC(5, 2) NOT NULL, -- 0.00 to 100.00
    user_confirmed BOOLEAN DEFAULT FALSE,
    user_correction VARCHAR(255),
    location GEOMETRY(Point, 4326),
    observation_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_plant_observations_farm ON plant_observations_ai(farm_id);
CREATE INDEX IF NOT EXISTS idx_plant_observations_zone ON plant_observations_ai(grazing_zone_id);

-- 3. PLANT IDENTIFICATION LOGS (Audit & Token tracking)
CREATE TABLE IF NOT EXISTS plant_identification_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    observation_id UUID NOT NULL REFERENCES plant_observations_ai(id) ON DELETE CASCADE,
    ai_model_used VARCHAR(100) NOT NULL,
    prompt_version VARCHAR(20) DEFAULT 'v1',
    response_time_ms INT,
    token_usage INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
