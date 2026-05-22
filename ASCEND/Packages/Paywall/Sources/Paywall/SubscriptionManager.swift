import Foundation
import StoreKit

@Observable
public final class SubscriptionManager {
    public static let shared = SubscriptionManager()

    public enum SubscriptionStatus: Equatable {
        case free
        case trial(daysRemaining: Int)
        case active(plan: SubscriptionPlan, renewalDate: Date)
        case expired
    }

    public enum SubscriptionPlan: String, CaseIterable {
        case yearly = "us.ascendapp.yearly"
        case monthly = "us.ascendapp.monthly"

        public var displayName: String {
            switch self {
            case .yearly: "Yearly"
            case .monthly: "Monthly"
            }
        }

        public var price: String {
            switch self {
            case .yearly: "$29.99/year"
            case .monthly: "$9.99/month"
            }
        }
    }

    public private(set) var status: SubscriptionStatus = .free
    public private(set) var products: [Product] = []
    public private(set) var purchaseError: String?

    public var isPremium: Bool {
        switch status {
        case .active, .trial: true
        case .free, .expired: false
        }
    }

    /// Live StoreKit product for yearly plan
    public var yearlyProduct: Product? {
        products.first { $0.id == SubscriptionPlan.yearly.rawValue }
    }

    /// Live StoreKit product for monthly plan
    public var monthlyProduct: Product? {
        products.first { $0.id == SubscriptionPlan.monthly.rawValue }
    }

    private var transactionListener: Task<Void, Never>?

    private init() {
        // Listen for transaction updates (renewals, revocations, etc.)
        transactionListener = Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.refreshStatus()
                }
            }
        }

        // Load products and status on init
        Task {
            await loadProducts()
            await refreshStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products from App Store / StoreKit Config

    @MainActor
    public func loadProducts() async {
        do {
            let productIDs = SubscriptionPlan.allCases.map(\.rawValue)
            let storeProducts = try await Product.products(for: Set(productIDs))
            products = storeProducts.sorted { $0.price > $1.price } // yearly first
        } catch {
            purchaseError = "Failed to load products: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchase

    @MainActor
    public func purchase(plan: SubscriptionPlan) async -> Bool {
        purchaseError = nil

        // Try to use live StoreKit product first
        if let product = products.first(where: { $0.id == plan.rawValue }) {
            return await purchaseProduct(product)
        }

        // Fallback: try loading products then purchasing
        await loadProducts()
        if let product = products.first(where: { $0.id == plan.rawValue }) {
            return await purchaseProduct(product)
        }

        // Product not found — do not grant access
        status = .expired
        return false
    }

    @MainActor
    private func purchaseProduct(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await refreshStatus()
                    return true
                case .unverified(_, let error):
                    purchaseError = "Verification failed: \(error.localizedDescription)"
                    return false
                }
            case .userCancelled:
                return false
            case .pending:
                purchaseError = "Purchase is pending approval."
                return false
            @unknown default:
                return false
            }
        } catch {
            purchaseError = "Purchase failed: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Restore

    @MainActor
    public func restorePurchases() async -> Bool {
        do {
            try await AppStore.sync()
            await refreshStatus()
            return isPremium
        } catch {
            purchaseError = "Restore failed: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - Refresh Status

    @MainActor
    public func refreshStatus() async {
        var foundActive = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if transaction.revocationDate == nil,
               let expirationDate = transaction.expirationDate,
               expirationDate > Date() {

                let plan = SubscriptionPlan(rawValue: transaction.productID) ?? .yearly

                // Check if in trial (introductory offer)
                if let offerType = transaction.offerType, offerType == .introductory {
                    let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
                    status = .trial(daysRemaining: max(daysRemaining, 0))
                } else {
                    status = .active(plan: plan, renewalDate: expirationDate)
                }
                foundActive = true
                break
            }
        }

        if !foundActive {
            status = .free
        }
    }

    // MARK: - Manage Subscription

    public func openManageSubscription() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
}
