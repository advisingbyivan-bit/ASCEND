import Foundation
import SwiftData

public final class DataStore {
    public static let shared = DataStore()

    public let container: ModelContainer?

    /// True if the data store failed to initialize and is running in degraded mode.
    public var isDegraded: Bool { container == nil }

    private init() {
        // Fast-fail: try persistent once, then in-memory once. No slow retry chain.
        let schema = Schema([ScanRecord.self, UserProfile.self, WorkoutEntry.self])
        var resolved: ModelContainer?

        // First try: persistent storage
        do {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            resolved = try ModelContainer(for: schema, configurations: [config])
        } catch {
            #if DEBUG
            print("⚠️ SwiftData persistent store failed: \(error). Trying in-memory.")
            #endif
            Self.deleteExistingStore()

            // Second try: in-memory only (skip persistent retry — it's slow)
            do {
                let memConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                resolved = try ModelContainer(for: schema, configurations: [memConfig])
            } catch {
                #if DEBUG
                print("❌ ModelContainer failed entirely: \(error). Running without persistence.")
                #endif
                resolved = nil
            }
        }

        container = resolved
    }

    /// Deletes the default SwiftData store files so a fresh database can be created.
    private static func deleteExistingStore() {
        let fm = FileManager.default
        guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }

        // SwiftData stores files as default.store, default.store-shm, default.store-wal
        let storeFiles = ["default.store", "default.store-shm", "default.store-wal"]
        for file in storeFiles {
            let url = appSupport.appendingPathComponent(file)
            try? fm.removeItem(at: url)
        }
    }

    @MainActor
    public func saveScan(_ record: ScanRecord) throws {
        guard let container else { return }
        let context = container.mainContext
        context.insert(record)
        try context.save()
    }

    @MainActor
    public func fetchScans() throws -> [ScanRecord] {
        guard let container else { return [] }
        let context = container.mainContext
        let descriptor = FetchDescriptor<ScanRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return try context.fetch(descriptor)
    }

    @MainActor
    public func saveProfile(_ profile: UserProfile) throws {
        guard let container else { return }
        let context = container.mainContext
        context.insert(profile)
        try context.save()
    }

    @MainActor
    public func fetchProfile() throws -> UserProfile? {
        guard let container else { return nil }
        let context = container.mainContext
        let descriptor = FetchDescriptor<UserProfile>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try context.fetch(descriptor).first
    }

    @MainActor
    public func updateProfileWeight(_ weightKg: Double) throws {
        guard let container else { return }
        let context = container.mainContext
        let descriptor = FetchDescriptor<UserProfile>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        if let profile = try context.fetch(descriptor).first {
            profile.weightKg = weightKg
            try context.save()
        }
    }

    /// Update a single field on the most recent profile.
    @MainActor
    public func updateProfileField<T>(_ keyPath: ReferenceWritableKeyPath<UserProfile, T>, value: T) throws {
        guard let container else { return }
        let context = container.mainContext
        let descriptor = FetchDescriptor<UserProfile>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        if let profile = try context.fetch(descriptor).first {
            profile[keyPath: keyPath] = value
            try context.save()
        }
    }

    // MARK: - Workout Entries

    @MainActor
    public func saveWorkout(_ entry: WorkoutEntry) throws {
        guard let container else { return }
        let context = container.mainContext
        context.insert(entry)
        try context.save()
    }

    @MainActor
    public func fetchWorkouts() throws -> [WorkoutEntry] {
        guard let container else { return [] }
        let context = container.mainContext
        let descriptor = FetchDescriptor<WorkoutEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return try context.fetch(descriptor)
    }

    /// Check if the user logged a workout today.
    @MainActor
    public func hasWorkoutToday() throws -> Bool {
        guard let container else { return false }
        let context = container.mainContext
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = #Predicate<WorkoutEntry> { $0.date >= startOfDay }
        var descriptor = FetchDescriptor<WorkoutEntry>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try !context.fetch(descriptor).isEmpty
    }

    /// Fetch all workout weekdays this week (1=Sun … 7=Sat).
    @MainActor
    public func workoutWeekdays() throws -> Set<Int> {
        guard let container else { return [] }
        let context = container.mainContext
        let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let predicate = #Predicate<WorkoutEntry> { $0.date >= startOfWeek }
        let descriptor = FetchDescriptor<WorkoutEntry>(predicate: predicate)
        let entries = try context.fetch(descriptor)
        return Set(entries.map { Calendar.current.component(.weekday, from: $0.date) })
    }

    // MARK: - Delete All

    @MainActor
    public func deleteAllData() throws {
        guard let container else { return }
        let context = container.mainContext
        try context.delete(model: ScanRecord.self)
        try context.delete(model: UserProfile.self)
        try context.delete(model: WorkoutEntry.self)
        try context.save()
    }
}
