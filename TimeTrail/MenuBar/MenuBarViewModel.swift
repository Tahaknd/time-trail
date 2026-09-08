import Foundation
import GRDB

final class MenuBarViewModel: ObservableObject {
    @Published private(set) var projectTimes: [TimeAggregator.ProjectTotal] = []
    @Published private(set) var totalSeconds: TimeInterval = 0

    private let segmentRepo: ActivitySegmentRepository
    private let projectRepo: ProjectRepository
    private let ruleRepo: ProjectRuleRepository

    init(db: DatabaseQueue) {
        segmentRepo = ActivitySegmentRepository(db: db)
        projectRepo = ProjectRepository(db: db)
        ruleRepo = ProjectRuleRepository(db: db)
    }

    /// Reloads today's activity from the database. Must be called from the main thread.
    func refresh() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }

        do {
            let segments = try segmentRepo.fetchByDateRange(from: startOfDay, to: endOfDay)
            let projects = try projectRepo.fetchAll()
            let rules = try ruleRepo.fetchAll()

            let times = TimeAggregator.aggregate(segments: segments, rules: rules, projects: projects)
            projectTimes = times
            totalSeconds = times.reduce(0) { $0 + $1.totalSeconds }
        } catch {
            // Fail silently — stale data stays visible until the next successful refresh.
        }
    }
}
