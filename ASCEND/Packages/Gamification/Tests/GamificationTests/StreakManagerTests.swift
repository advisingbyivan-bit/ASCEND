import XCTest
@testable import Gamification

final class StreakManagerTests: XCTestCase {

    private let streakKey = "ascend_streak"
    private let longestStreakKey = "ascend_longest_streak"
    private let diamondsKey = "ascend_diamonds"
    private let lastScanKey = "ascend_last_scan"

    override func setUp() {
        super.setUp()
        // Clean UserDefaults state before each test.
        // Note: StreakManager.shared reads from UserDefaults in its private init,
        // which only runs once (singleton). We must also reset the in-memory properties
        // by writing to UserDefaults and forcing a re-read where possible.
        // Since StreakManager properties have didSet that writes TO UserDefaults but
        // reads happen only in init, we clean UserDefaults and rely on recordScan()
        // behavior to produce deterministic results when lastScanDate is nil.
        UserDefaults.standard.set(0, forKey: streakKey)
        UserDefaults.standard.set(0, forKey: longestStreakKey)
        UserDefaults.standard.set(0, forKey: diamondsKey)
        UserDefaults.standard.removeObject(forKey: lastScanKey)
        UserDefaults.standard.synchronize()
    }

    override func tearDown() {
        // Clean up after tests
        UserDefaults.standard.removeObject(forKey: streakKey)
        UserDefaults.standard.removeObject(forKey: longestStreakKey)
        UserDefaults.standard.removeObject(forKey: diamondsKey)
        UserDefaults.standard.removeObject(forKey: lastScanKey)
        UserDefaults.standard.synchronize()
        super.tearDown()
    }

    // MARK: - Initial State (UserDefaults cleaned)

    func testShared_isNotNil() {
        XCTAssertNotNil(StreakManager.shared)
    }

    func testCleanState_currentStreakFromUserDefaults() {
        // After cleaning UserDefaults, the persisted value is 0
        let stored = UserDefaults.standard.integer(forKey: streakKey)
        XCTAssertEqual(stored, 0)
    }

    // MARK: - recordScan()

    func testRecordScan_firstCall_returnsNonAlreadyScanned() {
        // When lastScanDate is nil (cleaned in setUp), first call should not be .alreadyScanned
        let manager = StreakManager.shared
        let reward = manager.recordScan()
        XCTAssertNotEqual(reward, .alreadyScanned,
                          "First recordScan after clean state should not return .alreadyScanned")
    }

    func testRecordScan_setsCurrentStreakToAtLeastOne() {
        let manager = StreakManager.shared
        _ = manager.recordScan()
        XCTAssertGreaterThanOrEqual(manager.currentStreak, 1,
                                     "After recordScan, currentStreak should be at least 1")
    }

    func testRecordScan_twiceImmediately_secondReturnsAlreadyScanned() {
        let manager = StreakManager.shared
        let first = manager.recordScan()
        XCTAssertNotEqual(first, .alreadyScanned)

        let second = manager.recordScan()
        XCTAssertEqual(second, .alreadyScanned,
                       "Second recordScan on the same day should return .alreadyScanned")
    }

    // MARK: - Longest streak

    func testLongestStreak_greaterThanOrEqualToCurrentStreak() {
        let manager = StreakManager.shared
        _ = manager.recordScan()
        XCTAssertGreaterThanOrEqual(manager.longestStreak, manager.currentStreak,
                                     "longestStreak should always be >= currentStreak")
    }

    // MARK: - streakTier

    func testStreakTier_matchesCurrentStreak() {
        let manager = StreakManager.shared
        _ = manager.recordScan()
        let expected = StreakTier.from(manager.currentStreak)
        XCTAssertEqual(manager.streakTier, expected,
                       "streakTier should match StreakTier.from(currentStreak)")
    }

    // MARK: - UserDefaults persistence

    func testRecordScan_persistsStreakToUserDefaults() {
        let manager = StreakManager.shared
        _ = manager.recordScan()
        let stored = UserDefaults.standard.integer(forKey: streakKey)
        XCTAssertEqual(stored, manager.currentStreak,
                       "UserDefaults streak should match manager's currentStreak")
    }

    func testRecordScan_persistsLongestStreakToUserDefaults() {
        let manager = StreakManager.shared
        _ = manager.recordScan()
        let stored = UserDefaults.standard.integer(forKey: longestStreakKey)
        XCTAssertEqual(stored, manager.longestStreak,
                       "UserDefaults longest streak should match manager's longestStreak")
    }

    func testRecordScan_persistsLastScanDateToUserDefaults() {
        let manager = StreakManager.shared
        _ = manager.recordScan()
        let storedTimestamp = UserDefaults.standard.double(forKey: lastScanKey)
        XCTAssertGreaterThan(storedTimestamp, 0,
                             "lastScanDate should be persisted as a nonzero timestamp")
    }

    // MARK: - ScanReward cases

    func testScanReward_equatable() {
        XCTAssertEqual(ScanReward.alreadyScanned, ScanReward.alreadyScanned)
        XCTAssertEqual(ScanReward.standard, ScanReward.standard)
        XCTAssertEqual(ScanReward.bonus, ScanReward.bonus)
        XCTAssertEqual(ScanReward.mega(.day7), ScanReward.mega(.day7))
        XCTAssertNotEqual(ScanReward.standard, ScanReward.bonus)
        XCTAssertNotEqual(ScanReward.mega(.day7), ScanReward.mega(.day21))
    }
}
