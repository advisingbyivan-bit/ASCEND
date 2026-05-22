import { Router, Request, Response, NextFunction } from "express";
import { requireAuth } from "../middleware/auth";
import { MilestoneModel } from "../models/Milestone";
import { UserModel } from "../models/User";
import { Errors } from "../middleware/errorHandler";

const router = Router();

// All routes require authentication
router.use(requireAuth);

// Diamond rewards for each milestone type
const MILESTONE_REWARDS: Record<string, Record<number, number>> = {
  streak: {
    2: 10,
    4: 25,
    8: 50,
    12: 100,
    24: 250,
    52: 500,
  },
  scans: {
    1: 5,
    5: 15,
    10: 30,
    25: 75,
    50: 150,
    100: 300,
  },
  score_improvement: {
    5: 10,
    10: 25,
    20: 50,
    30: 100,
  },
  diamonds: {
    50: 10,
    100: 25,
    250: 50,
    500: 100,
    1000: 250,
  },
};

// --- GET /milestones ---
// List all milestones for the authenticated user.

router.get("/", async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;

    const milestones = await MilestoneModel.findByUser(userId);
    const unclaimedCount = await MilestoneModel.getUnclaimedCount(userId);

    res.json({
      milestones: milestones.map((m) => ({
        id: m.id,
        type: m.milestone_type,
        value: m.milestone_value,
        claimed: m.claimed,
        earnedAt: m.earned_at,
        claimedAt: m.claimed_at,
        reward: MILESTONE_REWARDS[m.milestone_type]?.[m.milestone_value] || 0,
      })),
      unclaimedCount,
    });
  } catch (err) {
    next(err);
  }
});

// --- POST /milestones/claim ---
// Claim a milestone reward (awards diamonds).

router.post(
  "/claim",
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const userId = req.userId!;
      const { milestoneId } = req.body;

      if (!milestoneId) {
        throw Errors.badRequest("milestoneId is required");
      }

      // Validate UUID format
      if (
        !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
          milestoneId
        )
      ) {
        throw Errors.badRequest("Invalid milestoneId format");
      }

      // Verify milestone exists and belongs to user
      const milestone = await MilestoneModel.findById(milestoneId);
      if (!milestone) {
        throw Errors.notFound("Milestone not found");
      }
      if (milestone.user_id !== userId) {
        throw Errors.forbidden("You do not have access to this milestone");
      }
      if (milestone.claimed) {
        throw Errors.conflict("Milestone already claimed");
      }

      // Determine the diamond reward
      const reward =
        MILESTONE_REWARDS[milestone.milestone_type]?.[
          milestone.milestone_value
        ] || 0;

      // Claim the milestone
      const claimed = await MilestoneModel.claim(milestoneId, userId);
      if (!claimed) {
        throw Errors.internal("Failed to claim milestone");
      }

      // Award diamonds to user
      if (reward > 0) {
        const user = await UserModel.findById(userId);
        if (user) {
          await UserModel.update(userId, {
            total_diamonds: user.total_diamonds + reward,
          });
        }
      }

      res.json({
        message: "Milestone claimed!",
        milestone: {
          id: claimed.id,
          type: claimed.milestone_type,
          value: claimed.milestone_value,
          claimed: true,
          claimedAt: claimed.claimed_at,
        },
        diamondsAwarded: reward,
      });
    } catch (err) {
      next(err);
    }
  }
);

// --- POST /milestones/claim-all ---
// Claim all unclaimed milestones at once.

router.post(
  "/claim-all",
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const userId = req.userId!;

      const milestones = await MilestoneModel.findByUser(userId);
      const unclaimed = milestones.filter((m) => !m.claimed);

      if (unclaimed.length === 0) {
        return res.json({
          message: "No unclaimed milestones",
          claimed: 0,
          diamondsAwarded: 0,
        });
      }

      let totalReward = 0;

      for (const m of unclaimed) {
        await MilestoneModel.claim(m.id, userId);
        const reward =
          MILESTONE_REWARDS[m.milestone_type]?.[m.milestone_value] || 0;
        totalReward += reward;
      }

      // Award all diamonds at once
      if (totalReward > 0) {
        const user = await UserModel.findById(userId);
        if (user) {
          await UserModel.update(userId, {
            total_diamonds: user.total_diamonds + totalReward,
          });
        }
      }

      res.json({
        message: `Claimed ${unclaimed.length} milestones!`,
        claimed: unclaimed.length,
        diamondsAwarded: totalReward,
      });
    } catch (err) {
      next(err);
    }
  }
);

export default router;
