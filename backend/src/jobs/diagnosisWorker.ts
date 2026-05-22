import Bull, { Queue, Job } from "bull";
import { config } from "../config";
import { ScanModel } from "../models/Scan";
import { DiagnosisModel } from "../models/Diagnosis";
import { UserModel } from "../models/User";
import { LeaderboardModel } from "../models/Leaderboard";
import { MilestoneModel } from "../models/Milestone";
import { ProgressMetricModel } from "../models/ProgressMetric";
import { analyzeBodyScan, DiagnosisResult } from "../services/claude";
import { generateReadUrl, extractKeyFromUrl } from "../services/s3";
import { invalidateLeaderboardCache } from "../services/redis";
import {
  sendPushNotification,
  NotificationTemplates,
} from "../services/notifications";

interface DiagnosisJobData {
  scanId: string;
  userId: string;
}

let diagnosisQueue: Queue<DiagnosisJobData> | null = null;

/**
 * Get or create the Bull queue for diagnosis processing.
 */
export function getDiagnosisQueue(): Queue<DiagnosisJobData> {
  if (!diagnosisQueue) {
    // Bull needs explicit Redis options for TLS connections (Railway uses rediss://)
    const bullRedisOpts = config.redisUrl.startsWith("rediss://")
      ? {
          redis: {
            tls: { rejectUnauthorized: false },
          },
        }
      : {};

    diagnosisQueue = new Bull<DiagnosisJobData>("diagnosis", config.redisUrl, {
      ...bullRedisOpts,
      defaultJobOptions: {
        attempts: 3,
        backoff: {
          type: "exponential",
          delay: 5000,
        },
      },
    });
  }
  return diagnosisQueue;
}

/**
 * Generate presigned read URLs for scan images.
 */
async function getReadableImageUrls(scan: {
  front_image_url: string | null;
  side_image_url: string | null;
  back_image_url: string | null;
}): Promise<{ front?: string; side?: string; back?: string }> {
  const urls: { front?: string; side?: string; back?: string } = {};

  if (scan.front_image_url) {
    const key = extractKeyFromUrl(scan.front_image_url);
    if (key) urls.front = await generateReadUrl(key);
  }
  if (scan.side_image_url) {
    const key = extractKeyFromUrl(scan.side_image_url);
    if (key) urls.side = await generateReadUrl(key);
  }
  if (scan.back_image_url) {
    const key = extractKeyFromUrl(scan.back_image_url);
    if (key) urls.back = await generateReadUrl(key);
  }

  return urls;
}

/**
 * Calculate which week number this scan falls on for the user.
 */
function calculateWeekNumber(userCreatedAt: Date, scanDate: Date): number {
  const diffMs = scanDate.getTime() - userCreatedAt.getTime();
  const diffWeeks = Math.floor(diffMs / (7 * 24 * 60 * 60 * 1000));
  return Math.max(1, diffWeeks + 1);
}

/**
 * Check and award milestones after a scan is completed.
 */
async function checkMilestones(userId: string): Promise<void> {
  const user = await UserModel.findById(userId);
  if (!user) return;

  const scanCount = await ScanModel.countByUser(userId);

  // Streak milestones
  const streakThresholds = [2, 4, 8, 12, 24, 52];
  for (const threshold of streakThresholds) {
    if (user.current_streak >= threshold) {
      const hasEarned = await MilestoneModel.hasEarned(
        userId,
        "streak",
        threshold
      );
      if (!hasEarned) {
        await MilestoneModel.create({
          user_id: userId,
          milestone_type: "streak",
          milestone_value: threshold,
        });
      }
    }
  }

  // Scan count milestones
  const scanThresholds = [1, 5, 10, 25, 50, 100];
  for (const threshold of scanThresholds) {
    if (scanCount >= threshold) {
      const hasEarned = await MilestoneModel.hasEarned(
        userId,
        "scans",
        threshold
      );
      if (!hasEarned) {
        await MilestoneModel.create({
          user_id: userId,
          milestone_type: "scans",
          milestone_value: threshold,
        });
      }
    }
  }

  // Diamond milestones
  const diamondThresholds = [50, 100, 250, 500, 1000];
  for (const threshold of diamondThresholds) {
    if (user.total_diamonds >= threshold) {
      const hasEarned = await MilestoneModel.hasEarned(
        userId,
        "diamonds",
        threshold
      );
      if (!hasEarned) {
        await MilestoneModel.create({
          user_id: userId,
          milestone_type: "diamonds",
          milestone_value: threshold,
        });
      }
    }
  }
}

/**
 * Update the user's streak based on scan timing.
 */
async function updateStreak(userId: string): Promise<void> {
  const user = await UserModel.findById(userId);
  if (!user) return;

  const now = new Date();
  const lastScan = user.last_scan_date;

  if (!lastScan) {
    // First scan ever
    await UserModel.update(userId, {
      current_streak: 1,
      longest_streak: Math.max(1, user.longest_streak),
      last_scan_date: now,
    });
    return;
  }

  // Check if the last scan was within the expected window (roughly weekly)
  const daysSinceLastScan =
    (now.getTime() - new Date(lastScan).getTime()) / (1000 * 60 * 60 * 24);

  let newStreak: number;
  if (daysSinceLastScan <= 10) {
    // Within a generous weekly window
    newStreak = user.current_streak + 1;
  } else {
    // Streak broken
    newStreak = 1;
  }

  await UserModel.update(userId, {
    current_streak: newStreak,
    longest_streak: Math.max(newStreak, user.longest_streak),
    last_scan_date: now,
  });
}

