import { config } from "../config";

export interface GoogleTokenPayload {
  sub: string; // Google user ID
  email?: string;
  email_verified?: boolean;
}

/**
 * Verify a Google Sign-In ID token using Google's tokeninfo endpoint.
 *
 * The iOS app obtains an idToken via the Google Sign-In SDK.
 * We validate it server-side and ensure the audience matches our client ID.
 */
export async function verifyGoogleToken(
  idToken: string
): Promise<GoogleTokenPayload> {
  try {
    const response = await fetch(
      `https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken)}`
    );

    if (!response.ok) {
      throw new Error(`Google returned status ${response.status}`);
    }

    const payload = (await response.json()) as Record<string, unknown>;

    // Validate the audience claim matches our Google client ID
    if (payload.aud !== config.google.clientId) {
      throw new Error("Token audience does not match GOOGLE_CLIENT_ID");
    }

    return {
      sub: payload.sub as string,
      email: payload.email as string | undefined,
      email_verified: payload.email_verified === "true" || payload.email_verified === true,
    };
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Unknown verification error";
    throw new Error(`Google token verification failed: ${message}`);
  }
}
