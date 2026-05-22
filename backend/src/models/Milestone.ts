import { query } from "../db/connection";

export interface Milestone {
  id: string;
  user_id: string;
  milestone_type: string;
  milestone_value: number;
  claimed: boolean;
  earned_at: Date;
  claimed_at: Date | null;
}

export const MilestoneModel = {
  async findByUser(userId: string): Promise<Milestone[]> {
    const { rows } = await query<Milestone>(
      "SELECT * FROM milestones WHERE user_id = $1 ORDER BY earned_at DESC",
      [userId]
    );
    return rows;
  },

  async findById(id: string): Promise<Milestone | null> {
    const { rows } = await query<Milestone>(
      "SELECT * FROM milestones WHERE id = $1",
      [id]
    );
    return rows[0] || null;
  },

  async create(data: {
    user_id: string;
    milestone_type: string;
    milestone_value: number;
  }): Promise<Milestone> {
    const { rows } = await query<Milestone>(
      `INSERT INTO milestones (user_id, milestone_type, milestone_value)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [data.user_id, data.milestone_type, data.milestone_value]
    );
    return rows[0];
  },

  async claim(id: string, userId: string): Promise<Milestone | null> {
    const { rows } = await query<Milestone>(
      `UPDATE milestones
       SET claimed = TRUE, claimed_at = NOW()
       WHERE id = $1 AND user_id = $2 AND claimed = FALSE
       RETURNING *`,
      [id, userId]
    );
    return rows[0] || null;
  },

  async hasEarned(
    userId: string,
    milestoneType: string,
    milestoneValue: number
  ): Promise<boolean> {
    const { rows } = await query<{ exists: boolean }>(
      `SELECT EXISTS(
        SELECT 1 FROM milestones
        WHERE user_id = $1 AND milestone_type = $2 AND milestone_value = $3
      ) as exists`,
      [userId, milestoneType, milestoneValue]
    );
    return rows[0].exists;
  },

  async getUnclaimedCount(userId: string): Promise<number> {
    const { rows } = await query<{ count: string }>(
      "SELECT COUNT(*) as count FROM milestones WHERE user_id = $1 AND claimed = FALSE",
      [userId]
    );
    return parseInt(rows[0].count, 10);
  },
};
