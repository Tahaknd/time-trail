import GRDB

struct ProjectRule: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var projectId: Int64
    var appBundleId: String
    var windowTitleKeyword: String?

    static let databaseTableName = "project_rule"

    enum CodingKeys: String, CodingKey {
        case id
        case projectId = "project_id"
        case appBundleId = "app_bundle_id"
        case windowTitleKeyword = "window_title_keyword"
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
