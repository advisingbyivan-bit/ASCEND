import BodyModel3D

extension BodyZone {
    static func from(_ string: String) -> BodyZone? {
        let normalized = string.lowercased().trimmingCharacters(in: .whitespaces)
        switch normalized {
        case "shoulders", "delts", "deltoids": return .shoulders
        case "chest", "pecs", "pectorals": return .chest
        case "arms", "biceps", "triceps": return .arms
        case "back", "lats", "upper back", "lower back": return .back
        case "core", "obliques": return .core
        case "abs", "abdominals": return .abs
        case "legs", "quads", "hamstrings", "calves": return .legs
        case "glutes", "butt", "buttocks", "hips": return .glutes
        default: return BodyZone(rawValue: normalized)
        }
    }
}

extension ZoneStatus {
    static func from(_ string: String) -> ZoneStatus? {
        switch string.lowercased().trimmingCharacters(in: .whitespaces) {
        case "weak", "declining": return .weak
        case "moderate", "maintaining": return .moderate
        case "strong", "improving": return .strong
        case "target": return .target
        default: return .moderate
        }
    }
}
