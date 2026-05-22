import { Router, Request, Response, NextFunction } from "express";
import { requireAuth } from "../middleware/auth";
import { UserModel } from "../models/User";
import { LeaderboardModel } from "../models/Leaderboard";
import { Errors } from "../middleware/errorHandler";

const router = Router();

// All routes require authentication
router.use(requireAuth);

// --- GET /users/me ---

router.get("/me", async (req: Request, res: Response, next: NextFunction) => {
  try {
    const user = await UserModel.findPublicById(req.userId!);
    if (!user) {
      throw Errors.notFound("User not found");
    }

    res.json({ user });
  } catch (err) {
    next(err);
  }
});

// --- PUT /users/me ---

const ALLOWED_UPDATE_FIELDS = new Set([
  "display_name",
  "gender",
  "age",
  "height_cm",
  "weight_kg",
  "goal_weight_kg",
  "body_concerns",
  "training_frequency",
  "timeline",
  "scan_day",
  "rest_day",
  "notification_hour",
  "device_token",
]);

const VALID_GENDERS = new Set(["male", "female", "other"]);
const VALID_FREQUENCIES = new Set(["sedentary", "light", "moderate", "active", "intense"]);
const VALID_DAYS = new Set([
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
  "Sunday",
]);

router.put("/me", async (req: Request, res: Response, next: NextFunction) => {
  try {
    const updates: Record<string, any> = {};

    for (const [key, value] of Object.entries(req.body)) {
      if (ALLOWED_UPDATE_FIELDS.has(key) && value !== undefined) {
        updates[key] = value;
      }
    }

    if (Object.keys(updates).length === 0) {
      throw Errors.badRequest("No valid fields to update");
    }

    // Validate specific fields
    if (updates.display_name !== undefined) {
      const name = String(updates.display_name).trim();
      if (name.length < 1 || name.length > 100) {
        throw Errors.badRequest("display_name must be 1-100 characters");
      }
      updates.display_name = name;
    }

    if (updates.gender !== undefined && !VALID_GENDERS.has(updates.gender)) {
      throw Errors.badRequest("gender must be male, female, or other");
    }

    if (updates.age !== undefined) {
      const age = Number(updates.age);
      if (!Number.isInteger(age) || age < 13 || age > 120) {
        throw Errors.badRequest("age must be an integer between 13 and 120");
      }
      updates.age = age;
    }

    if (updates.height_cm !== undefined) {
      const h = Number(updates.height_cm);
      if (h < 50 || h > 300) {
        throw Errors.badRequest("height_cm must be between 50 and 300");
      }
      updates.height_cm = h;
    }

    if (updates.weight_kg !== undefined) {
      const w = Number(updates.weight_kg);
      if (w < 20 || w > 500) {
        throw Errors.badRequest("weight_kg must be between 20 and 500");
      }
      updates.weight_kg = w;
    }

    if (updates.goal_weight_kg !== undefined) {
      const gw = Number(updates.goal_weight_kg);
      if (gw < 20 || gw > 500) {
        throw Errors.badRequest("goal_weight_kg must be between 20 and 500");
      }
      updates.goal_weight_kg = gw;
    }

    if (
      updates.training_frequency !== undefined &&
      !VALID_FREQUENCIES.has(updates.training_frequency)
    ) {
      throw Errors.badRequest(
        "training_frequency must be one of: sedentary, light, moderate, active, intense"
      );
    }

    if (updates.scan_day !== undefined && !VALID_DAYS.has(updates.scan_day)) {
      throw Errors.badRequest("scan_day must be a valid day of the week");
    }

    if (updates.rest_day !== undefined && !VALID_DAYS.has(updates.rest_day)) {
      throw Errors.badRequest("rest_day must be a valid day of the week");
    }

    if (updates.notification_hour !== undefined) {
      const hour = Number(updates.notification_hour);
      if (!Number.isInteger(hour) || hour < 0 || hour > 23) {
        throw Errors.badRequest("notification_hour must be 0-23");
      }
      updates.notification_hour = hour;
    }

    const user = await UserModel.update(req.userId!, updates);
    if (!user) {
      throw Errors.notFound("User not found");
    }

    // Sync display_name to leaderboard if changed
    if (updates.display_name) {
      await LeaderboardModel.updateEntry(req.userId!, {
        display_name: updates.display_name,
      });
    }

    res.json({ user });
  } catch (err) {
    next(err);
  }
});

// --- DELETE /users/me ---

router.delete(
  "/me",
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const deleted = await UserModel.delete(req.userId!);
      if (!deleted) {
        throw Errors.notFound("User not found");
      }

      res.status(200).json({ message: "Account deleted successfully" });
    } catch (err) {
      next(err);
    }
  }
);

export default router;
