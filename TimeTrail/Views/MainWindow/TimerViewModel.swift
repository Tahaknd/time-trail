import Foundation
import GRDB

final class TimerViewModel: ObservableObject {
    @Published private(set) var allProjects: [Project] = []
    @Published private(set) var recentEntries: [TimeEntry] = []
    @Published private(set) var runningEntry: TimeEntry?
    @Published var errorMessage: String?

    let timerController: TimerController

    private let entryRepo: TimeEntryRepository
    private let projectRepo: ProjectRepository

    init(db: DatabaseQueue) {
        entryRepo = TimeEntryRepository(db: db)
        projectRepo = ProjectRepository(db: db)
        timerController = TimerController(repository: entryRepo)
        runningEntry = timerController.runningEntry
    }

    /// Reloads the project list and the last 14 days of entries. Must be called from the main thread.
    func refresh() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard
            let end = calendar.date(byAdding: .day, value: 1, to: startOfDay),
            let start = calendar.date(byAdding: .day, value: -14, to: startOfDay)
        else { return }

        do {
            allProjects = try projectRepo.fetchAll()
            recentEntries = try entryRepo.fetchByDateRange(from: start, to: end)
            timerController.syncRunningEntry()
            runningEntry = timerController.runningEntry
            publishWidgetSnapshot()
        } catch {
            // Fail silently — stale data stays visible until the next successful refresh.
        }
    }

    /// Pushes a lightweight summary to the App Group so the widget extension
    /// (which can't open the app's sandboxed SQLite database) can show
    /// something without needing IPC into the running app.
    private func publishWidgetSnapshot() {
        let today = recentEntries.filter { Calendar.current.isDateInToday($0.startedAt) }
        var totals: [Int64: TimeInterval] = [:]
        let now = Date()
        for entry in today where entry.endedAt != nil || entry.id == runningEntry?.id {
            totals[entry.projectId, default: 0] += (entry.endedAt ?? now).timeIntervalSince(entry.startedAt)
        }
        let top = totals
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { pid, seconds in
                WidgetSnapshot.ProjectTotal(
                    name: projectName(for: pid),
                    colorHex: projectColor(for: pid) ?? "#8E8E93",
                    seconds: seconds
                )
            }

        let snapshot = WidgetSnapshot(
            runningProjectName: runningEntry.map { projectName(for: $0.projectId) },
            runningProjectColorHex: runningEntry.flatMap { projectColor(for: $0.projectId) },
            runningStartedAt: runningEntry?.startedAt,
            todayTotalSeconds: totalSecondsToday,
            topProjectsToday: Array(top),
            updatedAt: Date()
        )
        WidgetSnapshotStore.write(snapshot)
    }

    var totalSecondsToday: TimeInterval {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let now = Date()
        return recentEntries
            .filter { $0.startedAt >= startOfDay }
            .reduce(0) { $0 + ($1.endedAt ?? now).timeIntervalSince($1.startedAt) }
    }

    func projectName(for id: Int64) -> String {
        allProjects.first(where: { $0.id == id })?.name ?? "Deleted project"
    }

    func projectColor(for id: Int64) -> String? {
        allProjects.first(where: { $0.id == id })?.color
    }

    /// Distinct tag names seen across recently-loaded entries, for quick-pick suggestions.
    var knownTags: [String] {
        var seen = Set<String>()
        var ordered: [String] = []
        for entry in recentEntries {
            for tag in entry.tagList where !seen.contains(tag) {
                seen.insert(tag)
                ordered.append(tag)
            }
        }
        return ordered.sorted()
    }

    // MARK: - Timer control

    func startTimer(projectId: Int64, description: String? = nil, tags: String? = nil) {
        do {
            try timerController.start(projectId: projectId, description: description, tags: tags)
            refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopTimer() {
        do {
            try timerController.stop()
            refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Entry editing

    func deleteEntry(id: Int64) {
        do {
            try entryRepo.delete(id: id)
            refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
