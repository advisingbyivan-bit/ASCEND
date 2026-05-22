-- Add UNIQUE constraint on leaderboard.user_id for ON CONFLICT upsert
ALTER TABLE leaderboard ADD CONSTRAINT leaderboard_user_id_unique UNIQUE (user_id);
