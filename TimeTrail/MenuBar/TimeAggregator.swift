import Foundation

enum TimeAggregator {
    struct ProjectTotal: Equatable {
        let projectId: Int64?
        let projectName: String
        let color: String?
        let totalSeconds: TimeInterval
    }

    /// Sums segment durations per project bucket.
    /// Open segments (endedAt == nil) use `now` as the end time.
    /// Results are sorted by totalSeconds descending; Unassigned appears at the end.
    static func aggregate(
        segments: [ActivitySegment],
        rules: [ProjectRule],
        projects: [Project],
        now: Date = Date()
    ) -> [ProjectTotal] {
        typealias Bucket = (name: String, color: String?, seconds: TimeInterval)
        var totals: [Int64?: Bucket] = [:]

        let projectIndex = Dictionary(
            uniqueKeysWithValues: projects.compactMap { p -> (Int64, Project)? in
                guard let id = p.id else { return nil }
                return (id, p)
            }
        )

        for segment in segments {
            let end = segment.endedAt ?? now
            let duration = end.timeIntervalSince(segment.startedAt)
            guard duration > 0 else { continue }

            // A manual project override on the segment always wins over rule matching.
            let key: Int64?
            let name: String
            let color: String?
            if let overrideId = segment.overrideProjectId, let project = projectIndex[overrideId] {
                key = overrideId
                name = project.name
                color = project.color
            } else {
                let match = RuleMatcher.match(
                    bundleId: segment.appBundleId,
                    windowTitle: segment.windowTitle,
                    rules: rules,
                    projects: projects
                )
                key = match?.projectId
                name = match?.projectName ?? "Unassigned"
                color = match?.color
            }

            if totals[key] == nil {
                totals[key] = (name: name, color: color, seconds: 0)
            }
            totals[key]!.seconds += duration
        }

        let assigned = totals
            .filter { $0.key != nil }
            .map { ProjectTotal(projectId: $0.key, projectName: $0.value.name, color: $0.value.color, totalSeconds: $0.value.seconds) }
            .sorted { $0.totalSeconds > $1.totalSeconds }

        let unassigned = totals
            .filter { $0.key == nil }
            .map { ProjectTotal(projectId: nil, projectName: $0.value.name, color: nil, totalSeconds: $0.value.seconds) }

        return assigned + unassigned
    }
}
