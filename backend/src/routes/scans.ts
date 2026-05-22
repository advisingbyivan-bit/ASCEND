import { Router, Request, Response, NextFunction } from "express";
import { requireAuth } from "../middleware/auth";
import { ScanModel } from "../models/Scan";
import { DiagnosisModel } from "../models/Diagnosis";
import { generateUploadUrls, buildS3Url } from "../services/s3";
import { Errors } from "../middleware/errorHandler";

const router = Router();

// All routes require authentication
router.use(requireAuth);

// --- POST /scans ---
// Create a new scan record and return presigned S3 upload URLs.

router.post("/", async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;

    // Create the scan record in pending state
    const scan = await ScanModel.create({ user_id: userId });

    // Generate presigned upload URLs
    const uploadUrls = await generateUploadUrls(userId, scan.id);

    // Store the expected S3 keys as the image URLs so the worker can find them
    await ScanModel.updateImageUrls(scan.id, {
      front_image_url: buildS3Url(uploadUrls.front.key),
      side_image_url: buildS3Url(uploadUrls.side.key),
      back_image_url: buildS3Url(uploadUrls.back.key),
    });

    res.status(201).json({
      scan: {
        id: scan.id,
        status: "pending",
        created_at: scan.created_at,
      },
      uploadUrls: {
        front: uploadUrls.front.uploadUrl,
        side: uploadUrls.side.uploadUrl,
        back: uploadUrls.back.uploadUrl,
      },
    });
  } catch (err) {
    next(err);
  }
});

// --- GET /scans ---
// List the authenticated user's scans, paginated (newest first).

router.get("/", async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;

    const limit = Math.min(Math.max(parseInt(req.query.limit as string) || 20, 1), 100);
    const offset = Math.max(parseInt(req.query.offset as string) || 0, 0);

    const [scans, total] = await Promise.all([
      ScanModel.findByUser(userId, limit, offset),
      ScanModel.countByUser(userId),
    ]);

    res.json({
      scans,
      pagination: {
        total,
        limit,
        offset,
        hasMore: offset + limit < total,
      },
    });
  } catch (err) {
    next(err);
  }
});

// --- GET /scans/:id ---
// Get a single scan with its diagnoses.

router.get("/:id", async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;
    const scanId = req.params.id;

    // Validate UUID format
    if (
      !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
        scanId
      )
    ) {
      throw Errors.badRequest("Invalid scan ID format");
    }

    const scan = await ScanModel.findById(scanId);
    if (!scan) {
      throw Errors.notFound("Scan not found");
    }

    // Ensure the scan belongs to the authenticated user
    if (scan.user_id !== userId) {
      throw Errors.forbidden("You do not have access to this scan");
    }

    // Fetch diagnoses for this scan
    const diagnoses = await DiagnosisModel.findByScanId(scanId);

    res.json({
      scan,
      diagnoses,
    });
  } catch (err) {
    next(err);
  }
});

export default router;
