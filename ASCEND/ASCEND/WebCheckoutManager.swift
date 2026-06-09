import Foundation
import UIKit
import Networking
import Paywall

/// Manages the app-to-web checkout flow for Stripe subscriptions.
/// Opens Safari with the checkout page, handles deep link return.
@MainActor
final class WebCheckoutManager {
    static let shared = WebCheckoutManager()
    private init() {}

    /// Whether a web checkout is in progress (user is in Safari)
    var isCheckoutInProgress = false

    /// Callback when subscription is confirmed
    var onSubscriptionActivated: (() -> Void)?

    // MARK: - Open Web Checkout

    /// Opens the web checkout page in Safari with the user's JWT token.
    /// The checkout page handles Stripe, then redirects back via Universal Link.
    func openCheckout(plan: String = "monthly") {
        guard let token = AuthClient.shared.token else {
            print("[WebCheckout] No auth token — user must be signed in")
            return
        }

        let baseURL = Secrets.stripeCheckoutURL.isEmpty
            ? "https://ascendapp.us/checkout"
            : Secrets.stripeCheckoutURL

        guard var components = URLComponents(string: baseURL) else { return }
        components.queryItems = [
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "plan", value: plan),
        ]

        guard let url = components.url else { return }

        isCheckoutInProgress = true
        UIApplication.shared.open(url)
    }

    // MARK: - Handle Deep Link Return

    /// Called when the app receives a Universal Link from the checkout success page.
    /// Returns true if the URL was handled.
    func handleUniversalLink(_ url: URL) -> Bool {
        guard let host = url.host,
              (host == "ascendapp.us" || host == "www.ascendapp.us") else {
            return false
        }

        let path = url.path

        // /open or /open?subscription=active — user returning from checkout
        if path.hasPrefix("/open") {
            isCheckoutInProgress = false

            // Check if subscription param indicates success
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let subscriptionStatus = components?.queryItems?.first(where: { $0.name == "subscription" })?.value

            if subscriptionStatus == "active" {
                // Refresh subscription status from backend
                Task {
                    await refreshSubscriptionFromBackend()
                    onSubscriptionActivated?()
                }
            }

            return true
        }

        // /checkout/success — direct success link
        if path.hasPrefix("/checkout/success") {
            isCheckoutInProgress = false
            Task {
                await refreshSubscriptionFromBackend()
                onSubscriptionActivated?()
            }
            return true
        }

        return false
    }

    // MARK: - Refresh from Backend

    /// Polls the backend to confirm the Stripe subscription is active.
    /// Stripe webhooks are near-instant but we give it a moment.
    private func refreshSubscriptionFromBackend() async {
        guard let token = AuthClient.shared.token, !token.isEmpty else { return }

        // Small delay to let Stripe webhook process
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s

        let url = URL(string: "\(Secrets.backendBaseURL)/stripe/status")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let status = try JSONDecoder().decode(SubscriptionStatusResponse.self, from: data)

            if status.subscription_status == "active" || status.subscription_status == "trialing" {
                print("[WebCheckout] Subscription confirmed: \(status.subscription_status)")
                // The SubscriptionManager will pick this up on next refresh
                // Force a status refresh
                await SubscriptionManager.shared.refreshStatus()
            } else {
                // Webhook might not have fired yet — retry once
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3s
                let (data2, _) = try await URLSession.shared.data(for: request)
                let status2 = try JSONDecoder().decode(SubscriptionStatusResponse.self, from: data2)
                if status2.subscription_status == "active" || status2.subscription_status == "trialing" {
                    print("[WebCheckout] Subscription confirmed on retry: \(status2.subscription_status)")
                    await SubscriptionManager.shared.refreshStatus()
                }
            }
        } catch {
            print("[WebCheckout] Failed to check subscription status: \(error)")
        }
    }
}

// MARK: - Response Model

private struct SubscriptionStatusResponse: Codable {
    let subscription_status: String
    let subscription_plan: String?
    let subscription_expiry: String?
    let subscription_source: String?
}
