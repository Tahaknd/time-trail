import Foundation
import GRDB

final class MenuBarViewModel: ObservableObject {
    @Published private(set) var projectTimes: [TimeAggregator.ProjectTotal] = []
    @Published private(set) var totalSeconds: TimeInterval = 0
    @Published private(set) var allProjects: [Project] = []
    @Published private(set) var activeOverrideProjectId: Int64?

    private let segmentRepo: ActivitySegmentRepository
    private let projectRepo: ProjectRepository
    private let ruleRepo: ProjectRuleRepository
    private let activeProjectStore: ActiveProjectStore

    init(db: DatabaseQueue, activeProjectStore: ActiveProjectStore = .shared) {
        segmentRepo = ActivitySegmentRepository(db: db)
        projectRepo = ProjectRepository(db: db)
        ruleRepo = ProjectRuleRepository(db: db)
        self.activeProjectStore = activeProjectStore
    }

    /// Reloads today's activity from the database. Must be called from the main thread.
    func refresh() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }

        activeOverrideProjectId = activeProjectStore.currentProjectId

        do {
            let segments = try segmentRepo.fetchByDateRange(from: startOfDay, to: endOfDay)
            let projects = try projectRepo.fetchAll()
            let rules = try ruleRepo.fetchAll()

            allProjects = projects
            let times = TimeAggregator.aggregate(segments: segments, rules: rules, projects: projects)
            projectTimes = times
            totalSeconds = times.reduce(0) { $0 + $1.totalSeconds }
        } catch {
            // Fail silently — stale data stays visible until the next successful refresh.
        }
    }

    /// Sets or clears the manual "working on" override. `nil` returns to automatic rule matching.
    func setActiveProject(_ projectId: Int64?) {
        activeProjectStore.currentProjectId = projectId
        activeOverrideProjectId = projectId
    }
}
