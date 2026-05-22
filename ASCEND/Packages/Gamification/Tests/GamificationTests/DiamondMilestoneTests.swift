import XCTest
@testable import Gamification

final class DiamondMilestoneTests: XCTestCase {

    // MARK: - check(streak:)

    func testCheck_day7() {
        XCTAssertEqual(DiamondMilestone.check(streak: 7), .day7)
    }

    func testCheck_day21() {
        XCTAssertEqual(DiamondMilestone.check(streak: 21), .day21)
    }

    func testCheck_day42() {
        XCTAssertEqual(DiamondMilestone.check(streak: 42), .day42)
    }

    func testCheck_day90() {
        XCTAssertEqual(DiamondMilestone.check(streak: 90), .day90)
    }

    func testCheck_day365() {
        XCTAssertEqual(DiamondMilestone.check(streak: 365), .day365)
    }

    func testCheck_nonMilestoneStreak_returnsNil() {
        let nonMilestones = [0, 1, 5, 6, 8, 10, 20, 22, 41, 43, 89, 91, 100, 200, 364, 366]
        for streak in nonMilestones {
            XCTAssertNil(DiamondMilestone.check(streak: streak), "Streak \(streak) should not be a milestone")
        }
    }

    // MARK: - earned(forStreak:)

    func testEarned_streakZero_isEmpty() {
        let earned = DiamondMilestone.earned(forStreak: 0)
        XCTAssertTrue(earned.isEmpty)
    }

    func testEarned_streak7_containsDay7Only() {
        let earned = DiamondMilestone.earned(forStreak: 7)
        XCTAssertEqual(earned, [.day7])
    }

    func testEarned_streak21_containsDay7AndDay21() {
        let earned = DiamondMilestone.earned(forStreak: 21)
        XCTAssertEqual(earned, [.day7, .day21])
    }

    func testEarned_streak50_containsThreeMilestones() {
        let earned = DiamondMilestone.earned(forStreak: 50)
        XCTAssertEqual(earned, [.day7, .day21, .day42])
    }

    func testEarned_streak90_containsFourMilestones() {
        let earned = DiamondMilestone.earned(forStreak: 90)
        XCTAssertEqual(earned, [.day7, .day21, .day42, .day90])
    }

    func testEarned_streak365_containsAllMilestones() {
        let earned = DiamondMilestone.earned(forStreak: 365)
        XCTAssertEqual(earned.count, 5)
        XCTAssertEqual(earned, DiamondMilestone.allCases)
    }

    func testEarned_streak1000_containsAllMilestones() {
        let earned = DiamondMilestone.earned(forStreak: 1000)
        XCTAssertEqual(earned.count, 5)
    }

    // MARK: - next(forStreak:)

    func testNext_streak0_returnsDay7() {
        XCTAssertEqual(DiamondMilestone.next(forStreak: 0), .day7)
    }

    func testNext_streak6_returnsDay7() {
        XCTAssertEqual(DiamondMilestone.next(forStreak: 6), .day7)
    }

    func testNext_streak7_returnsDay21() {
        XCTAssertEqual(DiamondMilestone.next(forStreak: 7), .day21)
    }

    func testNext_streak21_returnsDay42() {
        XCTAssertEqual(DiamondMilestone.next(forStreak: 21), .day42)
    }

    func testNext_streak42_returnsDay90() {
        XCTAssertEqual(DiamondMilestone.next(forStreak: 42), .day90)
    }

    func testNext_streak90_returnsDay365() {
        XCTAssertEqual(DiamondMilestone.next(forStreak: 90), .day365)
    }

    func testNext_streak365_returnsNil() {
        XCTAssertNil(DiamondMilestone.next(forStreak: 365))
    }

    func testNext_streak1000_returnsNil() {
        XCTAssertNil(DiamondMilestone.next(forStreak: 1000))
    }

    // MARK: - displayName and description

    func testDisplayName_nonEmpty() {
        for milestone in DiamondMilestone.allCases {
            XCTAssertFalse(milestone.displayName.isEmpty, "\(milestone) displayName should not be empty")
        }
    }

    func testDisplayName_containsDayPrefix() {
        for milestone in DiamondMilestone.allCases {
            XCTAssertTrue(milestone.displayName.hasPrefix("Day "), "\(milestone) displayName should start with 'Day '")
        }
    }

    func testDisplayName_containsRawValue() {
        for milestone in DiamondMilestone.allCases {
            XCTAssertTrue(milestone.displayName.contains("\(milestone.rawValue)"),
                          "\(milestone) displayName should contain raw value")
        }
    }

    func testDescription_nonEmpty() {
        for milestone in DiamondMilestone.allCases {
            XCTAssertFalse(milestone.description.isEmpty, "\(milestone) description should not be empty")
        }
    }

    func testDescription_specificValues() {
        XCTAssertEqual(DiamondMilestone.day7.description, "First Week Warrior")
        XCTAssertEqual(DiamondMilestone.day21.description, "Habit Formed")
        XCTAssertEqual(DiamondMilestone.day42.description, "Unstoppable")
        XCTAssertEqual(DiamondMilestone.day90.description, "Quarterly Crusher")
        XCTAssertEqual(DiamondMilestone.day365.description, "Year of Iron")
    }

    // MARK: - Identifiable

    func testId_equalsRawValue() {
        for milestone in DiamondMilestone.allCases {
            XCTAssertEqual(milestone.id, milestone.rawValue)
        }
    }

    // MARK: - CaseIterable

    func testAllCases_hasFiveEntries() {
        XCTAssertEqual(DiamondMilestone.allCases.count, 5)
    }
}
