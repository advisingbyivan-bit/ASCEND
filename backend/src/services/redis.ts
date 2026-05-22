import Redis from "ioredis";
import { config } from "../config";

let redis: Redis | null = null;

/**
 * Get or create the Redis client singleton.
 */
export function getRedisClient(): Redis {
  if (!redis) {
    redis = new Redis(config.redisUrl, {
      maxRetriesPerRequest: 3,
      retryStrategy(times) {
        const delay = Math.min(times * 200, 5000);
        return delay;
      },
      lazyConnect: true,
      // Railway Redis uses rediss:// (TLS); accept self-signed certs
      ...(config.redisUrl.startsWith("rediss://")
        ? { tls: { rejectUnauthorized: false } }
        : {}),
    });

    redis.on("error", (err) => {
      console.error("Redis connection error:", err.message);
    });

    redis.on("connect", () => {
      console.log("Redis connected");
    });
  }
  return redis;
}

/**
 * Connect to Redis (call during app startup).
 */
export async function connectRedis(): Promise<void> {
  const client = getRedisClient();
  await client.connect();
}

/**
 * Disconnect Redis (call during shutdown).
 */
export async function disconnectRedis(): Promise<void> {
  if (redis) {
    await redis.quit();
    redis = null;
  }
}

// --- Leaderboard Cache ---

const LEADERBOARD_PREFIX = "lb:";
const LEADERBOARD_TTL = 300; // 5 minutes

/**
 * Cache a leaderboard result.
 */
export async function cacheLeaderboard(
  key: string,
  data: any
): Promise<void> {
  const client = getRedisClient();
  await client.setex(
    `${LEADERBOARD_PREFIX}${key}`,
    LEADERBOARD_TTL,
    JSON.stringify(data)
  );
}

/**
 * Retrieve a cached leaderboard result.
 */
export async function getCachedLeaderboard(key: string): Promise<any | null> {
  const client = getRedisClient();
  const cached = await client.get(`${LEADERBOARD_PREFIX}${key}`);
  if (!cached) return null;
  return JSON.parse(cached);
}

/**
 * Invalidate all leaderboard caches (call after score updates).
 */
export async function invalidateLeaderboardCache(): Promise<void> {
  const client = getRedisClient();
  const keys = await client.keys(`${LEADERBOARD_PREFIX}*`);
  if (keys.length > 0) {
    await client.del(...keys);
  }
}

// --- General Cache Helpers ---

/**
 * Set a value with TTL.
 */
export async function setCache(
  key: string,
  value: any,
  ttlSeconds: number
): Promise<void> {
  const client = getRedisClient();
  await client.setex(key, ttlSeconds, JSON.stringify(value));
}

/**
 * Get a cached value.
 */
export async function getCache<T = any>(key: string): Promise<T | null> {
  const client = getRedisClient();
  const cached = await client.get(key);
  if (!cached) return null;
  return JSON.parse(cached) as T;
}

/**
 * Delete a cached key.
 */
export async function deleteCache(key: string): Promise<void> {
  const client = getRedisClient();
  await client.del(key);
}

// --- Sorted Sets for Leaderboards ---

/**
 * Update a user's score in a Redis sorted set leaderboard.
 */
export async function updateLeaderboardScore(
  leaderboardKey: string,
  userId: string,
  score: number
): Promise<void> {
  const client = getRedisClient();
  await client.zadd(leaderboardKey, score, userId);
}

/**
 * Get the top N entries from a sorted set leaderboard.
 */
export async function getLeaderboardTop(
  leaderboardKey: string,
  count: number,
  offset: number = 0
): Promise<Array<{ userId: string; score: number }>> {
  const client = getRedisClient();
  const results = await client.zrevrange(
    leaderboardKey,
    offset,
    offset + count - 1,
    "WITHSCORES"
  );

  const entries: Array<{ userId: string; score: number }> = [];
  for (let i = 0; i < results.length; i += 2) {
    entries.push({
      userId: results[i],
      score: parseFloat(results[i + 1]),
    });
  }
  return entries;
}

/**
 * Get a user's rank in a sorted set (0-based, so add 1 for display).
 */
export async function getLeaderboardRank(
  leaderboardKey: string,
  userId: string
): Promise<number | null> {
  const client = getRedisClient();
  const rank = await client.zrevrank(leaderboardKey, userId);
  return rank !== null ? rank + 1 : null;
}
