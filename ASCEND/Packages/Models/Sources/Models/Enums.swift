public enum Gender: String, Codable, CaseIterable, Sendable {
    case male
    case female
}

public enum TrainingFrequency: String, Codable, CaseIterable, Sendable {
    case sedentary
    case light
    case moderate
    case active
    case veryActive

    public var displayName: String {
        switch self {
        case .sedentary: "Sedentary"
        case .light: "Light"
        case .moderate: "Moderate"
        case .active: "Active"
        case .veryActive: "Very Active"
        }
    }
}

public enum GoalTimeline: String, Codable, CaseIterable, Sendable {
    case weeks4
    case weeks8
    case weeks12
    case weeks24
    case noRush

    public var displayName: String {
        switch self {
        case .weeks4: "4 Weeks"
        case .weeks8: "8 Weeks"
        case .weeks12: "12 Weeks"
        case .weeks24: "24 Weeks"
        case .noRush: "No Rush"
        }
    }
}

public enum Weekday: String, Codable, CaseIterable, Sendable {
    case sunday
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
}
