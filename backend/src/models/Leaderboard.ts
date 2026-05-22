import { query } from "../db/connection";

export interface LeaderboardEntry {
  id: string;
  user_id: string;
  display_name: string;
  focus_area: string | null;
  overall_score: number;
  progress_pct: number;
  streak: number;
  diamonds: number;
  badge_id: string | null;
  rank: number;
  updated_at: Date;
}

export const LeaderboardModel = {
  async upsert(data: {
    user_id: string;
    display_name: string;
    focus_area?: string;
    overall_score?: number;
    progress_pct?: number;
    streak?: number;
    diamonds?: number;
    badge_id?: string;
  }): Promise<LeaderboardEntry> {
    const { rows } = await query<LeaderboardEntry>(
      `INSERT INTO leaderboard (user_id, display_name, focus_area, overall_score, progress_pct, streak, diamonds, badge_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       ON CONFLICT (user_id)
       DO UPDATE SET
         display_name = EXCLUDED.display_name,
         focus_area = COALESCE(EXCLUDED.focus_area, leaderboard.focus_area),
         overall_score = COALESCE(EXCLUDED.overall_score, leaderboard.overall_score),
         progress_pct = COALESCE(EXCLUDED.progress_pct, leaderboard.progress_pct),
         streak = COALESCE(EXCLUDED.streak, leaderboard.streak),
         diamonds = COALESCE(EXCLUDED.diamonds, leaderboard.diamonds),
         badge_id = COALESCE(EXCLUDED.badge_id, leaderboard.badge_id)
       RETURNING *`,
      [
        data.user_id,
        data.display_name,
        data.focus_area ?? null,
        data.overall_score ?? 0,
        data.progress_pct ?? 0,
        data.streak ?? 0,
        data.diamonds ?? 0,
        data.badge_id ?? null,
      ]
    );
    return rows[0];
  },

  async getGlobal(limit: number = 50, offset: number = 0): Promise<LeaderboardEntry[]> {
    const { rows } = await query<LeaderboardEntry>(
      `SELECT *, ROW_NUMBER() OVER (ORDER BY overall_score DESC) as rank
       FROM leaderboard
       ORDER BY overall_score DESC
       LIMIT $1 OFFSET $2`,
      [limit, offset]
    );
    return rows;
  },

  async getByFocusArea(
    focusArea: string,
    limit: number = 50,
    offset: number = 0
  ): Promise<LeaderboardEntry[]> {
    const { rows } = await query<LeaderboardEntry>(
      `SELECT *, ROW_NUMBER() OVER (ORDER BY overall_score DESC) as rank
       FROM leaderboard
       WHERE focus_area = $1
       ORDER BY overall_score DESC
       LIMIT $2 OFFSET $3`,
      [focusArea, limit, offset]
    );
    return rows;
  },

  async getFriends(
    userId: string,
    limit: number = 50,
    offset: number = 0
  ): Promise<LeaderboardEntry[]> {
    const { rows } = await query<LeaderboardEntry>(
      `SELECT l.*, ROW_NUMBER() OVER (ORDER BY l.overall_score DESC) as rank
       FROM leaderboard l
       WHERE l.user_id = $1
          OR l.user_id IN (
            SELECT friend_id FROM friends WHERE user_id = $1 AND status = 'accepted'
            UNION
            SELECT user_id FROM friends WHERE friend_id = $1 AND status = 'accepted'
          )
       ORDER BY l.overall_score DESC
       LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );
    return rows;
  },

  async getUserRank(userId: string): Promise<{ rank: number; entry: LeaderboardEntry | null }> {
    const { rows } = await query<LeaderboardEntry & { rank: number }>(
      `SELECT *, (
        SELECT COUNT(*) + 1 FROM leaderboard l2 WHERE l2.overall_score > leaderboard.overall_score
       ) as rank
       FROM leaderboard
       WHERE user_id = $1`,
      [userId]
    );
    if (rows.length === 0) {
      return { rank: 0, entry: null };
    }
    return { rank: rows[0].rank, entry: rows[0] };
  },

  async updateEntry(
    userId: string,
    fields: Partial<Pick<LeaderboardEntry, "display_name" | "focus_area" | "overall_score" | "progress_pct" | "streak" | "diamonds" | "badge_id">>
  ): Promise<LeaderboardEntry | null> {
    const entries = Object.entries(fields).filter(([_, v]) => v !== undefined);
    if (entries.length === 0) return null;

    const setClauses = entries.map(([key], i) => `${key} = $${i + 2}`);
    const values = entries.map(([_, v]) => v);

    const { rows } = await query<LeaderboardEntry>(
      `UPDATE leaderboard SET ${setClauses.join(", ")} WHERE user_id = $1 RETURNING *`,
      [userId, ...values]
    );
    return rows[0] || null;
  },
};
