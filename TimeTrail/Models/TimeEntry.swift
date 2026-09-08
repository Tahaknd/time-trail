import Foundation
import GRDB

struct TimeEntry: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var projectId: Int64
    var description: String?
    var startedAt: Date
    var endedAt: Date?
    /// Comma-separated tag names. Kept as a flat string rather than a
    /// relational table — tags are a lightweight, unstructured label here.
    var tags: String? = nil

    static let databaseTableName = "time_entry"

    enum CodingKeys: String, CodingKey {
        case id
        case projectId = "project_id"
        case description
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case tags
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    /// Parsed, trimmed, non-empty tag names.
    var tagList: [String] {
        guard let tags else { return [] }
        return tags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    static func joinTags(_ list: [String]) -> String? {
        let cleaned = list.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        return cleaned.isEmpty ? nil : cleaned.joined(separator: ", ")
    }
}
