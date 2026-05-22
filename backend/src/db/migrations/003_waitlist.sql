-- Email waitlist for pre-launch signups
CREATE TABLE IF NOT EXISTS waitlist (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    source VARCHAR(50) DEFAULT 'landing_page',
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_waitlist_email ON waitlist(email);
