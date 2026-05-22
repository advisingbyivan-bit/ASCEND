import { query } from "../db/connection";

export interface User {
  id: string;
  apple_id: string | null;
  google_id: string | null;
  email: string | null;
  email_verified: boolean;
  password_hash: string | null;
  display_name: string;
  gender: string;
  age: number;
  height_cm: number;
  weight_kg: number;
  goal_weight_kg: number;
  body_concerns: string;
  training_frequency: string;
  timeline: string;
  scan_day: string;
  rest_day: string;
  notification_hour: number;
  current_streak: number;
  longest_streak: number;
  total_diamonds: number;
  last_scan_date: Date | null;
  subscription_status: string;
  subscription_plan: string | null;
  subscription_expiry: Date | null;
  device_token: string | null;
  created_at: Date;
  updated_at: Date;
}

/** Fields safe to return in API responses (excludes password_hash). */
export type PublicUser = Omit<User, "password_hash">;

const PUBLIC_COLUMNS = `
  id, apple_id, google_id, email, email_verified, display_name,
  gender, age, height_cm, weight_kg, goal_weight_kg, body_concerns,
  training_frequency, timeline, scan_day, rest_day, notification_hour,
  current_streak, longest_streak, total_diamonds, last_scan_date,
  subscription_status, subscription_plan, subscription_expiry,
  device_token, created_at, updated_at
`;

export const UserModel = {
  async findById(id: string): Promise<User | null> {
    const { rows } = await query<User>(
      "SELECT * FROM users WHERE id = $1",
      [id]
    );
    return rows[0] || null;
  },

  async findPublicById(id: string): Promise<PublicUser | null> {
    const { rows } = await query<PublicUser>(
      `SELECT ${PUBLIC_COLUMNS} FROM users WHERE id = $1`,
      [id]
    );
    return rows[0] || null;
  },

  async findByEmail(email: string): Promise<User | null> {
    const { rows } = await query<User>(
      "SELECT * FROM users WHERE email = $1",
      [email.toLowerCase()]
    );
    return rows[0] || null;
  },

  async findByAppleId(appleId: string): Promise<User | null> {
    const { rows } = await query<User>(
      "SELECT * FROM users WHERE apple_id = $1",
      [appleId]
    );
    return rows[0] || null;
  },

  async findByGoogleId(googleId: string): Promise<User | null> {
    const { rows } = await query<User>(
      "SELECT * FROM users WHERE google_id = $1",
      [googleId]
    );
    return rows[0] || null;
  },

  async create(data: {
    apple_id?: string;
    google_id?: string;
    email?: string;
    password_hash?: string;
    display_name: string;
    gender?: string;
    age?: number;
    height_cm?: number;
    weight_kg?: number;
    goal_weight_kg?: number;
  }): Promise<User> {
    const { rows } = await query<User>(
      `INSERT INTO users (apple_id, google_id, email, password_hash, display_name, gender, age, height_cm, weight_kg, goal_weight_kg)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
       RETURNING *`,
      [
        data.apple_id || null,
        data.google_id || null,
        data.email ? data.email.toLowerCase() : null,
        data.password_hash || null,
        data.display_name,
        data.gender || "male",
        data.age || 25,
        data.height_cm || 175,
        data.weight_kg || 75.0,
        data.goal_weight_kg || 72.0,
      ]
    );
    return rows[0];
  },

  async update(
    id: string,
    fields: Partial<
      Pick<
        User,
        | "display_name"
        | "gender"
        | "age"
        | "height_cm"
        | "weight_kg"
        | "goal_weight_kg"
        | "body_concerns"
        | "training_frequency"
        | "timeline"
        | "scan_day"
        | "rest_day"
        | "notification_hour"
        | "current_streak"
        | "longest_streak"
        | "total_diamonds"
        | "last_scan_date"
        | "subscription_status"
        | "subscription_plan"
        | "subscription_expiry"
        | "device_token"
        | "email_verified"
      >
    >
  ): Promise<PublicUser | null> {
    const allowed = Object.entries(fields).filter(
      ([_, v]) => v !== undefined
    );
    if (allowed.length === 0) return this.findPublicById(id);

    const setClauses = allowed.map(([key], i) => `${key} = $${i + 2}`);
    const values = allowed.map(([_, v]) => v);

    const { rows } = await query<PublicUser>(
      `UPDATE users SET ${setClauses.join(", ")} WHERE id = $1 RETURNING ${PUBLIC_COLUMNS}`,
      [id, ...values]
    );
    return rows[0] || null;
  },

  async delete(id: string): Promise<boolean> {
    const { rowCount } = await query("DELETE FROM users WHERE id = $1", [id]);
    return (rowCount ?? 0) > 0;
  },
};
