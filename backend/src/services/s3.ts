import {
  S3Client,
  PutObjectCommand,
  GetObjectCommand,
} from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { config } from "../config";
import { v4 as uuidv4 } from "uuid";

const s3Client = new S3Client({
  region: config.aws.region,
  ...(config.aws.accessKeyId && config.aws.secretAccessKey
    ? {
        credentials: {
          accessKeyId: config.aws.accessKeyId,
          secretAccessKey: config.aws.secretAccessKey,
        },
      }
    : {}),
});

const PRESIGN_EXPIRY_SECONDS = 300; // 5 minutes

export interface PresignedUploadUrls {
  scanId: string;
  front: { uploadUrl: string; key: string };
  side: { uploadUrl: string; key: string };
  back: { uploadUrl: string; key: string };
}

/**
 * Generate a unique S3 key for a scan image.
 */
function generateKey(
  userId: string,
  scanId: string,
  angle: "front" | "side" | "back"
): string {
  return `scans/${userId}/${scanId}/${angle}.jpg`;
}

/**
 * Generate presigned PUT URLs for uploading front, side, and back images.
 */
export async function generateUploadUrls(
  userId: string,
  scanId: string
): Promise<PresignedUploadUrls> {
  const angles = ["front", "side", "back"] as const;

  const urlPromises = angles.map(async (angle) => {
    const key = generateKey(userId, scanId, angle);
    const command = new PutObjectCommand({
      Bucket: config.aws.s3Bucket,
      Key: key,
      ContentType: "image/jpeg",
      Metadata: {
        userId,
        scanId,
        angle,
      },
    });

    const uploadUrl = await getSignedUrl(s3Client, command, {
      expiresIn: PRESIGN_EXPIRY_SECONDS,
    });

    return { angle, uploadUrl, key };
  });

  const results = await Promise.all(urlPromises);

  const urlMap: Record<string, { uploadUrl: string; key: string }> = {};
  for (const r of results) {
    urlMap[r.angle] = { uploadUrl: r.uploadUrl, key: r.key };
  }

  return {
    scanId,
    front: urlMap.front,
    side: urlMap.side,
    back: urlMap.back,
  };
}

/**
 * Generate a presigned GET URL for reading a stored image.
 */
export async function generateReadUrl(key: string): Promise<string> {
  const command = new GetObjectCommand({
    Bucket: config.aws.s3Bucket,
    Key: key,
  });

  return getSignedUrl(s3Client, command, {
    expiresIn: 3600, // 1 hour
  });
}

/**
 * Build the full S3 URL for a stored object (non-presigned, for internal use
 * where the bucket has appropriate access policies).
 */
export function buildS3Url(key: string): string {
  return `https://${config.aws.s3Bucket}.s3.${config.aws.region}.amazonaws.com/${key}`;
}

/**
 * Extract the S3 key from a full S3 URL.
 */
export function extractKeyFromUrl(url: string): string | null {
  const match = url.match(
    /s3\.[^/]+\.amazonaws\.com\/(.+?)(?:\?.*)?$/
  );
  if (match) return match[1];

  // Also handle path-style URLs
  const pathMatch = url.match(
    /amazonaws\.com\/[^/]+\/(.+?)(?:\?.*)?$/
  );
  return pathMatch ? pathMatch[1] : null;
}
