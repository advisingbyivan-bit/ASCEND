import { Router, Request, Response, NextFunction } from "express";
import { query } from "../db/connection";
import { AppError, Errors } from "../middleware/errorHandler";
import { requireAuth } from "../middleware/auth";

const router = Router();

/**
 * POST /waitlist
 * Public — adds an email to the launch waitlist.
 */
router.post(
  "/",
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { email, source } = req.body;

      if (!email || typeof email !== "string") {
        throw Errors.badRequest("email is required");
      }

      const trimmed = email.trim().toLowerCase();
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(trimmed)) {
        throw Errors.badRequest("Invalid email format");
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
