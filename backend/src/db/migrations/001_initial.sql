-- ASCEND Database Schema
-- Run with: npm run migrate

BEGIN;

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    apple_id VARCHAR(255) UNIQUE,
    google_id VARCHAR(255) UNIQUE,
    email VARCHAR(255) UNIQUE,
    email_verified BOOLEAN DEFAULT FALSE,
    password_hash VARCHAR(255),
    display_name VARCHAR(100) NOT NULL,
    gender VARCHAR(10) NOT NULL DEFAULT 'male',
    age INTEGER NOT NULL DEFAULT 25,
    height_cm INTEGER NOT NULL DEFAULT 175,
    weight_kg DECIMAL(5,2) NOT NULL DEFAULT 75.0,
    goal_weight_kg DECIMAL(5,2) NOT NULL DEFAULT 72.0,
    body_concerns TEXT DEFAULT '',
    training_frequency VARCHAR(20) DEFAULT 'moderate',
    timeline VARCHAR(20) DEFAULT '12 Weeks',
    scan_day VARCHAR(15) DEFAULT 'Sunday',
    rest_day VARCHAR(15) DEFAULT 'Wednesday',
    notification_hour INTEGER DEFAULT 8,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    total_diamonds INTEGER DEFAULT 0,
    last_scan_date TIMESTAMP,
    subscription_status VARCHAR(20) DEFAULT 'free',
    subscription_plan VARCHAR(50),
    subscription_expiry TIMESTAMP,
    device_token VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Scans table
CREATE TABLE IF NOT EXISTS scans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    front_image_url VARCHAR(500),
    side_image_url VARCHAR(500),
    back_image_url VARCHAR(500),
    overall_score DECIMAL(5,2) DEFAULT 0,
    iris_message TEXT DEFAULT '',
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_scans_user ON scans(user_id, created_at DESC);

-- Diagnoses table (zone-level breakdown)
CREATE TABLE IF NOT EXISTS diagnoses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scan_id UUID NOT NULL REFERENCES scans(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    zone_name VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL,
    delta DECIMAL(5,2),
    note TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_diagnoses_scan ON diagnoses(scan_id);

-- Progress metrics (weekly snapshots)
CREATE TABLE IF NOT EXISTS progress_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    week_number INTEGER NOT NULL,
    overall_score DECIMAL(5,2),
    zone_scores JSONB,
    weight_kg DECIMAL(5,2),
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_progress_user ON progress_metrics(user_id, week_number);

-- Leaderboard table
CREATE TABLE IF NOT EXISTS leaderboard (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    display_name VARCHAR(100) NOT NULL,
    focus_area VARCHAR(50),
    overall_score DECIMAL(5,2) DEFAULT 0,
    progress_pct DECIMAL(5,2) DEFAULT 0,
    streak INTEGER DEFAULT 0,
    diamonds INTEGER DEFAULT 0,
    badge_id VARCHAR(50),
    rank INTEGER DEFAULT 0,
    updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_leaderboard_rank ON leaderboard(rank);
CREATE INDEX IF NOT EXISTS idx_leaderboard_focus ON leaderboard(focus_area, rank);

-- Milestones table
CREATE TABLE IF NOT EXISTS milestones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    milestone_type VARCHAR(50) NOT NULL,
    milestone_value INTEGER NOT NULL,
    claimed BOOLEAN DEFAULT FALSE,
    earned_at TIMESTAMP DEFAULT NOW(),
    claimed_at TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_milestones_user ON milestones(user_id);

-- Friends table
CREATE TABLE IF NOT EXISTS friends (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    friend_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, friend_id)
);
CREATE INDEX IF NOT EXISTS idx_friends_user ON friends(user_id);
CREATE INDEX IF NOT EXISTS idx_friends_friend ON friends(friend_id);

-- Function to auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to users table
DROP TRIGGER IF EXISTS trigger_users_updated_at ON users;
CREATE TRIGGER trigger_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Apply trigger to leaderboard table
DROP TRIGGER IF EXISTS trigger_leaderboard_updated_at ON leaderboard;
CREATE TRIGGER trigger_leaderboard_updated_at
    BEFORE UPDATE ON leaderboard
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

COMMIT;
