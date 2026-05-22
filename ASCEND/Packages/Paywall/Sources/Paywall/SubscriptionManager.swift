import Foundation
import StoreKit
import RevenueCat

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

    /// RevenueCat packages from the default offering
    public private(set) var rcPackages: [RevenueCat.Package] = []

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

    /// RevenueCat package for yearly
    public var yearlyPackage: RevenueCat.Package? {
        rcPackages.first { $0.storeProduct.productIdentifier == SubscriptionPlan.yearly.rawValue }
    }

    /// RevenueCat package for monthly
    public var monthlyPackage: RevenueCat.Package? {
        rcPackages.first { $0.storeProduct.productIdentifier == SubscriptionPlan.monthly.rawValue }
    }

    /// Whether RevenueCat is configured (API key provided)
    public private(set) var isRevenueCatConfigured = false

    private var transactionListener: Task<Void, Never>?

    private init() {
        // Fallback: Listen for StoreKit transaction updates directly
        // (RevenueCat also does this internally, but we keep it for when RC isn't configured)
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

    // MARK: - RevenueCat Configuration

    /// Call once at app launch with your RevenueCat API key.
    /// If apiKey is empty, falls back to raw StoreKit 2.
    public func configure(apiKey: String, appUserID: String? = nil) {
        guard !apiKey.isEmpty else { return }

        Purchases.logLevel = .warn
        Purchases.configure(
            with: .init(withAPIKey: apiKey)
                .with(appUserID: appUserID)
        )

        isRevenueCatConfigured = true

        // Reload offerings and status through RevenueCat
        Task {
            await loadOfferings()
            await refreshStatus()
        }
    }

    /// Link a RevenueCat user to your backend user ID (call after auth)
    public func identify(userId: String) async {
        guard isRevenueCatConfigured else { return }
        do {
            let (customerInfo, _) = try await Purchases.shared.logIn(userId)
            await MainActor.run {
                updateStatusFromCustomerInfo(customerInfo)
            }
        } catch {
            print("[SubscriptionManager] RevenueCat identify error: \(error.localizedDescription)")
        }
    }

    // MARK: - Load Products

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

    /// Load RevenueCat offerings (packages with paywall metadata)
    @MainActor
    private func loadOfferings() async {
        guard isRevenueCatConfigured else { return }
        do {
            let offerings = try await Purchases.shared.offerings()
            if let current = offerings.current {
                rcPackages = current.availablePackages
            }
        } catch {
            print("[SubscriptionManager] Failed to load offerings: \(error.localizedDescription)")
        }
    }

    // MARK: - Purchase

    @MainActor
    public func purchase(plan: SubscriptionPlan) async -> Bool {
        purchaseError = nil

        // Prefer RevenueCat if configured
        if isRevenueCatConfigured {
            return await purchaseViaRevenueCat(plan: plan)
        }

        // Fallback to raw StoreKit 2
        return await purchaseViaStoreKit(plan: plan)
    }

    @MainActor
    private func purchaseViaRevenueCat(plan: SubscriptionPlan) async -> Bool {
        guard let package = rcPackages.first(where: {
            $0.storeProduct.productIdentifier == plan.rawValue
        }) else {
            // Package not in offerings — fall back to StoreKit
            return await purchaseViaStoreKit(plan: plan)
        }

        do {
            let (_, customerInfo, _) = try await Purchases.shared.purchase(package: package)
            updateStatusFromCustomerInfo(customerInfo)
            return isPremium
        } catch let error as RevenueCat.ErrorCode {
            if error == .purchaseCancelledError {
                return false
            }
            purchaseError = "Purchase failed: \(error.localizedDescription)"
            return false
        } catch {
            purchaseError = "Purchase failed: \(error.localizedDescription)"
            return false
        }
    }

    @MainActor
    private func purchaseViaStoreKit(plan: SubscriptionPlan) async -> Bool {
        if let product = products.first(where: { $0.id == plan.rawValue }) {
            return await purchaseProduct(product)
        }

        await loadProducts()
        if let product = products.first(where: { $0.id == plan.rawValue }) {
            return await purchaseProduct(product)
        }

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
        if isRevenueCatConfigured {
            do {
                let customerInfo = try await Purchases.shared.restorePurchases()
                updateStatusFromCustomerInfo(customerInfo)
                return isPremium
            } catch {
                purchaseError = "Restore failed: \(error.localizedDescription)"
                return false
            }
        }

        // Fallback StoreKit
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
        // Prefer RevenueCat if configured
        if isRevenueCatConfigured {
            do {
                let customerInfo = try await Purchases.shared.customerInfo()
                updateStatusFromCustomerInfo(customerInfo)
                return
            } catch {
                // Fall through to StoreKit
            }
        }

        // Raw StoreKit fallback
        var foundActive = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if transaction.revocationDate == nil,
               let expirationDate = transaction.expirationDate,
               expirationDate > Date() {

                let plan = SubscriptionPlan(rawValue: transaction.productID) ?? .yearly

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

    // MARK: - RevenueCat CustomerInfo → Status

    private func updateStatusFromCustomerInfo(_ info: CustomerInfo) {
        // Check the "pro" entitlement (configure this in RevenueCat dashboard)
        let entitlement = info.entitlements["pro"] ?? info.entitlements.active.values.first

        guard let ent = entitlement, ent.isActive else {
            status = .free
            return
        }

        // Determine plan from product ID
        let plan = SubscriptionPlan(rawValue: ent.productIdentifier) ?? .yearly

        // Check trial
        if ent.periodType == .trial {
            if let expDate = ent.expirationDate {
                let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: expDate).day ?? 0
                status = .trial(daysRemaining: max(daysRemaining, 0))
            } else {
                status = .trial(daysRemaining: 3)
            }
        } else if let expDate = ent.expirationDate {
            status = .active(plan: plan, renewalDate: expDate)
        } else {
            status = .active(plan: plan, renewalDate: Date().addingTimeInterval(30 * 86400))
        }
    }

    // MARK: - Manage Subscription

    public func openManageSubscription() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
}
