import Foundation

/// Owns the currently-running time entry, if any. Purely user-driven —
/// no background polling or app observation, unlike v1's TrackingEngine.
final class TimerController: ObservableObject {
    @Published private(set) var runningEntry: TimeEntry?

    private let repository: TimeEntryRepository

    init(repository: TimeEntryRepository) {
        self.repository = repository
        runningEntry = try? repository.fetchRunning()
    }

    /// Re-reads the running entry from the database. Multiple TimerController
    /// instances exist at once (main window, status item) and each only
    /// updates its own in-memory state on its own start()/stop() calls — so
    /// without this, one instance can go stale relative to a timer
    /// started/stopped through a different instance.
    func syncRunningEntry() {
        runningEntry = try? repository.fetchRunning()
    }

    @discardableResult
    func start(projectId: Int64, description: String? = nil, tags: String? = nil) throws -> TimeEntry {
        if runningEntry != nil {
            try stop()
        }
        var entry = TimeEntry(
            projectId: projectId,
            description: description,
            startedAt: Date(),
            endedAt: nil,
            tags: tags
        )
        try repository.insert(&entry)
        runningEntry = entry
        return entry
    }

    func stop() throws {
        guard var entry = runningEntry else { return }
        entry.endedAt = Date()
        try repository.update(entry)
        runningEntry = nil
    }
}
