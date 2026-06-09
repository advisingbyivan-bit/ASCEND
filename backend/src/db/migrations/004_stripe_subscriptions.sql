-- 004: Add Stripe customer tracking to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS stripe_customer_id VARCHAR(255);
CREATE INDEX IF NOT EXISTS idx_users_stripe_customer ON users(stripe_customer_id);

-- Track subscription source (stripe vs appstore) so we know which system manages each user
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_source VARCHAR(20) DEFAULT 'appstore';
-- Values: 'stripe', 'appstore', null
