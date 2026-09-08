import Foundation
import GRDB

struct TimeEntry: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var projectId: Int64
    var description: String?
    var startedAt: Date
    var endedAt: Date?

    static let databaseTableName = "time_entry"

    enum CodingKeys: String, CodingKey {
        case id
        case projectId = "project_id"
        case description
        case startedAt = "started_at"
        case endedAt = "ended_at"
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
