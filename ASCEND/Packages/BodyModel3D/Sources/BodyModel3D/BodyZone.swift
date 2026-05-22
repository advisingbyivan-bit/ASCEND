import SwiftUI

public enum BodyZone: String, CaseIterable, Identifiable {
    case shoulders
    case chest
    case arms
    case back
    case core
    case abs
    case legs
    case glutes

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .shoulders: "Shoulders"
        case .chest: "Chest"
        case .arms: "Arms"
        case .back: "Back"
        case .core: "Core"
        case .abs: "Abs"
        case .legs: "Legs"
        case .glutes: "Glutes"
        }
    }

    /// Whether this zone is best viewed from the back of the model
    public var isBackFacing: Bool {
        switch self {
        case .back, .glutes: true
        default: false
        }
    }
}

public enum ZoneStatus: Equatable {
    case base
    case weak
    case moderate
    case strong
    case target

    public var color: Color {
        switch self {
        case .base: Color(red: 0.1, green: 0.3, blue: 0.6)
        case .weak: Color(red: 1, green: 23.0/255, blue: 68.0/255)
        case .moderate: Color(red: 1, green: 193.0/255, blue: 7.0/255) // Yellow
        case .strong: Color(red: 57.0/255, green: 1, blue: 20.0/255)
        case .target: Color(red: 0, green: 217.0/255, blue: 1)
        }
    }
}

public enum BodyGender {
    case male
    case female
}
