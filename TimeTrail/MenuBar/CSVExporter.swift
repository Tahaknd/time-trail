import Foundation

enum CSVExporter {
    struct Row {
        let date: String
        let project: String
        let description: String
        let durationSeconds: Int
    }

    /// Aggregates entries into (date, project, description) buckets and returns RFC 4180 CSV.
    static func build(
        entries: [TimeEntry],
        projects: [Project],
        now: Date = Date()
    ) -> String {
        let rows = buildRows(entries: entries, projects: projects, now: now)
        let header = "date,project,description,duration_seconds\n"
        let body = rows
            .map { "\(escape($0.date)),\(escape($0.project)),\(escape($0.description)),\($0.durationSeconds)\n" }
            .joined()
        return header + body
    }

    static func buildRows(
        entries: [TimeEntry],
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
        var buckets: [Key: (date: String, project: String, description: String, seconds: TimeInterval)] = [:]

        for entry in entries {
            let end = entry.endedAt ?? now
            let duration = end.timeIntervalSince(entry.startedAt)
            guard duration > 0 else { continue }

            let projectName = projectIndex[entry.projectId]?.name ?? "Deleted project"
            let description = entry.description ?? ""
            let date = dateFormatter.string(from: entry.startedAt)
            let key = "\(date)|\(projectName)|\(description)"

            if buckets[key] == nil {
                buckets[key] = (date: date, project: projectName, description: description, seconds: 0)
            }
            buckets[key]!.seconds += duration
        }

        return buckets.values
            .sorted { ($0.date, $0.project, $0.description) < ($1.date, $1.project, $1.description) }
            .map { Row(date: $0.date, project: $0.project, description: $0.description, durationSeconds: Int($0.seconds)) }
    }

    static func escape(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else {
            return value
        }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
