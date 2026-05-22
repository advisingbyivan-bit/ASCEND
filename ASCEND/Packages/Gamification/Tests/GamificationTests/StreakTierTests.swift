import XCTest
@testable import Gamification

final class StreakTierTests: XCTestCase {

    func testStreakZero_returnsNone() {
        XCTAssertEqual(StreakTier.from(0), .none)
    }

    func testStreakOne_returnsBronze() {
        XCTAssertEqual(StreakTier.from(1), .bronze)
    }

    func testStreakSeven_returnsBronze() {
        XCTAssertEqual(StreakTier.from(7), .bronze)
    }

    func testStreakEight_returnsSilver() {
        XCTAssertEqual(StreakTier.from(8), .silver)
    }

    func testStreakTwentyOne_returnsSilver() {
        XCTAssertEqual(StreakTier.from(21), .silver)
    }

    func testStreakTwentyTwo_returnsGold() {
        XCTAssertEqual(StreakTier.from(22), .gold)
    }

    func testStreakOneHundred_returnsGold() {
        XCTAssertEqual(StreakTier.from(100), .gold)
    }

    func testBronzeRange_allReturnBronze() {
        for streak in 1...7 {
            XCTAssertEqual(StreakTier.from(streak), .bronze, "Streak \(streak) should be bronze")
        }
    }

    func testSilverRange_allReturnSilver() {
        for streak in 8...21 {
            XCTAssertEqual(StreakTier.from(streak), .silver, "Streak \(streak) should be silver")
        }
    }

    func testGoldRange_severalValues() {
        for streak in [22, 50, 100, 365, 1000] {
            XCTAssertEqual(StreakTier.from(streak), .gold, "Streak \(streak) should be gold")
        }
    }
}
