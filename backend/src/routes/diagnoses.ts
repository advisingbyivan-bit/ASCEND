import { Router, Request, Response, NextFunction } from "express";
import { requireAuth } from "../middleware/auth";
import { ScanModel } from "../models/Scan";
import { DiagnosisModel } from "../models/Diagnosis";
import { Errors } from "../middleware/errorHandler";
import { getDiagnosisQueue } from "../jobs/diagnosisWorker";

const router = Router();

// All routes require authentication
router.use(requireAuth);

// --- POST /diagnoses ---
// Trigger Claude Vision analysis for a scan. Enqueues a Bull job.

router.post("/", async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;
    const { scanId } = req.body;

    if (!scanId) {
      throw Errors.badRequest("scanId is required");
    }

    // Validate UUID format
    if (
      !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
        scanId
      )
    ) {
      throw Errors.badRequest("Invalid scanId format");
    }

    // Verify scan exists and belongs to user
    const scan = await ScanModel.findById(scanId);
    if (!scan) {
      throw Errors.notFound("Scan not found");
    }
    if (scan.user_id !== userId) {
      throw Errors.forbidden("You do not have access to this scan");
    }

    // Check if diagnosis already exists or is in progress
    if (scan.status === "completed") {
      const existingDiagnoses = await DiagnosisModel.findByScanId(scanId);
      return res.status(200).json({
        message: "Diagnosis already completed",
        scan,
        diagnoses: existingDiagnoses,
      });
    }

    if (scan.status === "processing") {
      return res.status(202).json({
        message: "Diagnosis is already being processed",
        scan,
      });
    }

    // Update scan status to processing
    await ScanModel.updateStatus(scanId, "processing");

    // Enqueue the diagnosis job
    const queue = getDiagnosisQueue();
    const job = await queue.add(
      "analyze-scan",
      {
        scanId,
        userId,
      },
      {
        attempts: 3,
        backoff: {
          type: "exponential",
          delay: 5000,
        },
        removeOnComplete: 100,
        removeOnFail: 50,
      }
    );

    res.status(202).json({
      message: "Diagnosis queued for processing",
      jobId: job.id,
      scan: {
        id: scan.id,
        status: "processing",
      },
    });
  } catch (err) {
    next(err);
  }
});

// --- GET /diagnoses/:scanId ---
// Get diagnosis results for a specific scan.

router.get(
  "/:scanId",
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const userId = req.userId!;
      const { scanId } = req.params;

      // Validate UUID format
      if (
        !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
          scanId
        )
      ) {
        throw Errors.badRequest("Invalid scanId format");
      }

      // Verify scan exists and belongs to user
      const scan = await ScanModel.findById(scanId);
      if (!scan) {
        throw Errors.notFound("Scan not found");
      }
      if (scan.user_id !== userId) {
        throw Errors.forbidden("You do not have access to this scan");
      }

      // If still processing, return status
      if (scan.status === "pending" || scan.status === "processing") {
        return res.status(200).json({
          scan: {
            id: scan.id,
            status: scan.status,
          },
          diagnoses: [],
        });
      }

      // If failed, return the error
      if (scan.status === "failed") {
        return res.status(200).json({
          scan: {
            id: scan.id,
            status: "failed",
            iris_message: scan.iris_message,
          },
          diagnoses: [],
        });
      }

      // Return completed diagnosis
      const diagnoses = await DiagnosisModel.findByScanId(scanId);

      res.json({
        scan: {
          id: scan.id,
          status: scan.status,
          overall_score: scan.overall_score,
          iris_message: scan.iris_message,
          created_at: scan.created_at,
        },
        diagnoses,
      });
    } catch (err) {
      next(err);
    }
  }
);

export default router;
