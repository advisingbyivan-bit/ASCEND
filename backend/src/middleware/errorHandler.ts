import { Request, Response, NextFunction } from "express";
import { config } from "../config";

/**
 * Custom application error with HTTP status code.
 */
export class AppError extends Error {
  public readonly statusCode: number;
  public readonly isOperational: boolean;

  constructor(
    message: string,
    statusCode: number = 500,
    isOperational: boolean = true
  ) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = isOperational;
    Object.setPrototypeOf(this, AppError.prototype);
  }
}

/**
 * Convenience constructors for common HTTP errors.
 */
export const Errors = {
  badRequest(message: string = "Bad request"): AppError {
    return new AppError(message, 400);
  },
  unauthorized(message: string = "Unauthorized"): AppError {
    return new AppError(message, 401);
  },
  forbidden(message: string = "Forbidden"): AppError {
    return new AppError(message, 403);
  },
  notFound(message: string = "Resource not found"): AppError {
    return new AppError(message, 404);
  },
  conflict(message: string = "Conflict"): AppError {
    return new AppError(message, 409);
  },
  internal(message: string = "Internal server error"): AppError {
    return new AppError(message, 500, false);
  },
};

/**
 * Global error handling middleware.
 * Must be registered LAST in the Express middleware chain.
 */
export function errorHandler(
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction
): void {
  // Log the error
  if (err instanceof AppError && err.isOperational) {
    console.warn(`[${err.statusCode}] ${err.message}`);
  } else {
    console.error("Unhandled error:", err);
  }

  // Determine status code and message
  const statusCode = err instanceof AppError ? err.statusCode : 500;
  const message =
    err instanceof AppError && err.isOperational
      ? err.message
      : "Internal server error";

  const responseBody: Record<string, any> = {
    error: message,
    statusCode,
  };

  // Include stack trace in development
  if (!config.isProduction && err.stack) {
    responseBody.stack = err.stack;
  }

  res.status(statusCode).json(responseBody);
}

/**
 * Catch-all for 404 routes.
 */
export function notFoundHandler(
  req: Request,
  res: Response,
  _next: NextFunction
): void {
  res.status(404).json({
    error: "Not found",
    message: `Route ${req.method} ${req.path} does not exist`,
    statusCode: 404,
  });
}
