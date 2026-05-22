public struct Diagnosis: Codable, Identifiable, Sendable {
    public let id: UUID
    public let scanId: UUID
    public var zones: [ZoneDiagnosis]
    public var overallScore: Double
    public var irisMessage: String
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        scanId: UUID,
        zones: [ZoneDiagnosis] = [],
        overallScore: Double,
        irisMessage: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.scanId = scanId
        self.zones = zones
        self.overallScore = overallScore
        self.irisMessage = irisMessage
        self.createdAt = createdAt
    }
}

public struct ZoneDiagnosis: Codable, Identifiable, Sendable {
    public var id: String { zone }
    public var zone: String
    public var status: String
    public var delta: Double?
    public var note: String?

    public init(
        zone: String,
        status: String,
        delta: Double? = nil,
        note: String? = nil
    ) {
        self.zone = zone
        self.status = status
        self.delta = delta
        self.note = note
    }
}
