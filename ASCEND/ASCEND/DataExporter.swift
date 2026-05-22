import Foundation
import Persistence

/// Gathers all user data from Persistence and exports it as a pretty-printed JSON file.
struct DataExporter {

    /// Exported data structure matching the user's stored information.
    struct ExportPayload: Codable {
        let exportDate: String
        let appVersion: String
        let profile: ProfileData?
        let scans: [ScanData]
    }

    struct ProfileData: Codable {
        let id: String
        let displayName: String
        let gender: String
        let age: Int
        let heightCm: Int
        let weightKg: Double
        let goalWeightKg: Double
        let bodyConcerns: String
        let trainingFrequency: String
        let timeline: String
        let scanDay: String
        let restDay: String
        let notificationHour: Int
        let createdAt: String
    }

    struct ScanData: Codable {
        let id: String
        let date: String
        let overallScore: Double
        let irisMessage: String
        let hasFrontImage: Bool
        let hasSideImage: Bool
        let hasBackImage: Bool
    }

    // MARK: - Export

    /// Gathers all user data and writes a JSON file to a temporary directory.
    /// Returns the file URL suitable for sharing via ShareLink / UIActivityViewController.
    @MainActor
    static func exportJSON() throws -> URL {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]

        // Fetch profile
        let userProfile = try DataStore.shared.fetchProfile()
        let profileData: ProfileData? = userProfile.map { p in
            ProfileData(
                id: p.id.uuidString,
                displayName: p.displayName,
                gender: p.gender,
                age: p.age,
                heightCm: p.heightCm,
                weightKg: p.weightKg,
                goalWeightKg: p.goalWeightKg,
                bodyConcerns: p.bodyConcerns,
                trainingFrequency: p.trainingFrequency,
                timeline: p.timeline,
                scanDay: p.scanDay,
                restDay: p.restDay,
                notificationHour: p.notificationHour,
                createdAt: iso.string(from: p.createdAt)
            )
        }

        // Fetch scans
        let scanRecords = try DataStore.shared.fetchScans()
        let scansData: [ScanData] = scanRecords.map { s in
            ScanData(
                id: s.id.uuidString,
                date: iso.string(from: s.date),
                overallScore: s.overallScore,
                irisMessage: s.irisMessage,
                hasFrontImage: s.frontImageData != nil,
                hasSideImage: s.sideImageData != nil,
                hasBackImage: s.backImageData != nil
            )
        }

        let payload = ExportPayload(
            exportDate: iso.string(from: Date()),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            profile: profileData,
            scans: scansData
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(payload)

        // Write to temp file
        let fileName = "ASCEND_Export_\(dateStamp()).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: tempURL, options: .atomic)
        return tempURL
    }

    private static func dateStamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd_HHmmss"
        return f.string(from: Date())
    }
}
