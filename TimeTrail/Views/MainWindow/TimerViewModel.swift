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
            runningEntry = timerController.runningEntry
        } catch {
            // Fail silently — stale data stays visible until the next successful refresh.
        }
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

    // MARK: - Timer control

    func startTimer(projectId: Int64, description: String? = nil) {
        do {
            try timerController.start(projectId: projectId, description: description)
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
