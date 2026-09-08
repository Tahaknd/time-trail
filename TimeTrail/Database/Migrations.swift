import GRDB

enum Migrations {
    static func migrate(_ writer: any DatabaseWriter) throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_initial_schema") { db in
            try db.create(table: "project") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("color", .text).notNull()
            }

            try db.create(table: "activity_segment") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("app_bundle_id", .text).notNull()
                t.column("app_name", .text).notNull()
                t.column("window_title", .text)
                t.column("started_at", .datetime).notNull()
                t.column("ended_at", .datetime)
            }

            try db.create(table: "project_rule") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("project_id", .integer).notNull().references("project", onDelete: .cascade)
                t.column("app_bundle_id", .text).notNull()
                t.column("window_title_keyword", .text)
            }
        }

        try migrator.migrate(writer)
    }
}
