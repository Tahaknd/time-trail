import Foundation

enum TimeAggregator {
    struct ProjectTotal: Equatable {
        let projectId: Int64?
        let projectName: String
        let color: String?
        let totalSeconds: TimeInterval
    }

    /// Sums entry durations per project.
    /// Open entries (endedAt == nil) use `now` as the end time.
    /// Results are sorted by totalSeconds descending.
    static func aggregate(
        entries: [TimeEntry],
        projects: [Project],
        now: Date = Date()
    ) -> [ProjectTotal] {
        let projectIndex = Dictionary(
            uniqueKeysWithValues: projects.compactMap { p -> (Int64, Project)? in
                guard let id = p.id else { return nil }
                return (id, p)
            }
        )

        typealias Bucket = (name: String, color: String?, seconds: TimeInterval)
        var totals: [Int64: Bucket] = [:]

        for entry in entries {
            let end = entry.endedAt ?? now
            let duration = end.timeIntervalSince(entry.startedAt)
            guard duration > 0 else { continue }

            let project = projectIndex[entry.projectId]
            let name = project?.name ?? "Deleted project"
            let color = project?.color

            if totals[entry.projectId] == nil {
                totals[entry.projectId] = (name: name, color: color, seconds: 0)
            }
            totals[entry.projectId]!.seconds += duration
        }

        return totals
            .map { ProjectTotal(projectId: $0.key, projectName: $0.value.name, color: $0.value.color, totalSeconds: $0.value.seconds) }
            .sorted { $0.totalSeconds > $1.totalSeconds }
    }
}
