import Foundation
import GRDB

struct ActivitySegment: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var appBundleId: String
    var appName: String
    var windowTitle: String?
    var startedAt: Date
    var endedAt: Date?
    var overrideProjectId: Int64? = nil

    static let databaseTableName = "activity_segment"

    enum CodingKeys: String, CodingKey {
        case id
        case appBundleId = "app_bundle_id"
        case appName = "app_name"
        case windowTitle = "window_title"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case overrideProjectId = "override_project_id"
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
