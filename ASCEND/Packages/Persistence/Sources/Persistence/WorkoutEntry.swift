import Foundation
import SwiftData

@Model
public final class WorkoutEntry {
    public var id: UUID
    public var date: Date
    /// Comma-separated muscle groups, e.g. "chest,shoulders,triceps"
    public var muscleGroups: String
    public var notes: String

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        muscleGroups: String = "",
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.muscleGroups = muscleGroups
        self.notes = notes
    }
}
