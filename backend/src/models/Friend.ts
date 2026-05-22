import { query } from "../db/connection";

export interface Friend {
  id: string;
  user_id: string;
  friend_id: string;
  status: string;
  created_at: Date;
}

export interface FriendWithDetails extends Friend {
  display_name: string;
  overall_score: number;
  current_streak: number;
}

export const FriendModel = {
  async findByUser(userId: string): Promise<FriendWithDetails[]> {
    const { rows } = await query<FriendWithDetails>(
      `SELECT f.*,
              u.display_name,
              COALESCE(
                (SELECT overall_score FROM scans WHERE user_id = u.id ORDER BY created_at DESC LIMIT 1),
                0
              ) as overall_score,
              u.current_streak
       FROM friends f
       INNER JOIN users u ON (
         CASE WHEN f.user_id = $1 THEN f.friend_id ELSE f.user_id END
       ) = u.id
       WHERE (f.user_id = $1 OR f.friend_id = $1)
         AND f.status = 'accepted'
       ORDER BY f.created_at DESC`,
      [userId]
    );
    return rows;
  },

  async findPendingForUser(userId: string): Promise<FriendWithDetails[]> {
    const { rows } = await query<FriendWithDetails>(
      `SELECT f.*, u.display_name, 0 as overall_score, u.current_streak
       FROM friends f
       INNER JOIN users u ON f.user_id = u.id
       WHERE f.friend_id = $1 AND f.status = 'pending'
       ORDER BY f.created_at DESC`,
      [userId]
    );
    return rows;
  },

  async create(userId: string, friendId: string): Promise<Friend> {
    const { rows } = await query<Friend>(
      `INSERT INTO friends (user_id, friend_id, status)
       VALUES ($1, $2, 'pending')
       RETURNING *`,
      [userId, friendId]
    );
    return rows[0];
  },

  async accept(id: string, userId: string): Promise<Friend | null> {
    const { rows } = await query<Friend>(
      `UPDATE friends SET status = 'accepted'
       WHERE id = $1 AND friend_id = $2 AND status = 'pending'
       RETURNING *`,
      [id, userId]
    );
    return rows[0] || null;
  },

  async findExisting(
    userId: string,
    friendId: string
  ): Promise<Friend | null> {
    const { rows } = await query<Friend>(
      `SELECT * FROM friends
       WHERE (user_id = $1 AND friend_id = $2) OR (user_id = $2 AND friend_id = $1)`,
      [userId, friendId]
    );
    return rows[0] || null;
  },

  async delete(id: string, userId: string): Promise<boolean> {
    const { rowCount } = await query(
      "DELETE FROM friends WHERE id = $1 AND (user_id = $2 OR friend_id = $2)",
      [id, userId]
    );
    return (rowCount ?? 0) > 0;
  },

  async findFriendUserIds(userId: string): Promise<string[]> {
    const { rows } = await query<{ id: string }>(
      `SELECT CASE WHEN user_id = $1 THEN friend_id ELSE user_id END as id
       FROM friends
       WHERE (user_id = $1 OR friend_id = $1) AND status = 'accepted'`,
      [userId]
    );
    return rows.map((r) => r.id);
  },
};
