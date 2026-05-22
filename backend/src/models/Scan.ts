import { query } from "../db/connection";

export interface Scan {
  id: string;
  user_id: string;
  front_image_url: string | null;
  side_image_url: string | null;
  back_image_url: string | null;
  overall_score: number;
  iris_message: string;
  status: string;
  created_at: Date;
}

export const ScanModel = {
  async create(data: {
    user_id: string;
    front_image_url?: string;
    side_image_url?: string;
    back_image_url?: string;
  }): Promise<Scan> {
    const { rows } = await query<Scan>(
      `INSERT INTO scans (user_id, front_image_url, side_image_url, back_image_url, status)
       VALUES ($1, $2, $3, $4, 'pending')
       RETURNING *`,
      [
        data.user_id,
        data.front_image_url || null,
        data.side_image_url || null,
        data.back_image_url || null,
      ]
    );
    return rows[0];
  },

  async findById(id: string): Promise<Scan | null> {
    const { rows } = await query<Scan>(
      "SELECT * FROM scans WHERE id = $1",
      [id]
    );
    return rows[0] || null;
  },

  async findByUser(
    userId: string,
    limit: number = 20,
    offset: number = 0
  ): Promise<Scan[]> {
    const { rows } = await query<Scan>(
      "SELECT * FROM scans WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3",
      [userId, limit, offset]
    );
    return rows;
  },

  async updateStatus(
    id: string,
    status: string,
    overallScore?: number,
    irisMessage?: string
  ): Promise<Scan | null> {
    const updates: string[] = ["status = $2"];
    const params: any[] = [id, status];
    let paramIdx = 3;

    if (overallScore !== undefined) {
      updates.push(`overall_score = $${paramIdx}`);
      params.push(overallScore);
      paramIdx++;
    }
    if (irisMessage !== undefined) {
      updates.push(`iris_message = $${paramIdx}`);
      params.push(irisMessage);
      paramIdx++;
    }

    const { rows } = await query<Scan>(
      `UPDATE scans SET ${updates.join(", ")} WHERE id = $1 RETURNING *`,
      params
    );
    return rows[0] || null;
  },

  async updateImageUrls(
    id: string,
    urls: {
      front_image_url?: string;
      side_image_url?: string;
      back_image_url?: string;
    }
  ): Promise<Scan | null> {
    const entries = Object.entries(urls).filter(([_, v]) => v !== undefined);
    if (entries.length === 0) return this.findById(id);

    const setClauses = entries.map(([key], i) => `${key} = $${i + 2}`);
    const values = entries.map(([_, v]) => v);

    const { rows } = await query<Scan>(
      `UPDATE scans SET ${setClauses.join(", ")} WHERE id = $1 RETURNING *`,
      [id, ...values]
    );
    return rows[0] || null;
  },

  async countByUser(userId: string): Promise<number> {
    const { rows } = await query<{ count: string }>(
      "SELECT COUNT(*) as count FROM scans WHERE user_id = $1",
      [userId]
    );
    return parseInt(rows[0].count, 10);
  },
};
