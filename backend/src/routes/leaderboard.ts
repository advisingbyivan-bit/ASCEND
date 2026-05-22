import { Router, Request, Response, NextFunction } from "express";
import { requireAuth } from "../middleware/auth";
import { LeaderboardModel } from "../models/Leaderboard";
import {
  getCachedLeaderboard,
  cacheLeaderboard,
} from "../services/redis";
import { Errors } from "../middleware/errorHandler";

const router = Router();

// All routes require authentication
router.use(requireAuth);

// --- GET /leaderboard?type=global|friends|goal&goalArea=xxx ---

router.get("/", async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;
    const type = (req.query.type as string) || "global";
    const goalArea = req.query.goalArea as string | undefined;
    const limit = Math.min(
      Math.max(parseInt(req.query.limit as string) || 50, 1),
      100
    );
    const offset = Math.max(parseInt(req.query.offset as string) || 0, 0);

    if (!["global", "friends", "goal"].includes(type)) {
      throw Errors.badRequest("type must be global, friends, or goal");
    }

    if (type === "goal" && !goalArea) {
      throw Errors.badRequest("goalArea is required when type=goal");
    }

    // Build cache key
    const cacheKey =
      type === "goal"
        ? `${type}:${goalArea}:${limit}:${offset}`
        : type === "friends"
          ? `${type}:${userId}:${limit}:${offset}`
          : `${type}:${limit}:${offset}`;

    // Check cache first
    const cached = await getCachedLeaderboard(cacheKey);
    if (cached) {
      return res.json(cached);
    }

    // Fetch from database
    let entries;
    switch (type) {
      case "friends":
        entries = await LeaderboardModel.getFriends(userId, limit, offset);
        break;
      case "goal":
        entries = await LeaderboardModel.getByFocusArea(
          goalArea!,
          limit,
          offset
        );
        break;
      case "global":
      default:
        entries = await LeaderboardModel.getGlobal(limit, offset);
        break;
    }

    const result = {
      type,
      goalArea: goalArea || null,
      entries: entries.map((e, index) => ({
        rank: offset + index + 1,
        userId: e.user_id,
        displayName: e.display_name,
        focusArea: e.focus_area,
        overallScore: Number(e.overall_score),
        progressPct: Number(e.progress_pct),
        streak: e.streak,
        diamonds: e.diamonds,
        badgeId: e.badge_id,
      })),
      pagination: {
        limit,
        offset,
        hasMore: entries.length === limit,
      },
    };

    // Cache the result
    await cacheLeaderboard(cacheKey, result);

    res.json(result);
  } catch (err) {
    next(err);
  }
});

// --- GET /leaderboard/me ---
// Get the current user's rank and leaderboard entry.

router.get("/me", async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;

    const { rank, entry } = await LeaderboardModel.getUserRank(userId);

    if (!entry) {
      return res.json({
        rank: 0,
        entry: null,
        message: "No leaderboard entry found. Complete a scan to join!",
      });
    }

    res.json({
      rank,
      entry: {
        userId: entry.user_id,
        displayName: entry.display_name,
        focusArea: entry.focus_area,
        overallScore: Number(entry.overall_score),
        progressPct: Number(entry.progress_pct),
        streak: entry.streak,
        diamonds: entry.diamonds,
        badgeId: entry.badge_id,
      },
    });
  } catch (err) {
    next(err);
  }
});

export default router;
