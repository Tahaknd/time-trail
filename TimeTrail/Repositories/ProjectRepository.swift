import GRDB

struct ProjectRepository {
    let db: DatabaseQueue

    func insert(_ project: inout Project) throws {
        try db.write { try project.insert($0) }
    }

    func fetch(id: Int64) throws -> Project? {
        try db.read { try Project.fetchOne($0, key: id) }
    }

    func fetchAll() throws -> [Project] {
        try db.read { try Project.fetchAll($0) }
    }

    func update(_ project: Project) throws {
        try db.write { try project.update($0) }
    }

    func delete(id: Int64) throws {
        try db.write { _ = try Project.deleteOne($0, key: id) }
    }
}
