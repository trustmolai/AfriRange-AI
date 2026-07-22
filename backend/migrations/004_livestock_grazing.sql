-- ===================================================================
-- AfriRange AI — Migration 004: Livestock & Grazing Management
-- ===================================================================

-- 1. LSU / TLU CONVERSION FACTORS REFERENCE TABLE
CREATE TABLE IF NOT EXISTS lsu_conversion_factors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    species VARCHAR(50) UNIQUE NOT NULL, -- 'cattle_mature', 'cattle_heifer', 'sheep', 'goat', 'camel', 'donkey', 'horse'
    display_name VARCHAR(100) NOT NULL,
    lsu_factor NUMERIC(5, 3) NOT NULL, -- Relative to 450kg steer (1.000)
    tlu_factor NUMERIC(5, 3) NOT NULL, -- Relative to 250kg animal (1.000)
    average_weight_kg NUMERIC(6, 2) NOT NULL,
    daily_intake_dm_kg NUMERIC(5, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Seed Standard African Livestock Conversions
INSERT INTO lsu_conversion_factors (species, display_name, lsu_factor, tlu_factor, average_weight_kg, daily_intake_dm_kg) VALUES
('cattle_mature', 'Cattle (Mature Steer/Cow)', 1.000, 1.400, 450.00, 11.25),
('cattle_heifer', 'Cattle (Heifer/Calf)', 0.600, 0.840, 270.00, 6.75),
('sheep', 'Sheep (Mature)', 0.150, 0.210, 50.00, 1.70),
('goat', 'Goat (Mature)', 0.150, 0.210, 45.00, 1.50),
('camel', 'Camel (Mature)', 1.250, 1.750, 550.00, 13.75),
('donkey', 'Donkey', 0.500, 0.700, 200.00, 5.00),
('horse', 'Horse', 0.800, 1.120, 350.00, 8.75)
ON CONFLICT (species) DO NOTHING;

-- 2. LIVESTOCK GROUPS TABLE
CREATE TABLE IF NOT EXISTS livestock_groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    species VARCHAR(50) NOT NULL,
    animal_class VARCHAR(50) DEFAULT 'mature',
    number_of_animals INT NOT NULL DEFAULT 1,
    average_weight_kg NUMERIC(6, 2),
    lsu_value NUMERIC(8, 3) NOT NULL,
    tlu_value NUMERIC(8, 3) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_livestock_farm ON livestock_groups(farm_id);

-- 3. GRAZING RECORDS TABLE
CREATE TABLE IF NOT EXISTS grazing_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    grazing_zone_id UUID NOT NULL REFERENCES paddocks(id) ON DELETE CASCADE,
    livestock_group_id UUID NOT NULL REFERENCES livestock_groups(id) ON DELETE CASCADE,
    grazing_start_date DATE NOT NULL,
    grazing_end_date DATE,
    number_of_animals INT NOT NULL,
    lsu_grazing NUMERIC(8, 3) NOT NULL,
    grazing_days INT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_grazing_records_zone ON grazing_records(grazing_zone_id, grazing_start_date DESC);
CREATE INDEX IF NOT EXISTS idx_grazing_records_group ON grazing_records(livestock_group_id);

-- 4. CARRYING CAPACITY RECORDS TABLE
CREATE TABLE IF NOT EXISTS carrying_capacity_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    grazing_zone_id UUID REFERENCES paddocks(id) ON DELETE CASCADE,
    total_area_ha NUMERIC(10, 2) NOT NULL,
    available_forage_kg_dm NUMERIC(12, 2) NOT NULL,
    sustainable_utilization_pct NUMERIC(5, 2) DEFAULT 40.00, -- 40% default utilization factor
    carrying_capacity_lsu NUMERIC(8, 2) NOT NULL,
    carrying_capacity_tlu NUMERIC(8, 2) NOT NULL,
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_carrying_capacity_farm ON carrying_capacity_records(farm_id, calculated_at DESC);

-- 5. STOCKING RATE RECORDS TABLE
CREATE TABLE IF NOT EXISTS stocking_rate_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    actual_lsu NUMERIC(8, 2) NOT NULL,
    recommended_lsu NUMERIC(8, 2) NOT NULL,
    stocking_rate_ha_per_lsu NUMERIC(8, 2) NOT NULL,
    grazing_pressure_pct NUMERIC(6, 2) NOT NULL,
    risk_level VARCHAR(50) NOT NULL, -- 'low', 'moderate', 'high', 'severe'
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_stocking_rate_farm ON stocking_rate_records(farm_id, calculated_at DESC);

-- 6. LIVESTOCK AUDIT LOGS TABLE
CREATE TABLE IF NOT EXISTS livestock_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    action VARCHAR(100) NOT NULL, -- 'create_group', 'move_livestock', 'recalculate_stocking'
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
