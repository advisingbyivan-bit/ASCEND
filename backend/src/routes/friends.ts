import { Router, Request, Response, NextFunction } from "express";
import { requireAuth } from "../middleware/auth";
import { FriendModel } from "../models/Friend";
import { UserModel } from "../models/User";
import { Errors } from "../middleware/errorHandler";
import {
  sendPushNotification,
  NotificationTemplates,
} from "../services/notifications";

const router = Router();

// All routes require authentication
router.use(requireAuth);

// --- POST /friends/invite ---
// Send a friend request by email or user ID.

router.post(
  "/invite",
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const userId = req.userId!;
      const { email, friendId } = req.body;

      if (!email && !friendId) {
        throw Errors.badRequest("Either email or friendId is required");
      }

      // Resolve the friend's user ID
      let targetUserId: string;

      if (friendId) {
        // Validate UUID
        if (
          !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
            friendId
          )
        ) {
          throw Errors.badRequest("Invalid friendId format");
        }
        const targetUser = await UserModel.findById(friendId);
        if (!targetUser) {
          throw Errors.notFound("User not found");
        }
        targetUserId = targetUser.id;
      } else {
        const targetUser = await UserModel.findByEmail(email);
        if (!targetUser) {
          throw Errors.notFound(
            "No user found with that email address"
          );
        }
        targetUserId = targetUser.id;
      }

      // Can't friend yourself
      if (targetUserId === userId) {
        throw Errors.badRequest("You cannot send a friend request to yourself");
      }

      // Check for existing friendship
      const existing = await FriendModel.findExisting(userId, targetUserId);
      if (existing) {
        if (existing.status === "accepted") {
          throw Errors.conflict("You are already friends with this user");
        }
        if (existing.status === "pending") {
          // If the other person sent the request, auto-accept
          if (existing.friend_id === userId) {
            const accepted = await FriendModel.accept(existing.id, userId);
            // Notify the original requester
            const currentUser = await UserModel.findById(userId);
            const originalRequester = await UserModel.findById(
              existing.user_id
            );
            if (originalRequester?.device_token && currentUser) {
              await sendPushNotification(
                originalRequester.device_token,
                NotificationTemplates.friendAccepted(
                  currentUser.display_name
                )
              );
            }
            return res.status(200).json({
              message: "Friend request accepted",
              friend: accepted,
            });
          }
          throw Errors.conflict("Friend request already pending");
        }
      }

      // Create the friend request
      const friend = await FriendModel.create(userId, targetUserId);

      // Send push notification to the target user
      const targetUser = await UserModel.findById(targetUserId);
      const currentUser = await UserModel.findById(userId);
      if (targetUser?.device_token && currentUser) {
        await sendPushNotification(
          targetUser.device_token,
          NotificationTemplates.friendRequest(currentUser.display_name)
        );
      }

      res.status(201).json({
        message: "Friend request sent",
        friend,
      });
    } catch (err) {
      next(err);
    }
  }
);

// --- POST /friends/:id/accept ---
// Accept a pending friend request.

router.post(
  "/:id/accept",
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const userId = req.userId!;
      const { id } = req.params;

      const friend = await FriendModel.accept(id, userId);
      if (!friend) {
        throw Errors.notFound(
          "Friend request not found or already accepted"
        );
      }

      // Notify the requester
      const requester = await UserModel.findById(friend.user_id);
      const currentUser = await UserModel.findById(userId);
      if (requester?.device_token && currentUser) {
        await sendPushNotification(
          requester.device_token,
          NotificationTemplates.friendAccepted(currentUser.display_name)
        );
      }

      res.json({
        message: "Friend request accepted",
        friend,
      });
    } catch (err) {
      next(err);
    }
  }
);

// --- GET /friends ---
// List the authenticated user's friends.

router.get("/", async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;
    const includePending = req.query.pending === "true";

    const friends = await FriendModel.findByUser(userId);

    let pending: Awaited<ReturnType<typeof FriendModel.findPendingForUser>> = [];
    if (includePending) {
      pending = await FriendModel.findPendingForUser(userId);
    }

    res.json({
      friends: friends.map((f) => ({
        id: f.id,
        userId: f.user_id === userId ? f.friend_id : f.user_id,
        displayName: f.display_name,
        overallScore: Number(f.overall_score),
        streak: f.current_streak,
        status: f.status,
        createdAt: f.created_at,
      })),
      ...(includePending && {
        pendingRequests: pending.map((p) => ({
          id: p.id,
          userId: p.user_id,
          displayName: p.display_name,
          createdAt: p.created_at,
        })),
      }),
    });
  } catch (err) {
    next(err);
  }
});

// --- DELETE /friends/:id ---
// Remove a friend or decline a pending request.

router.delete(
  "/:id",
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const userId = req.userId!;
      const { id } = req.params;

      const deleted = await FriendModel.delete(id, userId);
      if (!deleted) {
        throw Errors.notFound("Friendship not found");
      }

      res.json({ message: "Friend removed" });
    } catch (err) {
      next(err);
    }
  }
);

export default router;
