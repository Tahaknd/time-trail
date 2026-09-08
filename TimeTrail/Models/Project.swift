import GRDB

struct Project: Codable, FetchableRecord, MutablePersistableRecord {
    var id: Int64?
    var name: String
    var color: String

    static let databaseTableName = "project"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
