import { query } from "../db/connection";

export interface Diagnosis {
  id: string;
  scan_id: string;
  user_id: string;
  zone_name: string;
  status: string;
  delta: number | null;
  note: string | null;
  created_at: Date;
}

export const DiagnosisModel = {
  async createMany(
    scanId: string,
    userId: string,
    zones: Array<{
      zone_name: string;
      status: string;
      delta?: number;
      note?: string;
    }>
  ): Promise<Diagnosis[]> {
    if (zones.length === 0) return [];

    const valuePlaceholders: string[] = [];
    const params: any[] = [];
    let paramIdx = 1;

    for (const zone of zones) {
      valuePlaceholders.push(
        `($${paramIdx}, $${paramIdx + 1}, $${paramIdx + 2}, $${paramIdx + 3}, $${paramIdx + 4}, $${paramIdx + 5})`
      );
      params.push(
        scanId,
        userId,
        zone.zone_name,
        zone.status,
        zone.delta ?? null,
        zone.note ?? null
      );
      paramIdx += 6;
    }

    const { rows } = await query<Diagnosis>(
      `INSERT INTO diagnoses (scan_id, user_id, zone_name, status, delta, note)
       VALUES ${valuePlaceholders.join(", ")}
       RETURNING *`,
      params
    );
    return rows;
  },

  async findByScanId(scanId: string): Promise<Diagnosis[]> {
    const { rows } = await query<Diagnosis>(
      "SELECT * FROM diagnoses WHERE scan_id = $1 ORDER BY created_at ASC",
      [scanId]
    );
    return rows;
  },

  async findByUserAndScan(
    userId: string,
    scanId: string
  ): Promise<Diagnosis[]> {
    const { rows } = await query<Diagnosis>(
      "SELECT * FROM diagnoses WHERE user_id = $1 AND scan_id = $2 ORDER BY created_at ASC",
      [userId, scanId]
    );
    return rows;
  },

  async findLatestByUser(userId: string): Promise<Diagnosis[]> {
    const { rows } = await query<Diagnosis>(
      `SELECT d.* FROM diagnoses d
       INNER JOIN (
         SELECT id FROM scans WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1
       ) s ON d.scan_id = s.id
       ORDER BY d.created_at ASC`,
      [userId]
    );
    return rows;
  },
};
