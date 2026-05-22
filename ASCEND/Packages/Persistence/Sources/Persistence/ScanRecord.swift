import Foundation
import SwiftData

@Model
public final class ScanRecord {
    public var id: UUID
    public var date: Date
    public var frontImageData: Data?
    public var sideImageData: Data?
    public var backImageData: Data?
    public var overallScore: Double
    public var irisMessage: String
    public var zoneData: Data? // JSON-encoded zone breakdown

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        frontImageData: Data? = nil,
        sideImageData: Data? = nil,
        backImageData: Data? = nil,
        overallScore: Double = 0,
        irisMessage: String = "",
        zoneData: Data? = nil
    ) {
        self.id = id
        self.date = date
        self.frontImageData = frontImageData
        self.sideImageData = sideImageData
        self.backImageData = backImageData
        self.overallScore = overallScore
        self.irisMessage = irisMessage
        self.zoneData = zoneData
    }
}
