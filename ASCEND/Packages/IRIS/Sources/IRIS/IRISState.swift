import Foundation

public enum IRISState: Equatable {
    case idle
    case listening
    case processing
    case speaking
    case celebration
    case warning

    var bandSpeed: Double {
        switch self {
        case .idle: 10
        case .listening: 5
        case .processing: 2
        case .speaking: 6
        case .celebration: 3
        case .warning: 16
        }
    }

    var glowIntensity: Double {
        switch self {
        case .idle: 0.4
        case .listening: 0.6
        case .processing: 0.9
        case .speaking: 0.7
        case .celebration: 1.0
        case .warning: 0.3
        }
    }

    var particleDensity: Double {
        switch self {
        case .idle: 0.3
        case .listening: 0.5
        case .processing: 0.8
        case .speaking: 0.6
        case .celebration: 1.0
        case .warning: 0.15
        }
    }
}

public enum IRISSphereSize {
    case full        // 240pt — diagnosis reveal, onboarding
    case dashboard   // 120pt — home tab
    case notification // 60pt — alerts
    case badge       // 36pt — inline
    case tabIcon     // 32pt — tab bar

    public var points: CGFloat {
        switch self {
        case .full: 240
        case .dashboard: 120
        case .notification: 60
        case .badge: 36
        case .tabIcon: 32
        }
    }
}
