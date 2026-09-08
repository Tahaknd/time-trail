import Foundation
import GRDB

final class MenuBarViewModel: ObservableObject {
    @Published private(set) var allProjects: [Project] = []
    @Published private(set) var todayEntries: [TimeEntry] = []
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

    /// Reloads today's entries and the project list. Must be called from the main thread.
    func refresh() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }

        do {
            allProjects = try projectRepo.fetchAll()
            todayEntries = try entryRepo.fetchByDateRange(from: startOfDay, to: endOfDay)
            runningEntry = timerController.runningEntry
        } catch {
            // Fail silently — stale data stays visible until the next successful refresh.
        }
    }

    var totalSecondsToday: TimeInterval {
        let now = Date()
        return todayEntries.reduce(0) { total, entry in
            total + (entry.endedAt ?? now).timeIntervalSince(entry.startedAt)
        }
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

    func addManualEntry(projectId: Int64, description: String?, start: Date, end: Date) {
        var entry = TimeEntry(projectId: projectId, description: description, startedAt: start, endedAt: end)
        do {
            try entryRepo.insert(&entry)
            refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateEntry(_ entry: TimeEntry) {
        do {
            try entryRepo.update(entry)
            refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteEntry(id: Int64) {
        do {
            try entryRepo.delete(id: id)
            refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
