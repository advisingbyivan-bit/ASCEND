import { Router, Request, Response, NextFunction } from "express";
import { query } from "../db/connection";
import { AppError, Errors } from "../middleware/errorHandler";
import { requireAuth } from "../middleware/auth";
import { getRedisClient } from "../services/redis";

const router = Router();

// --- Spam Protection ---

const RATE_LIMIT_MAX = 5;          // max signups per IP per window
const RATE_LIMIT_WINDOW = 3600;    // 1 hour in seconds

// Common disposable/throwaway email domains
const DISPOSABLE_DOMAINS = new Set([
  "mailinator.com", "guerrillamail.com", "tempmail.com", "temp-mail.org",
  "throwam.com", "yopmail.com", "sharklasers.com", "guerrillamailblock.com",
  "grr.la", "guerrillamail.info", "guerrillamail.biz", "guerrillamail.de",
  "guerrillamail.net", "guerrillamail.org", "spam4.me", "trashmail.com",
  "trashmail.me", "trashmail.net", "dispostable.com", "mailnull.com",
  "spamgourmet.com", "spamgourmet.net", "spamgourmet.org", "trashmail.at",
  "trashmail.io", "trashmail.me", "wegwerfmail.de", "wegwerfmail.net",
  "wegwerfmail.org", "fakeinbox.com", "mailnesia.com", "maildrop.cc",
  "discard.email", "spamfree24.org", "mailfreeonline.com", "throwam.com",
  "getairmail.com", "filzmail.com", "owlpic.com", "tempinbox.com",
]);

async function checkRateLimit(ip: string): Promise<void> {
  let client;
  try {
    client = getRedisClient();
  } catch {
    // Redis unavailable — fail open (don't block legit users)
    return;
  }
  const key = `waitlist:rl:${ip}`;
  const current = await client.incr(key);
  if (current === 1) {
    await client.expire(key, RATE_LIMIT_WINDOW);
  }
  if (current > RATE_LIMIT_MAX) {
    throw Errors.badRequest("Too many requests. Please try again later.");
  }
}

/**
 * POST /waitlist
 * Public — adds an email to the launch waitlist.
 */
router.post(
  "/",
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { email, source, _hp } = req.body;

      // Honeypot — bots fill this hidden field, humans leave it empty
      if (_hp) {
        // Silently accept so bots don't know they were caught
        return res.status(200).json({
          message: "You're on the list! We'll email you when ASCEND launches.",
        });
      }

      // IP rate limiting
      const ip =
        (req.headers["x-forwarded-for"] as string)?.split(",")[0]?.trim() ||
        req.socket.remoteAddress ||
        "unknown";
      await checkRateLimit(ip);

      if (!email || typeof email !== "string") {
        throw Errors.badRequest("email is required");
      }

      const trimmed = email.trim().toLowerCase();

      // Email format check
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(trimmed)) {
        throw Errors.badRequest("Invalid email format");
      }

      // Disposable email domain check
      const domain = trimmed.split("@")[1];
      if (DISPOSABLE_DOMAINS.has(domain)) {
        throw Errors.badRequest("Please use a real email address.");
      }

      // Upsert — don't error on duplicates
      await query(
        `INSERT INTO waitlist (email, source)
         VALUES ($1, $2)
         ON CONFLICT (email) DO NOTHING`,
        [trimmed, source || "landing_page"]
      );

      res.status(200).json({
        message: "You're on the list! We'll email you when ASCEND launches.",
      });
    } catch (err) {
      next(err);
    }
  }
);

/**
 * GET /waitlist
 * Protected — returns all waitlist signups (for Ivan to export).
 */
router.get(
  "/",
  requireAuth,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { rows } = await query(
        "SELECT email, source, created_at FROM waitlist ORDER BY created_at DESC"
      );

      res.json({
        count: rows.length,
        emails: rows,
      });
    } catch (err) {
      next(err);
    }
  }
);

/**
 * GET /waitlist/count
 * Public — returns just the count (for social proof on landing page).
 */
router.get(
  "/count",
  async (_req: Request, res: Response, next: NextFunction) => {
    try {
      const { rows } = await query(
        "SELECT COUNT(*) as count FROM waitlist"
      );

      res.json({ count: parseInt(rows[0].count, 10) });
    } catch (err) {
      next(err);
    }
  }
);

export default router;