/**
 * Process a diagnosis job: fetch scan images, analyze with Claude Vision,
 * store results, and update user metrics.
 */
async function processDiagnosisJob(job: Job<DiagnosisJobData>): Promise<void> {
  const { scanId, userId } = job.data;

  console.log(`[DiagnosisWorker] Processing scan ${scanId} for user ${userId}`);

  try {
    // 1. Fetch the scan record
    const scan = await ScanModel.findById(scanId);
    if (!scan) {
      throw new Error(`Scan ${scanId} not found`);
    }

    // 2. Fetch the user for context
    const user = await UserModel.findById(userId);
    if (!user) {
      throw new Error(`User ${userId} not found`);
    }

    // 3. Generate presigned read URLs for the images
    const imageUrls = await getReadableImageUrls(scan);
    if (!imageUrls.front && !imageUrls.side && !imageUrls.back) {
      throw new Error("No scan images available for analysis");
    }

    // 4. Fetch previous scan data for comparison
    const previousScans = await ScanModel.findByUser(userId, 2, 0);
    const previousScan = previousScans.length > 1 ? previousScans[1] : null;
    let previousScanData: any = undefined;

    if (previousScan && previousScan.status === "completed") {
      const prevDiagnoses = await DiagnosisModel.findByScanId(previousScan.id);
      previousScanData = {
        overall_score: previousScan.overall_score,
        zones: prevDiagnoses.map((d) => ({
          zone_name: d.zone_name,
          status: d.status,
          delta: d.delta || 0,
          note: d.note || "",
        })),
      };
    }

    // 5. Analyze with Claude Vision
    job.progress(30);

    const diagnosisResult: DiagnosisResult = await analyzeBodyScan(
      imageUrls,
      {
        gender: user.gender,
        age: user.age,
        height_cm: user.height_cm,
        weight_kg: Number(user.weight_kg),
        goal_weight_kg: Number(user.goal_weight_kg),
        body_concerns: user.body_concerns,
        training_frequency: user.training_frequency,
        timeline: user.timeline,
      },
      previousScanData
    );

    job.progress(70);

    // 6. Store diagnosis zones
    await DiagnosisModel.createMany(
      scanId,
      userId,
      diagnosisResult.zones.map((z) => ({
        zone_name: z.zone_name,
        status: z.status,
        delta: z.delta,
        note: z.note,
      }))
    );

    // 7. Update scan status to completed
    await ScanModel.updateStatus(
      scanId,
      "completed",
      diagnosisResult.overall_score,
      diagnosisResult.iris_message
    );

    job.progress(85);

    // 8. Update streak
    await updateStreak(userId);

    // 9. Update progress metric for this week
    const weekNumber = calculateWeekNumber(user.created_at, new Date());
    const zoneScores: Record<string, number> = {};
    for (const zone of diagnosisResult.zones) {
      zoneScores[zone.zone_name] = zone.delta;
    }

    await ProgressMetricModel.upsert({
      user_id: userId,
      week_number: weekNumber,
      overall_score: diagnosisResult.overall_score,
      zone_scores: zoneScores,
      weight_kg: Number(user.weight_kg),
    });

    // 10. Update leaderboard entry
    await LeaderboardModel.updateEntry(userId, {
      overall_score: diagnosisResult.overall_score,
      streak: (await UserModel.findById(userId))?.current_streak || 0,
    });
    await invalidateLeaderboardCache();

    // 11. Check for new milestones
    await checkMilestones(userId);

    // 12. Send push notification
    const updatedUser = await UserModel.findById(userId);
    if (updatedUser?.device_token) {
      await sendPushNotification(
        updatedUser.device_token,
        NotificationTemplates.scanComplete(diagnosisResult.overall_score)
      );
    }

    job.progress(100);

    console.log(
      `[DiagnosisWorker] Completed scan ${scanId}: score=${diagnosisResult.overall_score}`
    );
  } catch (error) {
    console.error(`[DiagnosisWorker] Failed scan ${scanId}:`, error);

    // Mark the scan as failed
    const message =
      error instanceof Error ? error.message : "Unknown processing error";
    await ScanModel.updateStatus(scanId, "failed", undefined, message);

    throw error; // Re-throw so Bull retries
  }
}

/**
 * Start the diagnosis worker (registers the processor on the queue).
 */
export function startDiagnosisWorker(): void {
  const queue = getDiagnosisQueue();

  queue.process("analyze-scan", 2, processDiagnosisJob);

  queue.on("completed", (job) => {
    console.log(
      `[DiagnosisWorker] Job ${job.id} completed for scan ${job.data.scanId}`
    );
  });

  queue.on("failed", (job, err) => {
    console.error(
      `[DiagnosisWorker] Job ${job.id} failed for scan ${job.data.scanId}:`,
      err.message
    );
  });

  queue.on("stalled", (job) => {
    console.warn(`[DiagnosisWorker] Job ${job.id} stalled`);
  });

  console.log("[DiagnosisWorker] Worker started, processing diagnosis jobs");
}

/**
 * Graceful shutdown of the queue.
 */
export async function stopDiagnosisWorker(): Promise<void> {
  if (diagnosisQueue) {
    await diagnosisQueue.close();
    diagnosisQueue = null;
    console.log("[DiagnosisWorker] Worker stopped");
  }
}
