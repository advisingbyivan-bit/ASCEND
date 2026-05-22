import Foundation
import SwiftData

@Model
public final class UserProfile {
    public var id: UUID
    public var displayName: String
    public var gender: String // "male" or "female"
    public var age: Int
    public var heightCm: Int
    public var weightKg: Double
    public var goalWeightKg: Double
    public var bodyConcerns: String // comma-separated zones
    public var trainingFrequency: String
    public var timeline: String
    public var scanDay: String
    public var restDay: String
    public var notificationHour: Int
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        displayName: String = "",
        gender: String = "male",
        age: Int = 25,
        heightCm: Int = 175,
        weightKg: Double = 75,
        goalWeightKg: Double = 72,
        bodyConcerns: String = "",
        trainingFrequency: String = "moderate",
        timeline: String = "12 Weeks",
        scanDay: String = "Sunday",
        restDay: String = "Wednesday",
        notificationHour: Int = 8,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.gender = gender
        self.age = age
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.goalWeightKg = goalWeightKg
        self.bodyConcerns = bodyConcerns
        self.trainingFrequency = trainingFrequency
        self.timeline = timeline
        self.scanDay = scanDay
        self.restDay = restDay
        self.notificationHour = notificationHour
        self.createdAt = createdAt
    }
}
