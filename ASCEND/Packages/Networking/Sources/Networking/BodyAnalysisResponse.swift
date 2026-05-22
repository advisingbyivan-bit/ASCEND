import Foundation

public struct ZoneAnalysis: Codable, Sendable {
    public let zone: String
    public let status: String
    public let delta: Double?
    public let note: String?

    public init(zone: String, status: String, delta: Double? = nil, note: String? = nil) {
        self.zone = zone
        self.status = status
        self.delta = delta
        self.note = note
    }
}

public struct BodyAnalysisResponse: Codable, Sendable {
    public let zones: [ZoneAnalysis]
    public let overallScore: Double
    public let irisMessage: String

    public init(zones: [ZoneAnalysis], overallScore: Double, irisMessage: String) {
        self.zones = zones
        self.overallScore = overallScore
        self.irisMessage = irisMessage
    }
}
