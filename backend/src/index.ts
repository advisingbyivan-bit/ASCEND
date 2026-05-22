import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import fs from "fs";
import path from "path";

import { config } from "./config";
import { pool } from "./db/connection";
import { connectRedis, disconnectRedis } from "./services/redis";
import { errorHandler, notFoundHandler } from "./middleware/errorHandler";
import {
  startDiagnosisWorker,
  stopDiagnosisWorker,
} from "./jobs/diagnosisWorker";

// Route imports
import authRoutes from "./routes/auth";
import userRoutes from "./routes/users";
import scanRoutes from "./routes/scans";
import diagnosisRoutes from "./routes/diagnoses";
import leaderboardRoutes from "./routes/leaderboard";
import friendRoutes from "./routes/friends";
import milestoneRoutes from "./routes/milestones";

const app = express();

// --- Global Middleware ---

// Security headers
app.use(
  helmet({
    contentSecurityPolicy: false, // Allow API usage without CSP restrictions
  })
);

// CORS — allow mobile app origins
app.use(
  cors({
    origin: config.isProduction
      ? [
          "https://ascend.app",
          "capacitor://localhost",
          "ionic://localhost",
          // Railway default domains + custom domain
          /\.up\.railway\.app$/,
        ]
      : "*",
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH"],
    allowedHeaders: ["Content-Type", "Authorization"],
    maxAge: 86400, // 24 hours preflight cache
  })
);

// Request parsing
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true }));

// Logging
app.use(
  morgan(config.isProduction ? "combined" : "dev", {
    skip: (req) => req.url === "/health",
  })
);

// --- Health Check ---

app.get("/health", async (_req, res) => {
  try {
    // Quick DB check
    await pool.query("SELECT 1");
    res.json({
      status: "ok",
      timestamp: new Date().toISOString(),
      version: "1.0.0",
    });
  } catch {
    res.status(503).json({
      status: "error",
      timestamp: new Date().toISOString(),
    });
  }
});

// --- API Routes ---

app.use("/auth", authRoutes);
app.use("/users", userRoutes);
app.use("/scans", scanRoutes);
app.use("/diagnoses", diagnosisRoutes);
app.use("/leaderboard", leaderboardRoutes);
app.use("/friends", friendRoutes);
app.use("/milestones", milestoneRoutes);

// --- Error Handling ---

app.use(notFoundHandler);
app.use(errorHandler);

// --- Server Startup ---

async function runMigrations(): Promise<void> {
  const migrationsDir = path.join(__dirname, "db", "migrations");
  if (!fs.existsSync(migrationsDir)) {
    console.log("No migrations directory found, skipping");
    return;
  }
  const files = fs.readdirSync(migrationsDir).filter(f => f.endsWith(".sql")).sort();
  for (const file of files) {
    const sql = fs.readFileSync(path.join(migrationsDir, file), "utf8");
    try {
      await pool.query(sql);
      console.log(`Migration applied: ${file}`);
    } catch (err: any) {
      // IF NOT EXISTS clauses make re-runs safe; log but don't crash
      console.warn(`Migration warning for ${file}:`, err.message);
    }
  }
}

async function start(): Promise<void> {
  try {
    // Test database connection
    await pool.query("SELECT NOW()");
    console.log("Database connected");

    // Run migrations on startup
    await runMigrations();

    // Connect to Redis
    try {
      await connectRedis();
    } catch (err) {
      console.warn(
        "Redis connection failed — leaderboard caching and job queues will be degraded:",
        err instanceof Error ? err.message : err
      );
    }

    // Start the diagnosis worker
    try {
      startDiagnosisWorker();
    } catch (err) {
      console.warn(
        "Diagnosis worker startup failed:",
        err instanceof Error ? err.message : err
      );
    }

    // Start listening
    const server = app.listen(config.port, () => {
      console.log(
        `ASCEND API server running on port ${config.port} (${config.nodeEnv})`
      );
    });

    // Graceful shutdown
    const shutdown = async (signal: string) => {
      console.log(`\n${signal} received. Shutting down gracefully...`);

      server.close(async () => {
        try {
          await stopDiagnosisWorker();
          await disconnectRedis();
          await pool.end();
          console.log("All connections closed. Goodbye.");
          process.exit(0);
        } catch (err) {
          console.error("Error during shutdown:", err);
          process.exit(1);
        }
      });

      // Force exit after 15 seconds
      setTimeout(() => {
        console.error("Forced shutdown after timeout");
        process.exit(1);
      }, 15000);
    };

    process.on("SIGTERM", () => shutdown("SIGTERM"));
    process.on("SIGINT", () => shutdown("SIGINT"));
  } catch (err) {
    console.error("Failed to start server:", err);
    process.exit(1);
  }
}

start();

export default app;
