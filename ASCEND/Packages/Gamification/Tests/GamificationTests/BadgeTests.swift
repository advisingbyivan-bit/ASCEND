import XCTest
@testable import Gamification

final class BadgeTests: XCTestCase {

    // MARK: - Total count

    func testAllBadges_totalCountIsTen() {
        let badges = Badge.allBadges(streak: 0, totalScans: 0)
        XCTAssertEqual(badges.count, 10)
    }

    // MARK: - Unique IDs

    func testAllBadges_idsAreUnique() {
        let badges = Badge.allBadges(streak: 0, totalScans: 0)
        let ids = badges.map(\.id)
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "Badge IDs should be unique")
    }

    // MARK: - No streak, no scans

    func testAllBadges_zeroStreakZeroScans_noBadgesEarned() {
        let badges = Badge.allBadges(streak: 0, totalScans: 0)
        let earned = badges.filter(\.isEarned)
        XCTAssertTrue(earned.isEmpty, "With streak=0 and scans=0, no badges should be earned")
    }

    // MARK: - Streak 7, scans 1

    func testAllBadges_streak7Scans1_sevenDayAndFirstScanEarned() {
        let badges = Badge.allBadges(streak: 7, totalScans: 1)
        let earned = badges.filter(\.isEarned)
        let earnedIds = Set(earned.map(\.id))

        XCTAssertTrue(earnedIds.contains("streak_7"), "7-Day Streak should be earned")
        XCTAssertTrue(earnedIds.contains("first_scan"), "First Scan should be earned")
        XCTAssertEqual(earned.count, 2, "Exactly 2 badges should be earned with streak=7, scans=1")
    }

    // MARK: - Streak 30, scans 10

    func testAllBadges_streak30Scans10_multipleEarned() {
        let badges = Badge.allBadges(streak: 30, totalScans: 10)
        let earned = badges.filter(\.isEarned)
        let earnedIds = Set(earned.map(\.id))

        XCTAssertTrue(earnedIds.contains("streak_7"), "7-Day Streak should be earned")
        XCTAssertTrue(earnedIds.contains("iris_trusted_30"), "IRIS Trusted should be earned at streak 30")
        XCTAssertTrue(earnedIds.contains("first_scan"), "First Scan should be earned")
        XCTAssertTrue(earnedIds.contains("goal_crusher"), "Goal Crusher should be earned at 10 scans")
        XCTAssertTrue(earnedIds.contains("scanner_10"), "Dedicated Scanner should be earned at 10 scans")

        XCTAssertFalse(earnedIds.contains("iris_trusted_90"), "IRIS Veteran should not be earned at streak 30")
        XCTAssertFalse(earnedIds.contains("iris_trusted_365"), "IRIS Legend should not be earned at streak 30")
    }

    // MARK: - Streak 365, scans 0

    func testAllBadges_streak365Scans0_allStreakBadgesEarned() {
        let badges = Badge.allBadges(streak: 365, totalScans: 0)
        let earned = badges.filter(\.isEarned)
        let earnedIds = Set(earned.map(\.id))

        XCTAssertTrue(earnedIds.contains("streak_7"), "7-Day Streak should be earned")
        XCTAssertTrue(earnedIds.contains("iris_trusted_30"), "IRIS Trusted should be earned")
        XCTAssertTrue(earnedIds.contains("iris_trusted_90"), "IRIS Veteran should be earned")
        XCTAssertTrue(earnedIds.contains("iris_trusted_365"), "IRIS Legend should be earned")

        // Scan-based badges should NOT be earned with 0 scans
        XCTAssertFalse(earnedIds.contains("first_scan"), "First Scan should not be earned with 0 scans")
        XCTAssertFalse(earnedIds.contains("goal_crusher"), "Goal Crusher should not be earned with 0 scans")
        XCTAssertFalse(earnedIds.contains("scanner_10"), "Dedicated Scanner should not be earned with 0 scans")
    }

    // MARK: - Always-false badges

    func testAllBadges_alwaysFalseBadges_neverEarned() {
        // These badges have isEarned hardcoded to false
        let alwaysFalseIds: Set<String> = ["rising_challenger", "accountability", "champion"]

        // Test with very high values — they should still be false
        let badges = Badge.allBadges(streak: 9999, totalScans: 9999)
        for badge in badges where alwaysFalseIds.contains(badge.id) {
            XCTAssertFalse(badge.isEarned, "\(badge.id) should always be unearned (placeholder)")
        }
    }

    // MARK: - Badge properties

    func testAllBadges_allHaveNonEmptyProperties() {
        let badges = Badge.allBadges(streak: 0, totalScans: 0)
        for badge in badges {
            XCTAssertFalse(badge.id.isEmpty, "Badge id should not be empty")
            XCTAssertFalse(badge.name.isEmpty, "Badge name should not be empty")
            XCTAssertFalse(badge.icon.isEmpty, "Badge icon should not be empty")
            XCTAssertFalse(badge.requirement.isEmpty, "Badge requirement should not be empty")
        }
    }

    // MARK: - Specific badge names

    func testAllBadges_containsExpectedBadgeNames() {
        let badges = Badge.allBadges(streak: 0, totalScans: 0)
        let names = Set(badges.map(\.name))

        XCTAssertTrue(names.contains("7-Day Streak"))
        XCTAssertTrue(names.contains("IRIS Trusted"))
        XCTAssertTrue(names.contains("IRIS Veteran"))
        XCTAssertTrue(names.contains("IRIS Legend"))
        XCTAssertTrue(names.contains("Goal Crusher"))
        XCTAssertTrue(names.contains("First Scan"))
        XCTAssertTrue(names.contains("Dedicated Scanner"))
    }

    // MARK: - Equatable conformance

    func testBadge_equatable() {
        let badge1 = Badge(id: "test", name: "Test", icon: "star", requirement: "Do something", isEarned: true)
        let badge2 = Badge(id: "test", name: "Test", icon: "star", requirement: "Do something", isEarned: true)
        XCTAssertEqual(badge1, badge2)
    }

    func testBadge_notEqual_differentEarned() {
        let badge1 = Badge(id: "test", name: "Test", icon: "star", requirement: "Do something", isEarned: true)
        let badge2 = Badge(id: "test", name: "Test", icon: "star", requirement: "Do something", isEarned: false)
        XCTAssertNotEqual(badge1, badge2)
    }
}
