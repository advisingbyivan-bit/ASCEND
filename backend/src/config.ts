import dotenv from "dotenv";
dotenv.config();

function required(key: string): string {
  const value = process.env[key];
  if (!value) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
  return value;
}

function optional(key: string, fallback: string): string {
  return process.env[key] || fallback;
}

export const config = {
  port: parseInt(optional("PORT", "3000"), 10),
  nodeEnv: optional("NODE_ENV", "development"),
  isProduction: process.env.NODE_ENV === "production",

  // Database
  databaseUrl: required("DATABASE_URL"),

  // Redis
  redisUrl: optional("REDIS_URL", "redis://localhost:6379"),

  // JWT
  jwtSecret: required("JWT_SECRET"),
  jwtExpiresIn: optional("JWT_EXPIRES_IN", "30d"),

  // AWS S3
  aws: {
    region: optional("AWS_REGION", "us-east-1"),
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    s3Bucket: optional("AWS_S3_BUCKET", "ascend-scans"),
  },

  // Anthropic
  anthropicApiKey: process.env.ANTHROPIC_API_KEY || "",

  // Apple Sign-In
  apple: {
    teamId: process.env.APPLE_TEAM_ID || "",
    keyId: process.env.APPLE_KEY_ID || "",
    serviceId: process.env.APPLE_SERVICE_ID || "com.ascend.app",
    privateKeyPath: process.env.APPLE_PRIVATE_KEY_PATH || "./AuthKey.p8",
    // For Railway: store the .p8 key contents as a base64-encoded env var
    privateKeyBase64: process.env.APPLE_PRIVATE_KEY_BASE64 || "",
  },

  // Google Sign-In
  google: {
    clientId: process.env.GOOGLE_CLIENT_ID || "",
  },

  // APNs
  apns: {
    keyPath: process.env.APNS_KEY_PATH || "./APNsAuthKey.p8",
    // For Railway: store the APNs .p8 key contents as a base64-encoded env var
    keyBase64: process.env.APNS_KEY_BASE64 || "",
    keyId: process.env.APNS_KEY_ID || "",
    teamId: process.env.APNS_TEAM_ID || "",
    bundleId: process.env.APNS_BUNDLE_ID || "com.ascend.app",
    production: process.env.APNS_PRODUCTION === "true",
  },
} as const;
