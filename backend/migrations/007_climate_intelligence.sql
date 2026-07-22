-- ===================================================================
-- AfriRange AI — Migration 007: Climate Intelligence & Drought Alerts
-- ===================================================================

-- 1. CLIMATE OBSERVATIONS TABLE
CREATE TABLE IF NOT EXISTS climate_observations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    observation_date DATE NOT NULL,
    rainfall_mm NUMERIC(8, 2) DEFAULT 0.0,
    temperature_c NUMERIC(5, 2),
    humidity_percentage NUMERIC(5, 2),
    evapotranspiration_mm NUMERIC(8, 2),
    data_source VARCHAR(100) DEFAULT 'CHIRPS',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_farm_climate_date UNIQUE (farm_id, observation_date)
);

CREATE INDEX IF NOT EXISTS idx_climate_obs_farm ON climate_observations(farm_id, observation_date DESC);

-- 2. DROUGHT FORECASTS TABLE
CREATE TABLE IF NOT EXISTS drought_forecasts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    forecast_date DATE DEFAULT CURRENT_DATE,
    forecast_period_days INT NOT NULL, -- 30, 60, or 90
    drought_risk_level VARCHAR(50) NOT NULL, -- 'low', 'moderate', 'high', 'severe'
    drought_risk_score NUMERIC(5, 2) DEFAULT 0.0, -- 0-100 composite score
    rainfall_probability NUMERIC(5, 2), -- % chance of adequate rainfall
    forage_shortage_probability NUMERIC(5, 2), -- % chance of feed deficit
    water_stress_probability NUMERIC(5, 2), -- % chance of water scarcity
    heat_stress_probability NUMERIC(5, 2), -- % chance of THI >= 72
    forage_days_remaining INT, -- Estimated days until forage depletion
    ai_explanation TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_drought_forecast_farm ON drought_forecasts(farm_id, forecast_date DESC);

-- 3. CLIMATE ALERTS TABLE
CREATE TABLE IF NOT EXISTS climate_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    alert_type VARCHAR(100) NOT NULL, -- 'drought', 'forage_shortage', 'heat_stress', 'water_stress', 'destocking'
    risk_level VARCHAR(50) NOT NULL, -- 'low', 'moderate', 'high', 'severe'
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    recommended_action TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    acknowledged_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_climate_alerts_farm ON climate_alerts(farm_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_climate_alerts_unacked ON climate_alerts(farm_id) WHERE acknowledged_at IS NULL;
