import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import { config } from "../config";

/**
 * Extend the Express Request type to include our auth fields.
 */
declare global {
  namespace Express {
    interface Request {
      userId?: string;
    }
  }
}

interface JwtPayload {
  userId: string;
  iat: number;
  exp: number;
}

/**
 * Generate a JWT for the given user ID.
 */
export function generateToken(userId: string): string {
  return jwt.sign({ userId }, config.jwtSecret as jwt.Secret, {
    expiresIn: config.jwtExpiresIn,
  } as jwt.SignOptions);
}

/**
 * Middleware: require a valid JWT in the Authorization header.
 *
 * On success, sets req.userId.
 * On failure, returns 401.
 */
export function requireAuth(
  req: Request,
  res: Response,
  next: NextFunction
): void {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    res.status(401).json({
      error: "Unauthorized",
      message: "Missing or malformed Authorization header",
    });
    return;
  }

  const token = authHeader.substring(7);

  try {
    const decoded = jwt.verify(token, config.jwtSecret) as JwtPayload;
    req.userId = decoded.userId;
    next();
  } catch (err) {
    if (err instanceof jwt.TokenExpiredError) {
      res.status(401).json({
        error: "TokenExpired",
        message: "Authentication token has expired",
      });
      return;
    }

    res.status(401).json({
      error: "Unauthorized",
      message: "Invalid authentication token",
    });
  }
}

/**
 * Middleware: optionally attach userId if a valid token is present, but don't
 * reject the request if it's missing.
 */
export function optionalAuth(
  req: Request,
  res: Response,
  next: NextFunction
): void {
  const authHeader = req.headers.authorization;

  if (authHeader && authHeader.startsWith("Bearer ")) {
    const token = authHeader.substring(7);
    try {
      const decoded = jwt.verify(token, config.jwtSecret) as JwtPayload;
      req.userId = decoded.userId;
    } catch {
      // Token invalid — proceed without auth
    }
  }

  next();
}
