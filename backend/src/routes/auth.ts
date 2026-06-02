import { Router, Request, Response, NextFunction } from "express";
import bcrypt from "bcryptjs";
import { UserModel } from "../models/User";
import { LeaderboardModel } from "../models/Leaderboard";
import { generateToken } from "../middleware/auth";
import { verifyAppleToken } from "../services/appleAuth";
import { verifyGoogleToken } from "../services/googleAuth";
import { AppError, Errors } from "../middleware/errorHandler";
import { getRedisClient } from "../services/redis";

const router = Router();

const BCRYPT_ROUNDS = 12;

// --- Auth Rate Limiting ---

const AUTH_RATE_LIMIT_MAX = 10;      // max attempts per window
const AUTH_RATE_LIMIT_WINDOW = 900;  // 15 minutes

const inMemoryRateLimit = new Map<string, { count: number; resetAt: number }>();

async function checkAuthRateLimit(ip: string): Promise<void> {
  let client;
  try {
    client = getRedisClient();
    const key = `auth:rl:${ip}`;
    const current = await client.incr(key);
    if (current === 1) {
      await client.expire(key, AUTH_RATE_LIMIT_WINDOW);
    }
    if (current > AUTH_RATE_LIMIT_MAX) {
      throw Errors.badRequest(
        "Too many login attempts. Please try again in 15 minutes."
      );
    }
  } catch (err) {
    if (err instanceof AppError) throw err;
    // Redis unavailable — fall back to in-memory rate limiting
    const now = Date.now();
    const entry = inMemoryRateLimit.get(ip);
    if (entry && entry.resetAt > now) {
      entry.count++;
      if (entry.count > AUTH_RATE_LIMIT_MAX) {
        throw Errors.badRequest(
          "Too many login attempts. Please try again in 15 minutes."
        );
      }
    } else {
      inMemoryRateLimit.set(ip, {
        count: 1,
        resetAt: now + AUTH_RATE_LIMIT_WINDOW * 1000,
      });
    }
  }
}

// --- Validation helpers ---

function validateEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function validatePassword(password: string): string | null {
  if (password.length < 8) return "Password must be at least 8 characters";
  if (password.length > 128) return "Password must be at most 128 characters";
  return null;
}

function sanitizeDisplayName(name: string): string {
  return name.trim().substring(0, 100);
}

// --- POST /auth/apple ---

router.post(
  "/apple",
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      await checkAuthRateLimit(req.ip || "unknown");
      const { identityToken, displayName, email } = req.body;

      if (!identityToken) {
        throw Errors.badRequest("identityToken is required");
      }

      // Verify the Apple identity token
      const applePayload = await verifyAppleToken(identityToken);
      const appleId = applePayload.sub;

      // Check if user already exists
      let user = await UserModel.findByAppleId(appleId);

      if (!user) {
        // Create new user
        const name = sanitizeDisplayName(
          displayName || applePayload.email?.split("@")[0] || "ASCEND User"
        );

        user = await UserModel.create({
          apple_id: appleId,
          email: applePayload.email || email,
          display_name: name,
        });

        // Create initial leaderboard entry
        await LeaderboardModel.upsert({
          user_id: user.id,
          display_name: name,
        });
      }

      const token = generateToken(user.id);

      res.status(200).json({
        token,
        user: {
          id: user.id,
          displayName: user.display_name,
          email: user.email,
          isNewUser: !user.last_scan_date,
        },
      });
    } catch (err) {
      next(err);
    }
  }
);

// --- POST /auth/google ---

router.post(
  "/google",
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      await checkAuthRateLimit(req.ip || "unknown");
      const { idToken, displayName, email } = req.body;

      if (!idToken) {
        throw Errors.badRequest("idToken is required");
      }

      // Verify the Google ID token
      const googlePayload = await verifyGoogleToken(idToken);
      const googleId = googlePayload.sub;

      // Check if user already exists
      let user = await UserModel.findByGoogleId(googleId);

      if (!user) {
        // Create new user
        const name = sanitizeDisplayName(
          displayName || googlePayload.email?.split("@")[0] || "ASCEND User"
        );

        user = await UserModel.create({
          google_id: googleId,
          email: googlePayload.email || email,
          display_name: name,
        });

        // Create initial leaderboard entry
        await LeaderboardModel.upsert({
          user_id: user.id,
          display_name: name,
        });
      }

      const token = generateToken(user.id);

      res.status(200).json({
        token,
        user: {
          id: user.id,
          displayName: user.display_name,
          email: user.email,
          isNewUser: !user.last_scan_date,
        },
      });
    } catch (err) {
      next(err);
    }
  }
);

// --- POST /auth/register ---

router.post(
  "/register",
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      await checkAuthRateLimit(req.ip || "unknown");
      const { email, password, displayName, gender, age, height_cm, weight_kg, goal_weight_kg } =
        req.body;

      // Validate required fields
      if (!email || !password || !displayName) {
        throw Errors.badRequest(
          "email, password, and displayName are required"
        );
      }

      if (!validateEmail(email)) {
        throw Errors.badRequest("Invalid email format");
      }

      const passwordError = validatePassword(password);
      if (passwordError) {
        throw Errors.badRequest(passwordError);
      }

      const trimmedName = sanitizeDisplayName(displayName);
      if (trimmedName.length < 1) {
        throw Errors.badRequest("displayName cannot be empty");
      }

      // Check if email is already taken
      const existing = await UserModel.findByEmail(email);
      if (existing) {
        throw Errors.conflict("An account with this email already exists");
      }

      // Hash password
      const passwordHash = await bcrypt.hash(password, BCRYPT_ROUNDS);

      // Create user
      const user = await UserModel.create({
        email,
        password_hash: passwordHash,
        display_name: trimmedName,
        gender: gender || "male",
        age: age || 25,
        height_cm: height_cm || 175,
        weight_kg: weight_kg || 75.0,
        goal_weight_kg: goal_weight_kg || 72.0,
      });

      // Create initial leaderboard entry
      await LeaderboardModel.upsert({
        user_id: user.id,
        display_name: trimmedName,
      });

      const token = generateToken(user.id);

      res.status(201).json({
        token,
        user: {
          id: user.id,
          displayName: user.display_name,
          email: user.email,
          isNewUser: true,
        },
      });
    } catch (err) {
      next(err);
    }
  }
);

// --- POST /auth/login ---

router.post(
  "/login",
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      await checkAuthRateLimit(req.ip || "unknown");
      const { email, password } = req.body;

      if (!email || !password) {
        throw Errors.badRequest("email and password are required");
      }

      const user = await UserModel.findByEmail(email);
      if (!user || !user.password_hash) {
        throw Errors.unauthorized("Invalid email or password");
      }

      const isValid = await bcrypt.compare(password, user.password_hash);
      if (!isValid) {
        throw Errors.unauthorized("Invalid email or password");
      }

      const token = generateToken(user.id);

      res.status(200).json({
        token,
        user: {
          id: user.id,
          displayName: user.display_name,
          email: user.email,
          isNewUser: !user.last_scan_date,
        },
      });
    } catch (err) {
      next(err);
    }
  }
);

export default router;
