import Foundation
import GRDB

final class DatabaseManager {
    static let shared = DatabaseManager()

    let dbQueue: DatabaseQueue

    private init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        let dbDir = appSupport.appendingPathComponent("TimeTrail")
        try! FileManager.default.createDirectory(at: dbDir, withIntermediateDirectories: true)
        let dbURL = dbDir.appendingPathComponent("timetrail.sqlite")
        dbQueue = try! DatabaseQueue(path: dbURL.path)
        try! Migrations.migrate(dbQueue)
    }

    static func inMemory() throws -> DatabaseQueue {
        let queue = try DatabaseQueue()
        try Migrations.migrate(queue)
        return queue
    }
}
