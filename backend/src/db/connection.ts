import { Pool } from "pg";
import { config } from "../config";

export const pool = new Pool({
  connectionString: config.databaseUrl,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
  // Railway PostgreSQL requires SSL; reject self-signed certs only in strict environments
  ...(config.isProduction
    ? { ssl: { rejectUnauthorized: false } }
    : {}),
});

pool.on("error", (err) => {
  console.error("Unexpected Postgres pool error:", err);
});

/**
 * Execute a single query against the pool.
 */
export async function query<T = any>(
  text: string,
  params?: any[]
): Promise<{ rows: T[]; rowCount: number | null }> {
  const start = Date.now();
  const result = await pool.query(text, params);
  const duration = Date.now() - start;

  if (!config.isProduction) {
    console.log("Executed query", {
      text: text.substring(0, 80),
      duration: `${duration}ms`,
      rows: result.rowCount,
    });
  }

  return { rows: result.rows as T[], rowCount: result.rowCount };
}

/**
 * Execute multiple statements inside a transaction.
 */
export async function transaction<T>(
  fn: (client: import("pg").PoolClient) => Promise<T>
): Promise<T> {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const result = await fn(client);
    await client.query("COMMIT");
    return result;
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
}
