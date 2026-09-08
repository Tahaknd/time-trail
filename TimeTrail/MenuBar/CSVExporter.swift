import Foundation

enum CSVExporter {
    struct Row {
        let date: String
        let project: String
        let app: String
        let durationSeconds: Int
    }

    /// Aggregates segments into (date, project, app) buckets and returns RFC 4180 CSV.
    static func build(
        segments: [ActivitySegment],
        rules: [ProjectRule],
        projects: [Project],
        now: Date = Date()
    ) -> String {
        let rows = buildRows(segments: segments, rules: rules, projects: projects, now: now)
        let header = "date,project,app,duration_seconds\n"
        let body = rows
            .map { "\(escape($0.date)),\(escape($0.project)),\(escape($0.app)),\($0.durationSeconds)\n" }
            .joined()
        return header + body
    }

    static func buildRows(
        segments: [ActivitySegment],
        rules: [ProjectRule],
        projects: [Project],
        now: Date = Date()
    ) -> [Row] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        let projectIndex = Dictionary(
            uniqueKeysWithValues: projects.compactMap { p -> (Int64, Project)? in
                guard let id = p.id else { return nil }
                return (id, p)
            }
        )

        typealias Key = String
        var buckets: [Key: (date: String, project: String, app: String, seconds: TimeInterval)] = [:]

        for seg in segments {
            let end = seg.endedAt ?? now
            let duration = end.timeIntervalSince(seg.startedAt)
            guard duration > 0 else { continue }

            let projectName: String
            if let overrideId = seg.overrideProjectId, let project = projectIndex[overrideId] {
                projectName = project.name
            } else {
                let match = RuleMatcher.match(
                    bundleId: seg.appBundleId,
                    windowTitle: seg.windowTitle,
                    rules: rules,
                    projects: projects
                )
                projectName = match?.projectName ?? "Unassigned"
            }
            let date = dateFormatter.string(from: seg.startedAt)
            let key = "\(date)|\(projectName)|\(seg.appName)"

            if buckets[key] == nil {
                buckets[key] = (date: date, project: projectName, app: seg.appName, seconds: 0)
            }
            buckets[key]!.seconds += duration
        }

        return buckets.values
            .sorted { ($0.date, $0.project, $0.app) < ($1.date, $1.project, $1.app) }
            .map { Row(date: $0.date, project: $0.project, app: $0.app, durationSeconds: Int($0.seconds)) }
    }

    static func escape(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else {
            return value
        }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
