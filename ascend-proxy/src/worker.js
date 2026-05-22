/**
 * ASCEND API Proxy — Cloudflare Worker
 *
 * Proxies requests from the ASCEND iOS app to the Anthropic Claude API.
 * The API key lives here (as a Cloudflare secret), never in the app binary.
 *
 * Endpoints:
 *   POST /v1/messages  — proxies to Anthropic Messages API
 *   GET  /health       — health check
 *
 * Deploy:
 *   1. npm install -g wrangler
 *   2. wrangler login
 *   3. wrangler secret put ANTHROPIC_API_KEY  (paste your key)
 *   4. wrangler deploy
 *
 * The app calls: https://ascend-proxy.<your-subdomain>.workers.dev/v1/messages
 */

const ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages";
const ANTHROPIC_VERSION = "2023-06-01";

// Simple in-memory rate limiting (per worker instance)
const rateLimitMap = new Map();
const MAX_REQUESTS_PER_MINUTE = 30;
const RATE_LIMIT_WINDOW_MS = 60_000;

function checkRateLimit(ip) {
  const now = Date.now();
  const entry = rateLimitMap.get(ip);

  if (!entry || now - entry.windowStart > RATE_LIMIT_WINDOW_MS) {
    rateLimitMap.set(ip, { windowStart: now, count: 1 });
    return true;
  }

  if (entry.count >= MAX_REQUESTS_PER_MINUTE) {
    return false;
  }

  entry.count++;
  return true;
}

// Validate that the request body looks like a legit ASCEND request
function validateRequest(body) {
  if (!body || typeof body !== "object") return false;
  if (!body.model || typeof body.model !== "string") return false;
  if (!body.messages || !Array.isArray(body.messages)) return false;
  if (!body.max_tokens || typeof body.max_tokens !== "number") return false;
  // Limit max_tokens to prevent abuse
  if (body.max_tokens > 2048) return false;
  // Only allow our models
  const allowedModels = [
    "claude-sonnet-4-20250514",
    "claude-haiku-4-20250414",
  ];
  if (!allowedModels.includes(body.model)) return false;
  return true;
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // CORS preflight
    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type, X-App-Bundle",
          "Access-Control-Max-Age": "86400",
        },
      });
    }

    // Health check
    if (url.pathname === "/health" && request.method === "GET") {
      return Response.json({ status: "ok", service: "ascend-proxy" });
    }

    // Only accept POST to /v1/messages
    if (url.pathname !== "/v1/messages" || request.method !== "POST") {
      return Response.json(
        { error: "Not found" },
        { status: 404 }
      );
    }

    // Check app bundle header (basic app verification)
    const appBundle = request.headers.get("X-App-Bundle");
    if (appBundle !== "us.ascend.app.app") {
      return Response.json(
        { error: "Unauthorized" },
        { status: 403 }
      );
    }

    // Rate limiting by IP
    const clientIP = request.headers.get("CF-Connecting-IP") || "unknown";
    if (!checkRateLimit(clientIP)) {
      return Response.json(
        { error: "Rate limit exceeded. Try again in a minute." },
        { status: 429 }
      );
    }

    // Check API key is configured
    if (!env.ANTHROPIC_API_KEY) {
      return Response.json(
        { error: "Server misconfigured — API key not set" },
        { status: 500 }
      );
    }

    // Parse and validate the request body
    let body;
    try {
      body = await request.json();
    } catch {
      return Response.json(
        { error: "Invalid JSON body" },
        { status: 400 }
      );
    }

    if (!validateRequest(body)) {
      return Response.json(
        { error: "Invalid request format" },
        { status: 400 }
      );
    }

    // Forward to Anthropic with our server-side API key
    try {
      const anthropicResponse = await fetch(ANTHROPIC_API_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": env.ANTHROPIC_API_KEY,
          "anthropic-version": ANTHROPIC_VERSION,
        },
        body: JSON.stringify(body),
      });

      // Stream the response back
      const responseBody = await anthropicResponse.text();

      return new Response(responseBody, {
        status: anthropicResponse.status,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      });
    } catch (err) {
      return Response.json(
        { error: "Upstream API error", detail: err.message },
        { status: 502 }
      );
    }
  },
};
