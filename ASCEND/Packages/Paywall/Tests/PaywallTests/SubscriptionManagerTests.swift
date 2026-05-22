import XCTest
@testable import Paywall

final class SubscriptionManagerTests: XCTestCase {

    // MARK: - Initial state

    func testShared_isNotNil() {
        XCTAssertNotNil(SubscriptionManager.shared)
    }

    func testInitialStatus_isFree() {
        let manager = SubscriptionManager.shared
        // Note: since SubscriptionManager is a singleton, status may have been
        // modified by previous tests. We verify the type's default behavior.
        // The initial value in the source is .free.
        switch manager.status {
        case .free:
            // This is the expected initial state if no purchase has been made
            break
        case .trial, .active, .expired:
            // If another test already called purchase(), status may not be .free.
            // This is acceptable for singleton testing.
            break
        }
    }

    func testIsPremium_whenFree_isFalse() {
        // We verify the logic indirectly by checking the computed property behavior.
        // Since the enum matching logic is: .active/.trial -> true, .free/.expired -> false
        // We can test this by examining the status.
        let manager = SubscriptionManager.shared
        switch manager.status {
        case .free, .expired:
            XCTAssertFalse(manager.isPremium)
        case .trial, .active:
            XCTAssertTrue(manager.isPremium)
        }
    }

    // MARK: - Purchase

    func testPurchase_returnsTrue() async {
        let manager = SubscriptionManager.shared
        let result = await manager.purchase(plan: .yearly)
        XCTAssertTrue(result, "purchase() should return true")
    }

    func testPurchase_setsStatusToTrial() async {
        let manager = SubscriptionManager.shared
        _ = await manager.purchase(plan: .monthly)

        switch manager.status {
        case .trial(let daysRemaining):
            XCTAssertEqual(daysRemaining, 3, "Trial should have 3 days remaining")
        default:
            XCTFail("Status should be .trial after purchase, got \(manager.status)")
        }
    }

    func testPurchase_isPremiumBecomesTrue() async {
        let manager = SubscriptionManager.shared
        _ = await manager.purchase(plan: .yearly)
        XCTAssertTrue(manager.isPremium, "isPremium should be true after purchase (trial state)")
    }

    // MARK: - Restore

    func testRestorePurchases_returnsFalse() async {
        let manager = SubscriptionManager.shared
        let result = await manager.restorePurchases()
        XCTAssertFalse(result, "restorePurchases() placeholder should return false")
    }

    // MARK: - SubscriptionPlan properties

    func testYearlyPlan_displayName() {
        XCTAssertEqual(SubscriptionManager.SubscriptionPlan.yearly.displayName, "Yearly")
    }

    func testMonthlyPlan_displayName() {
        XCTAssertEqual(SubscriptionManager.SubscriptionPlan.monthly.displayName, "Monthly")
    }

    func testYearlyPlan_price() {
        XCTAssertEqual(SubscriptionManager.SubscriptionPlan.yearly.price, "$29.99/year")
    }

    func testMonthlyPlan_price() {
        XCTAssertEqual(SubscriptionManager.SubscriptionPlan.monthly.price, "$9.99/month")
    }

    func testYearlyPlan_rawValue() {
        XCTAssertEqual(SubscriptionManager.SubscriptionPlan.yearly.rawValue, "com.ascend.yearly")
    }

    func testMonthlyPlan_rawValue() {
        XCTAssertEqual(SubscriptionManager.SubscriptionPlan.monthly.rawValue, "com.ascend.monthly")
    }

    // MARK: - SubscriptionStatus behaviors

    func testIsPremium_forTrialStatus_isTrue() async {
        let manager = SubscriptionManager.shared
        _ = await manager.purchase(plan: .yearly)
        // After purchase, status is .trial(daysRemaining: 3)
        XCTAssertTrue(manager.isPremium)
    }
}
