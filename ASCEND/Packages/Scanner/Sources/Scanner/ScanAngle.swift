import Foundation

public enum ScanAngle: Int, CaseIterable {
    case front = 0
    case side = 1
    case back = 2

    public var instruction: String {
        switch self {
        case .front: "Face the camera straight on"
        case .side: "Turn to your left side"
        case .back: "Turn around, face away"
        }
    }

    public var label: String {
        switch self {
        case .front: "FRONT"
        case .side: "SIDE"
        case .back: "BACK"
        }
    }

    public var progress: Double {
        switch self {
        case .front: 0.33
        case .side: 0.67
        case .back: 1.0
        }
    }
}
