import XCTest
import GRDB
@testable import TimeTrail

final class TimeEntryRepositoryTests: XCTestCase {
    var db: DatabaseQueue!
    var repo: TimeEntryRepository!
    var projectId: Int64!

    override func setUpWithError() throws {
        db = try DatabaseManager.inMemory()
        repo = TimeEntryRepository(db: db)

        var project = Project(id: nil, name: "Client Work", color: "#FF0000")
        try ProjectRepository(db: db).insert(&project)
        projectId = project.id!
    }

    func testInsertAssignsId() throws {
        var entry = TimeEntry(id: nil, projectId: projectId, description: nil, startedAt: Date(), endedAt: nil)
        try repo.insert(&entry)
        XCTAssertNotNil(entry.id)
    }

    func testFetchRoundTrip() throws {
        let start = Date()
        var entry = TimeEntry(id: nil, projectId: projectId, description: "Writing docs", startedAt: start, endedAt: nil)
        try repo.insert(&entry)

        let fetched = try repo.fetch(id: entry.id!)
        XCTAssertEqual(fetched?.description, "Writing docs")
        XCTAssertEqual(fetched?.projectId, projectId)
        XCTAssertNil(fetched?.endedAt)
    }

    func testUpdate_setsEndedAt() throws {
        var entry = TimeEntry(id: nil, projectId: projectId, description: nil, startedAt: Date(), endedAt: nil)
        try repo.insert(&entry)

        var closed = entry
        closed.endedAt = Date()
        try repo.update(closed)

        let fetched = try repo.fetch(id: entry.id!)
        XCTAssertNotNil(fetched?.endedAt)
    }

    func testDelete() throws {
        var entry = TimeEntry(id: nil, projectId: projectId, description: nil, startedAt: Date(), endedAt: nil)
        try repo.insert(&entry)

        try repo.delete(id: entry.id!)

        XCTAssertNil(try repo.fetch(id: entry.id!))
    }

    func testFetchRunning_returnsOpenEntryOnly() throws {
        var closed = TimeEntry(id: nil, projectId: projectId, description: nil, startedAt: Date(), endedAt: Date())
        try repo.insert(&closed)
        var running = TimeEntry(id: nil, projectId: projectId, description: nil, startedAt: Date(), endedAt: nil)
        try repo.insert(&running)

        let fetched = try repo.fetchRunning()
        XCTAssertEqual(fetched?.id, running.id)
    }

    func testFetchRunning_noneOpen_returnsNil() throws {
        var closed = TimeEntry(id: nil, projectId: projectId, description: nil, startedAt: Date(), endedAt: Date())
        try repo.insert(&closed)

        XCTAssertNil(try repo.fetchRunning())
    }

    func testFetchByDateRange_excludesOutsideRange() throws {
        let dayStart = Calendar.current.startOfDay(for: Date())
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
        let yesterday = dayStart.addingTimeInterval(-3600)

        var inRange = TimeEntry(id: nil, projectId: projectId, description: nil, startedAt: dayStart.addingTimeInterval(60), endedAt: nil)
        var outOfRange = TimeEntry(id: nil, projectId: projectId, description: nil, startedAt: yesterday, endedAt: yesterday.addingTimeInterval(60))
        try repo.insert(&inRange)
        try repo.insert(&outOfRange)

        let result = try repo.fetchByDateRange(from: dayStart, to: dayEnd)
        XCTAssertEqual(result.map(\.id), [inRange.id])
    }
}
