import { query } from "../db/connection";

export interface ProgressMetric {
  id: string;
  user_id: string;
  week_number: number;
  overall_score: number | null;
  zone_scores: Record<string, number> | null;
  weight_kg: number | null;
  notes: string | null;
  created_at: Date;
}

export const ProgressMetricModel = {
  async create(data: {
    user_id: string;
    week_number: number;
    overall_score?: number;
    zone_scores?: Record<string, number>;
    weight_kg?: number;
    notes?: string;
  }): Promise<ProgressMetric> {
    const { rows } = await query<ProgressMetric>(
      `INSERT INTO progress_metrics (user_id, week_number, overall_score, zone_scores, weight_kg, notes)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [
        data.user_id,
        data.week_number,
        data.overall_score ?? null,
        data.zone_scores ? JSON.stringify(data.zone_scores) : null,
        data.weight_kg ?? null,
        data.notes ?? null,
      ]
    );
    return rows[0];
  },

  async findByUser(userId: string): Promise<ProgressMetric[]> {
    const { rows } = await query<ProgressMetric>(
      "SELECT * FROM progress_metrics WHERE user_id = $1 ORDER BY week_number ASC",
      [userId]
    );
    return rows;
  },

  async findByUserAndWeek(
    userId: string,
    weekNumber: number
  ): Promise<ProgressMetric | null> {
    const { rows } = await query<ProgressMetric>(
      "SELECT * FROM progress_metrics WHERE user_id = $1 AND week_number = $2",
      [userId, weekNumber]
    );
    return rows[0] || null;
  },

  async upsert(data: {
    user_id: string;
    week_number: number;
    overall_score?: number;
    zone_scores?: Record<string, number>;
    weight_kg?: number;
    notes?: string;
  }): Promise<ProgressMetric> {
    const { rows } = await query<ProgressMetric>(
      `INSERT INTO progress_metrics (user_id, week_number, overall_score, zone_scores, weight_kg, notes)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (user_id, week_number)
       DO UPDATE SET
         overall_score = COALESCE(EXCLUDED.overall_score, progress_metrics.overall_score),
         zone_scores = COALESCE(EXCLUDED.zone_scores, progress_metrics.zone_scores),
         weight_kg = COALESCE(EXCLUDED.weight_kg, progress_metrics.weight_kg),
         notes = COALESCE(EXCLUDED.notes, progress_metrics.notes)
       RETURNING *`,
      [
        data.user_id,
        data.week_number,
        data.overall_score ?? null,
        data.zone_scores ? JSON.stringify(data.zone_scores) : null,
        data.weight_kg ?? null,
        data.notes ?? null,
      ]
    );
    return rows[0];
  },
};
