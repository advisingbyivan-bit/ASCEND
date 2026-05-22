import { config } from "../config";
import * as fs from "fs";
import * as jwt from "jsonwebtoken";
import * as http2 from "http2";

/**
 * APNs JWT token generation and push notification sending.
 *
 * Uses HTTP/2 to communicate with Apple Push Notification Service.
 */

let cachedToken: { token: string; issuedAt: number } | null = null;
const TOKEN_REFRESH_INTERVAL = 50 * 60 * 1000; // Refresh every 50 min (tokens valid for 60)

/**
 * Generate or retrieve a cached APNs JWT.
 */
function getApnsToken(): string {
  const now = Date.now();

  if (cachedToken && now - cachedToken.issuedAt < TOKEN_REFRESH_INTERVAL) {
    return cachedToken.token;
  }

  let privateKey: string;

  // Prefer base64-encoded env var (for Railway / containerised deploys)
  if (config.apns.keyBase64) {
    privateKey = Buffer.from(config.apns.keyBase64, "base64").toString("utf8");
  } else {
    try {
      privateKey = fs.readFileSync(config.apns.keyPath, "utf8");
    } catch {
      throw new Error(
        `APNs private key not found at ${config.apns.keyPath} and APNS_KEY_BASE64 is not set. Push notifications are disabled.`
      );
    }
  }

  const token = jwt.sign({}, privateKey, {
    algorithm: "ES256",
    keyid: config.apns.keyId,
    issuer: config.apns.teamId,
    expiresIn: "1h",
  });

  cachedToken = { token, issuedAt: now };
  return token;
}

/**
 * APNs host based on environment.
 */
function getApnsHost(): string {
  return config.apns.production
    ? "api.push.apple.com"
    : "api.sandbox.push.apple.com";
}

export interface PushPayload {
  title: string;
  body: string;
  badge?: number;
  sound?: string;
  data?: Record<string, any>;
}

/**
 * Send a push notification to a single device.
 */
export async function sendPushNotification(
  deviceToken: string,
  payload: PushPayload
): Promise<{ success: boolean; error?: string }> {
  if (!config.apns.keyId || !config.apns.teamId) {
    console.warn("APNs not configured, skipping push notification");
    return { success: false, error: "APNs not configured" };
  }

  let apnsToken: string;
  try {
    apnsToken = getApnsToken();
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    console.warn("APNs token generation failed:", message);
    return { success: false, error: message };
  }

  const apnsPayload = {
    aps: {
      alert: {
        title: payload.title,
        body: payload.body,
      },
      badge: payload.badge,
      sound: payload.sound || "default",
      "mutable-content": 1,
    },
    ...payload.data,
  };

  return new Promise((resolve) => {
    const host = getApnsHost();

    let client: http2.ClientHttp2Session;
    try {
      client = http2.connect(`https://${host}`);
    } catch (err) {
      resolve({ success: false, error: "Failed to connect to APNs" });
      return;
    }

    client.on("error", () => {
      resolve({ success: false, error: "HTTP/2 connection error" });
    });

    const req = client.request({
      ":method": "POST",
      ":path": `/3/device/${deviceToken}`,
      authorization: `bearer ${apnsToken}`,
      "apns-topic": config.apns.bundleId,
      "apns-push-type": "alert",
      "apns-priority": "10",
    });

    let responseData = "";
    let statusCode = 0;

    req.on("response", (headers) => {
      statusCode = headers[":status"] as number;
    });

    req.on("data", (chunk: Buffer) => {
      responseData += chunk.toString();
    });

    req.on("end", () => {
      client.close();
      if (statusCode === 200) {
        resolve({ success: true });
      } else {
        resolve({
          success: false,
          error: `APNs responded with ${statusCode}: ${responseData}`,
        });
      }
    });

    req.on("error", () => {
      client.close();
      resolve({ success: false, error: "APNs request error" });
    });

    req.write(JSON.stringify(apnsPayload));
    req.end();
  });
}

/**
 * Send a push notification to multiple device tokens.
 */
export async function sendBulkNotifications(
  deviceTokens: string[],
  payload: PushPayload
): Promise<Array<{ token: string; success: boolean; error?: string }>> {
  const results = await Promise.allSettled(
    deviceTokens.map(async (token) => {
      const result = await sendPushNotification(token, payload);
      return { token, ...result };
    })
  );

  return results.map((r) =>
    r.status === "fulfilled"
      ? r.value
      : { token: "", success: false, error: "Send failed" }
  );
}

/**
 * Pre-built notification templates for common events.
 */
export const NotificationTemplates = {
  scanComplete(overallScore: number): PushPayload {
    return {
      title: "Scan Complete",
      body: `Your IRIS analysis is ready! Overall score: ${overallScore.toFixed(1)}`,
      data: { type: "scan_complete" },
    };
  },

  streakReminder(currentStreak: number): PushPayload {
    return {
      title: "Keep Your Streak Alive!",
      body: `You're on a ${currentStreak}-week streak. Don't forget your weekly scan!`,
      data: { type: "streak_reminder" },
    };
  },

  milestoneEarned(milestoneType: string, milestoneValue: number): PushPayload {
    return {
      title: "New Milestone!",
      body: `Congratulations! You've reached ${milestoneType}: ${milestoneValue}`,
      data: { type: "milestone_earned", milestoneType, milestoneValue },
    };
  },

  friendRequest(fromName: string): PushPayload {
    return {
      title: "New Friend Request",
      body: `${fromName} wants to connect with you on ASCEND`,
      data: { type: "friend_request" },
    };
  },

  friendAccepted(friendName: string): PushPayload {
    return {
      title: "Friend Request Accepted",
      body: `${friendName} accepted your friend request!`,
      data: { type: "friend_accepted" },
    };
  },
};
