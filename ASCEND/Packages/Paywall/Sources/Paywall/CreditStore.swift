import Foundation
import StoreKit
import Gamification

/// Handles consumable IAP purchases for scan credit packs.
/// Works alongside `SubscriptionManager` (which handles subscriptions).
@Observable
public final class CreditStore {
    public static let shared = CreditStore()

    public private(set) var products: [Product] = []
    public private(set) var purchaseError: String?
    public private(set) var isPurchasing = false

    private var transactionListener: Task<Void, Never>?

    /// Tracks transaction IDs already credited to prevent double-awarding
    /// when both the Transaction.updates listener and purchase() handle the same transaction.
    private var processedTransactionIDs: Set<UInt64> = []

    private init() {
        // Listen for consumable transaction updates
        transactionListener = Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = result {
                    // Skip if this transaction was already credited by purchase()
                    let alreadyProcessed = await MainActor.run { self.processedTransactionIDs.contains(transaction.id) }
                    guard !alreadyProcessed else {
                        await transaction.finish()
                        continue
                    }
                    // Check if it's a credit pack
                    if let pack = CreditPack(rawValue: transaction.productID) {
                        await MainActor.run {
                            self.processedTransactionIDs.insert(transaction.id)
                            ScanCreditManager.shared.addCredits(pack.creditCount, source: pack.source)
                        }
                    }
                    await transaction.finish()
                }
            }
        }

        Task {
            await loadProducts()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    @MainActor
    public func loadProducts() async {
        do {
            let productIDs = CreditPack.allCases.map(\.rawValue)
            let storeProducts = try await Product.products(for: Set(productIDs))
            // Sort by price ascending (small → medium → large)
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            purchaseError = "Failed to load credit packs: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchase

    /// Purchase a credit pack. Returns the number of credits awarded (0 on failure).
    @MainActor
    public func purchase(pack: CreditPack) async -> Int {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        // Try to find the StoreKit product
        var product = products.first { $0.id == pack.rawValue }

        if product == nil {
            await loadProducts()
            product = products.first { $0.id == pack.rawValue }
        }

        guard let storeProduct = product else {
            purchaseError = "Product not available. Please try again."
            return 0
        }

        do {
            let result = try await storeProduct.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // Mark as processed so the Transaction.updates listener skips it
                    processedTransactionIDs.insert(transaction.id)
                    // Award credits
                    ScanCreditManager.shared.addCredits(pack.creditCount, source: pack.source)
                    await transaction.finish()
                    return pack.creditCount

                case .unverified(_, let error):
                    purchaseError = "Verification failed: \(error.localizedDescription)"
                    return 0
                }

            case .userCancelled:
                return 0

            case .pending:
                purchaseError = "Purchase is pending approval."
                return 0

            @unknown default:
                return 0
            }
        } catch {
            purchaseError = "Purchase failed: \(error.localizedDescription)"
            return 0
        }
    }

    /// Get the StoreKit product for a given pack (for displaying real prices).
    public func product(for pack: CreditPack) -> Product? {
        products.first { $0.id == pack.rawValue }
    }
}
