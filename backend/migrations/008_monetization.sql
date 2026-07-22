-- ===================================================================
-- AfriRange AI — Migration 008: Monetization & Payment Architecture
-- ===================================================================

-- 1. SUBSCRIPTION PLANS TABLE
CREATE TABLE IF NOT EXISTS subscription_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_name VARCHAR(50) UNIQUE NOT NULL, -- 'free', 'basic', 'standard', 'premium'
    display_name VARCHAR(100) NOT NULL,
    monthly_price NUMERIC(10, 2) DEFAULT 0.00,
    currency VARCHAR(10) DEFAULT 'USD',
    ai_credits_included INT DEFAULT 10,
    features JSONB DEFAULT '{}'::jsonb,
    google_play_product_id VARCHAR(255) UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Seed subscription plans
INSERT INTO subscription_plans (plan_name, display_name, monthly_price, currency, ai_credits_included, features, google_play_product_id)
VALUES 
    ('free', 'Free Tier', 0.00, 'USD', 10, '{"max_farms": 1, "max_paddocks": 3, "ai_generation": false, "offline_maps": false}'::jsonb, 'afrirange_free'),
    ('basic', 'Basic Pastoralist Plan', 9.99, 'USD', 50, '{"max_farms": 2, "max_paddocks": 10, "ai_generation": true, "offline_maps": true}'::jsonb, 'afrirange_basic_monthly'),
    ('standard', 'Standard Commercial Plan', 29.99, 'USD', 200, '{"max_farms": 5, "max_paddocks": 30, "ai_generation": true, "offline_maps": true}'::jsonb, 'afrirange_standard_monthly'),
    ('premium', 'Premium Enterprise Plan', 79.99, 'USD', 1000, '{"max_farms": 25, "max_paddocks": 150, "ai_generation": true, "offline_maps": true}'::jsonb, 'afrirange_premium_monthly')
ON CONFLICT (plan_name) DO UPDATE SET 
    monthly_price = EXCLUDED.monthly_price,
    ai_credits_included = EXCLUDED.ai_credits_included,
    google_play_product_id = EXCLUDED.google_play_product_id;

-- 2. USER SUBSCRIPTIONS TABLE
CREATE TABLE IF NOT EXISTS user_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES subscription_plans(id),
    google_play_purchase_token TEXT,
    status VARCHAR(50) DEFAULT 'active', -- 'active', 'cancelled', 'expired', 'pending'
    start_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    end_date TIMESTAMP WITH TIME ZONE,
    auto_renew BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_subscription UNIQUE (user_id)
);

CREATE INDEX IF NOT EXISTS idx_user_subs_user ON user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subs_token ON user_subscriptions(google_play_purchase_token);

-- 3. AI CREDIT TRANSACTIONS TABLE
CREATE TABLE IF NOT EXISTS ai_credit_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    transaction_type VARCHAR(50) NOT NULL, -- 'monthly_grant', 'pack_purchase', 'consumption', 'bonus'
    credits_added INT DEFAULT 0,
    credits_used INT DEFAULT 0,
    balance_after INT NOT NULL,
    reference_id VARCHAR(255), -- Google Play Order ID, Feature Tag, etc.
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ai_credit_tx_user ON ai_credit_transactions(user_id, created_at DESC);

-- 4. PAYMENT RECORDS TABLE
CREATE TABLE IF NOT EXISTS payment_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    payment_provider VARCHAR(50) NOT NULL, -- 'google_play', 'paystack_external'
    amount NUMERIC(10, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    status VARCHAR(50) NOT NULL, -- 'completed', 'pending', 'failed', 'refunded'
    transaction_reference VARCHAR(255) NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_payment_records_user ON payment_records(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_payment_records_ref ON payment_records(transaction_reference);
