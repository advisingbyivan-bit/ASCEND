public struct Scan: Codable, Identifiable, Sendable {
    public let id: UUID
    public let userId: UUID
    public var frontImageData: Data?
    public var sideImageData: Data?
    public var backImageData: Data?
    public let createdAt: Date
    public var diagnosis: Diagnosis?

    public init(
        id: UUID = UUID(),
        userId: UUID,
        frontImageData: Data? = nil,
        sideImageData: Data? = nil,
        backImageData: Data? = nil,
        createdAt: Date = Date(),
        diagnosis: Diagnosis? = nil
    ) {
        self.id = id
        self.userId = userId
        self.frontImageData = frontImageData
        self.sideImageData = sideImageData
        self.backImageData = backImageData
        self.createdAt = createdAt
        self.diagnosis = diagnosis
    }
}
