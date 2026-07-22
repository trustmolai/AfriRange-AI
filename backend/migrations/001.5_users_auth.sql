-- ===================================================================
-- AfriRange AI — Migration 002: Users & Authentication Tables
-- ===================================================================

-- -------------------------------------------------------------------
-- 1. USERS (Extended with auth fields)
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    phone_number VARCHAR(50),
    country_code VARCHAR(10) DEFAULT 'ZA',
    preferred_language VARCHAR(10) DEFAULT 'en',
    farming_type VARCHAR(50), -- 'livestock', 'game', 'mixed', 'communal', 'extension_officer', 'ngo'

    -- Role-Based Access Control
    role VARCHAR(50) DEFAULT 'farmer', -- 'farmer', 'pastoralist', 'communal_manager', 'game_manager', 'extension_officer', 'ngo_manager', 'admin'

    -- Email Verification
    email_verified BOOLEAN DEFAULT FALSE,
    email_verified_at TIMESTAMP WITH TIME ZONE,

    -- Subscription & Billing
    subscription_tier VARCHAR(50) DEFAULT 'free', -- 'free', 'pro', 'enterprise'
    subscription_status VARCHAR(50) DEFAULT 'active', -- 'active', 'cancelled', 'grace_period', 'expired'
    google_play_purchase_token TEXT,
    google_play_subscription_id VARCHAR(255),
    ai_credit_balance INT DEFAULT 5,

    -- Soft Delete (Google Play account deletion compliance)
    deleted_at TIMESTAMP WITH TIME ZONE,
    deletion_requested_at TIMESTAMP WITH TIME ZONE,

    -- Metadata
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_deleted ON users(deleted_at) WHERE deleted_at IS NOT NULL;

-- -------------------------------------------------------------------
-- 2. EMAIL VERIFICATIONS
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS email_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    used_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_email_verifications_token ON email_verifications(token);
CREATE INDEX IF NOT EXISTS idx_email_verifications_user ON email_verifications(user_id);

-- -------------------------------------------------------------------
-- 3. PASSWORD RESETS
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS password_resets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    used_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_password_resets_token ON password_resets(token);
CREATE INDEX IF NOT EXISTS idx_password_resets_user ON password_resets(user_id);

-- -------------------------------------------------------------------
-- 4. REFRESH TOKENS (Rotated on every use)
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) UNIQUE NOT NULL, -- SHA-256 hash of the token
    device_info VARCHAR(500),
    ip_address VARCHAR(45),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    revoked_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_hash ON refresh_tokens(token_hash);

-- -------------------------------------------------------------------
-- 5. USER SESSIONS (Active session tracking)
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_info VARCHAR(500),
    ip_address VARCHAR(45),
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_sessions_user ON user_sessions(user_id);

-- -------------------------------------------------------------------
-- 6. AUDIT LOGS (Authentication events)
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL, -- 'register', 'login', 'logout', 'password_reset', 'account_delete', 'email_verify', 'token_refresh'
    ip_address VARCHAR(45),
    user_agent TEXT,
    metadata JSONB,
    success BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON audit_logs(created_at DESC);

-- -------------------------------------------------------------------
-- 7. Updated timestamp trigger
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
