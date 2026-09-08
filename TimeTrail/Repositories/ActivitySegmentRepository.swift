import Foundation
import GRDB

struct ActivitySegmentRepository {
    let db: DatabaseQueue

    func insert(_ segment: inout ActivitySegment) throws {
        try db.write { try segment.insert($0) }
    }

    func fetch(id: Int64) throws -> ActivitySegment? {
        try db.read { try ActivitySegment.fetchOne($0, key: id) }
    }

    func fetchAll() throws -> [ActivitySegment] {
        try db.read { try ActivitySegment.fetchAll($0) }
    }

    func update(_ segment: ActivitySegment) throws {
        try db.write { try segment.update($0) }
    }

    func delete(id: Int64) throws {
        try db.write { _ = try ActivitySegment.deleteOne($0, key: id) }
    }

    /// Returns segments with no ended_at (currently recording).
    func fetchOpen() throws -> [ActivitySegment] {
        try db.read { db in
            try ActivitySegment
                .filter(Column("ended_at") == nil)
                .fetchAll(db)
        }
    }

    /// Returns segments whose started_at falls within [from, to).
    func fetchByDateRange(from: Date, to: Date) throws -> [ActivitySegment] {
        try db.read { db in
            try ActivitySegment
                .filter(Column("started_at") >= from && Column("started_at") < to)
                .fetchAll(db)
        }
    }
}
