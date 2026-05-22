public struct User: Codable, Identifiable, Sendable {
    public let id: UUID
    public var email: String
    public var displayName: String
    public var gender: Gender
    public var dateOfBirth: Date?
    public var heightCM: Double?
    public var weightKG: Double?
    public var goalWeight: Double?
    public var bodyConcerns: [String]
    public var trainingFrequency: TrainingFrequency
    public var timeline: GoalTimeline
    public var scanDay: Weekday
    public var restDay: Weekday
    public var notificationTime: Date?
    public let createdAt: Date
    public var streakDays: Int
    public var diamonds: Int
    public var currentPlan: String?

    public init(
        id: UUID = UUID(),
        email: String,
        displayName: String,
        gender: Gender,
        dateOfBirth: Date? = nil,
        heightCM: Double? = nil,
        weightKG: Double? = nil,
        goalWeight: Double? = nil,
        bodyConcerns: [String] = [],
        trainingFrequency: TrainingFrequency = .moderate,
        timeline: GoalTimeline = .weeks12,
        scanDay: Weekday = .monday,
        restDay: Weekday = .sunday,
        notificationTime: Date? = nil,
        createdAt: Date = Date(),
        streakDays: Int = 0,
        diamonds: Int = 0,
        currentPlan: String? = nil
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.gender = gender
        self.dateOfBirth = dateOfBirth
        self.heightCM = heightCM
        self.weightKG = weightKG
        self.goalWeight = goalWeight
        self.bodyConcerns = bodyConcerns
        self.trainingFrequency = trainingFrequency
        self.timeline = timeline
        self.scanDay = scanDay
        self.restDay = restDay
        self.notificationTime = notificationTime
        self.createdAt = createdAt
        self.streakDays = streakDays
        self.diamonds = diamonds
        self.currentPlan = currentPlan
    }
}
