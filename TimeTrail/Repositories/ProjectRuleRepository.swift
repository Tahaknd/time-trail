import GRDB

struct ProjectRuleRepository {
    let db: DatabaseQueue

    func insert(_ rule: inout ProjectRule) throws {
        try db.write { try rule.insert($0) }
    }

    func fetch(id: Int64) throws -> ProjectRule? {
        try db.read { try ProjectRule.fetchOne($0, key: id) }
    }

    func fetchAll() throws -> [ProjectRule] {
        try db.read { try ProjectRule.fetchAll($0) }
    }

    func fetchByProjectId(_ projectId: Int64) throws -> [ProjectRule] {
        try db.read { db in
            try ProjectRule
                .filter(Column("project_id") == projectId)
                .fetchAll(db)
        }
    }

    func update(_ rule: ProjectRule) throws {
        try db.write { try rule.update($0) }
    }

    func delete(id: Int64) throws {
        try db.write { _ = try ProjectRule.deleteOne($0, key: id) }
    }
}
