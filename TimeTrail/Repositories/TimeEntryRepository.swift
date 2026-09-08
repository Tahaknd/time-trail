import Foundation
import GRDB

struct TimeEntryRepository {
    let db: DatabaseQueue

    func insert(_ entry: inout TimeEntry) throws {
        try db.write { try entry.insert($0) }
    }

    func fetch(id: Int64) throws -> TimeEntry? {
        try db.read { try TimeEntry.fetchOne($0, key: id) }
    }

    func fetchAll() throws -> [TimeEntry] {
        try db.read { try TimeEntry.fetchAll($0) }
    }

    func update(_ entry: TimeEntry) throws {
        try db.write { try entry.update($0) }
    }

    func delete(id: Int64) throws {
        try db.write { _ = try TimeEntry.deleteOne($0, key: id) }
    }

    /// Returns the currently running entry (ended_at is null), if any.
    /// There should be at most one at a time.
    func fetchRunning() throws -> TimeEntry? {
        try db.read { db in
            try TimeEntry
                .filter(Column("ended_at") == nil)
                .fetchOne(db)
        }
    }

    /// Returns entries whose started_at falls within [from, to).
    func fetchByDateRange(from: Date, to: Date) throws -> [TimeEntry] {
        try db.read { db in
            try TimeEntry
                .filter(Column("started_at") >= from && Column("started_at") < to)
                .order(Column("started_at").desc)
                .fetchAll(db)
        }
    }
}
