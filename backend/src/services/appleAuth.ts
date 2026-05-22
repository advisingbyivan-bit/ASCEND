import appleSignin from "apple-signin-auth";
import { config } from "../config";

export interface AppleTokenPayload {
  sub: string; // Apple user ID
  email?: string;
  email_verified?: boolean;
}

/**
 * Verify an Apple Sign-In identity token.
 *
 * The token is a JWT issued by Apple. We verify it using Apple's public keys
 * and ensure it was issued for our service/client ID.
 */
export async function verifyAppleToken(
  identityToken: string
): Promise<AppleTokenPayload> {
  try {
    const payload = await appleSignin.verifyIdToken(identityToken, {
      audience: config.apple.serviceId,
      ignoreExpiration: false,
    });

    return {
      sub: payload.sub,
      email: payload.email,
      email_verified:
        payload.email_verified === "true" || payload.email_verified === true,
    };
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Unknown verification error";
    throw new Error(`Apple token verification failed: ${message}`);
  }
}

/**
 * Get the authorization URL for Apple Sign-In (web flow).
 * This is primarily for testing; the iOS app uses native Sign-In with Apple.
 */
export function getAppleAuthUrl(state: string): string {
  return appleSignin.getAuthorizationUrl({
    clientID: config.apple.serviceId,
    redirectUri: `https://api.ascend.app/auth/apple/callback`,
    state,
  });
}
