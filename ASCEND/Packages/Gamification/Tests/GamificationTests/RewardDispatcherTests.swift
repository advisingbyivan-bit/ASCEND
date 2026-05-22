import XCTest
@testable import Gamification

final class RewardDispatcherTests: XCTestCase {

    // MARK: - Milestone present

    func testEvaluate_withDay7Milestone_returnsMega() {
        let reward = RewardDispatcher.evaluate(streak: 7, milestone: .day7)
        XCTAssertEqual(reward, .mega(.day7))
    }

    func testEvaluate_withDay21Milestone_returnsMega() {
        let reward = RewardDispatcher.evaluate(streak: 21, milestone: .day21)
        XCTAssertEqual(reward, .mega(.day21))
    }

    func testEvaluate_withDay42Milestone_returnsMega() {
        let reward = RewardDispatcher.evaluate(streak: 42, milestone: .day42)
        XCTAssertEqual(reward, .mega(.day42))
    }

    func testEvaluate_withDay90Milestone_returnsMega() {
        let reward = RewardDispatcher.evaluate(streak: 90, milestone: .day90)
        XCTAssertEqual(reward, .mega(.day90))
    }

    func testEvaluate_withDay365Milestone_returnsMega() {
        let reward = RewardDispatcher.evaluate(streak: 365, milestone: .day365)
        XCTAssertEqual(reward, .mega(.day365))
    }

    func testEvaluate_allMilestones_alwaysReturnMega() {
        for milestone in DiamondMilestone.allCases {
            for _ in 0..<10 {
                let reward = RewardDispatcher.evaluate(streak: milestone.rawValue, milestone: milestone)
                XCTAssertEqual(reward, .mega(milestone),
                               "Milestone \(milestone) should always produce .mega")
            }
        }
    }

    // MARK: - No milestone (random distribution)

    func testEvaluate_withoutMilestone_returnsStandardOrBonus() {
        for _ in 0..<100 {
            let reward = RewardDispatcher.evaluate(streak: 5, milestone: nil)
            XCTAssertTrue(reward == .standard || reward == .bonus,
                          "Without milestone, reward should be .standard or .bonus, got \(reward)")
        }
    }

    func testEvaluate_withoutMilestone_neverReturnsAlreadyScanned() {
        for _ in 0..<200 {
            let reward = RewardDispatcher.evaluate(streak: 1, milestone: nil)
            XCTAssertNotEqual(reward, .alreadyScanned,
                              "RewardDispatcher should never return .alreadyScanned")
        }
    }

    func testEvaluate_withoutMilestone_neverReturnsMega() {
        for _ in 0..<200 {
            let reward = RewardDispatcher.evaluate(streak: 10, milestone: nil)
            if case .mega = reward {
                XCTFail("Without milestone, reward should never be .mega")
            }
        }
    }

    func testEvaluate_distributionIsReasonable() {
        var standardCount = 0
        var bonusCount = 0
        let iterations = 1000

        for _ in 0..<iterations {
            let reward = RewardDispatcher.evaluate(streak: 3, milestone: nil)
            switch reward {
            case .standard: standardCount += 1
            case .bonus: bonusCount += 1
            default: XCTFail("Unexpected reward: \(reward)")
            }
        }

        // Expected: ~70% standard, ~30% bonus
        // Allow generous tolerance for randomness: standard should be 50-90%
        let standardPct = Double(standardCount) / Double(iterations)
        XCTAssertGreaterThan(standardPct, 0.50, "Standard rewards should be at least 50% (got \(standardPct))")
        XCTAssertLessThan(standardPct, 0.90, "Standard rewards should be less than 90% (got \(standardPct))")

        let bonusPct = Double(bonusCount) / Double(iterations)
        XCTAssertGreaterThan(bonusPct, 0.10, "Bonus rewards should be at least 10% (got \(bonusPct))")
        XCTAssertLessThan(bonusPct, 0.50, "Bonus rewards should be less than 50% (got \(bonusPct))")
    }
}
