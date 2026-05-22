import XCTest
import SwiftData
@testable import Persistence

final class PersistenceTests: XCTestCase {

    private var container: ModelContainer!

    override func setUp() {
        super.setUp()
        do {
            let schema = Schema([ScanRecord.self, UserProfile.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            XCTFail("Failed to create in-memory ModelContainer: \(error)")
        }
    }

    override func tearDown() {
        container = nil
        super.tearDown()
    }

    // MARK: - ScanRecord creation

    func testScanRecord_defaultInit() {
        let record = ScanRecord()
        XCTAssertNotNil(record.id)
        XCTAssertNotNil(record.date)
        XCTAssertNil(record.frontImageData)
        XCTAssertNil(record.sideImageData)
        XCTAssertNil(record.backImageData)
        XCTAssertEqual(record.overallScore, 0)
        XCTAssertEqual(record.irisMessage, "")
        XCTAssertNil(record.zoneData)
    }

    func testScanRecord_customInit() {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1000)
        let frontData = Data([0x01, 0x02, 0x03])
        let sideData = Data([0x04, 0x05])
        let backData = Data([0x06])
        let zoneJSON = "{\"chest\":8.5}".data(using: .utf8)

        let record = ScanRecord(
            id: id,
            date: date,
            frontImageData: frontData,
            sideImageData: sideData,
            backImageData: backData,
            overallScore: 85.5,
            irisMessage: "Looking strong!",
            zoneData: zoneJSON
        )

        XCTAssertEqual(record.id, id)
        XCTAssertEqual(record.date, date)
        XCTAssertEqual(record.frontImageData, frontData)
        XCTAssertEqual(record.sideImageData, sideData)
        XCTAssertEqual(record.backImageData, backData)
        XCTAssertEqual(record.overallScore, 85.5)
        XCTAssertEqual(record.irisMessage, "Looking strong!")
        XCTAssertEqual(record.zoneData, zoneJSON)
    }

    func testScanRecord_uniqueIds() {
        let record1 = ScanRecord()
        let record2 = ScanRecord()
        XCTAssertNotEqual(record1.id, record2.id)
    }

    // MARK: - UserProfile creation

    func testUserProfile_defaultInit() {
        let profile = UserProfile()
        XCTAssertNotNil(profile.id)
        XCTAssertEqual(profile.displayName, "")
        XCTAssertEqual(profile.gender, "male")
        XCTAssertEqual(profile.age, 25)
        XCTAssertEqual(profile.heightCm, 175)
        XCTAssertEqual(profile.weightKg, 75)
        XCTAssertEqual(profile.goalWeightKg, 72)
        XCTAssertEqual(profile.bodyConcerns, "")
        XCTAssertEqual(profile.trainingFrequency, "moderate")
        XCTAssertEqual(profile.timeline, "12 Weeks")
        XCTAssertEqual(profile.scanDay, "Sunday")
        XCTAssertEqual(profile.restDay, "Wednesday")
        XCTAssertEqual(profile.notificationHour, 8)
        XCTAssertNotNil(profile.createdAt)
    }

    func testUserProfile_customInit() {
        let id = UUID()
        let createdAt = Date(timeIntervalSince1970: 5000)

        let profile = UserProfile(
            id: id,
            displayName: "John",
            gender: "female",
            age: 30,
            heightCm: 165,
            weightKg: 60,
            goalWeightKg: 55,
            bodyConcerns: "arms,chest",
            trainingFrequency: "high",
            timeline: "8 Weeks",
            scanDay: "Monday",
            restDay: "Friday",
            notificationHour: 10,
            createdAt: createdAt
        )

        XCTAssertEqual(profile.id, id)
        XCTAssertEqual(profile.displayName, "John")
        XCTAssertEqual(profile.gender, "female")
        XCTAssertEqual(profile.age, 30)
        XCTAssertEqual(profile.heightCm, 165)
        XCTAssertEqual(profile.weightKg, 60)
        XCTAssertEqual(profile.goalWeightKg, 55)
        XCTAssertEqual(profile.bodyConcerns, "arms,chest")
        XCTAssertEqual(profile.trainingFrequency, "high")
        XCTAssertEqual(profile.timeline, "8 Weeks")
        XCTAssertEqual(profile.scanDay, "Monday")
        XCTAssertEqual(profile.restDay, "Friday")
        XCTAssertEqual(profile.notificationHour, 10)
        XCTAssertEqual(profile.createdAt, createdAt)
    }

    func testUserProfile_uniqueIds() {
        let profile1 = UserProfile()
        let profile2 = UserProfile()
        XCTAssertNotEqual(profile1.id, profile2.id)
    }

    // MARK: - ZoneData JSON round-trip

    func testScanRecord_zoneData_storesAndRetrievesJSON() {
        let zoneInfo: [String: Double] = [
            "chest": 8.5,
            "arms": 7.0,
            "legs": 9.2,
            "back": 6.8
        ]

        let jsonData = try! JSONEncoder().encode(zoneInfo)
        let record = ScanRecord(zoneData: jsonData)

        XCTAssertNotNil(record.zoneData)

        let decoded = try! JSONDecoder().decode([String: Double].self, from: record.zoneData!)
        XCTAssertEqual(decoded["chest"], 8.5)
        XCTAssertEqual(decoded["arms"], 7.0)
        XCTAssertEqual(decoded["legs"], 9.2)
        XCTAssertEqual(decoded["back"], 6.8)
    }

    func testScanRecord_zoneData_nilByDefault() {
        let record = ScanRecord()
        XCTAssertNil(record.zoneData)
    }

    // MARK: - ScanRecord field mutation

    func testScanRecord_fieldsAreMutable() {
        let record = ScanRecord()
        record.overallScore = 95.0
        record.irisMessage = "Updated message"
        XCTAssertEqual(record.overallScore, 95.0)
        XCTAssertEqual(record.irisMessage, "Updated message")
    }

    // MARK: - UserProfile field mutation

    func testUserProfile_fieldsAreMutable() {
        let profile = UserProfile()
        profile.displayName = "Updated Name"
        profile.weightKg = 80.0
        profile.goalWeightKg = 75.0
        XCTAssertEqual(profile.displayName, "Updated Name")
        XCTAssertEqual(profile.weightKg, 80.0)
        XCTAssertEqual(profile.goalWeightKg, 75.0)
    }

    // MARK: - ModelContainer integration

    @MainActor
    func testScanRecord_insertAndFetch() throws {
        let context = container.mainContext
        let record = ScanRecord(overallScore: 77.3, irisMessage: "Test scan")
        context.insert(record)
        try context.save()

        let descriptor = FetchDescriptor<ScanRecord>()
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.overallScore, 77.3)
        XCTAssertEqual(fetched.first?.irisMessage, "Test scan")
    }

    @MainActor
    func testUserProfile_insertAndFetch() throws {
        let context = container.mainContext
        let profile = UserProfile(displayName: "Test User", age: 28)
        context.insert(profile)
        try context.save()

        let descriptor = FetchDescriptor<UserProfile>()
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.displayName, "Test User")
        XCTAssertEqual(fetched.first?.age, 28)
    }

    @MainActor
    func testMultipleScanRecords_insertAndFetch() throws {
        let context = container.mainContext
        let record1 = ScanRecord(overallScore: 60.0, irisMessage: "First")
        let record2 = ScanRecord(overallScore: 80.0, irisMessage: "Second")
        context.insert(record1)
        context.insert(record2)
        try context.save()

        let descriptor = FetchDescriptor<ScanRecord>()
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 2)
    }
}
