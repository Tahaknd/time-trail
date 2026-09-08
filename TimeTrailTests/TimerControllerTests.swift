import XCTest
import GRDB
@testable import TimeTrail

final class TimerControllerTests: XCTestCase {
    var db: DatabaseQueue!
    var repo: TimeEntryRepository!
    var controller: TimerController!
    var projectId: Int64!
    var otherProjectId: Int64!

    override func setUpWithError() throws {
        db = try DatabaseManager.inMemory()
        repo = TimeEntryRepository(db: db)

        let projectRepo = ProjectRepository(db: db)
        var project = Project(id: nil, name: "Client Work", color: "#FF0000")
        try projectRepo.insert(&project)
        projectId = project.id!
        var other = Project(id: nil, name: "Internal", color: "#00FF00")
        try projectRepo.insert(&other)
        otherProjectId = other.id!

        controller = TimerController(repository: repo)
    }

    func testStart_createsRunningEntry() throws {
        let entry = try controller.start(projectId: projectId)
        XCTAssertNil(entry.endedAt)
        XCTAssertEqual(controller.runningEntry?.id, entry.id)
    }

    func testStop_closesRunningEntry() throws {
        let entry = try controller.start(projectId: projectId)
        try controller.stop()

        XCTAssertNil(controller.runningEntry)
        let fetched = try repo.fetch(id: entry.id!)
        XCTAssertNotNil(fetched?.endedAt)
    }

    func testStop_withNoRunningEntry_isNoop() throws {
        try controller.stop() // should not throw
        XCTAssertNil(controller.runningEntry)
    }

    func testStart_whileAlreadyRunning_closesPreviousAndStartsNew() throws {
        let first = try controller.start(projectId: projectId)
        let second = try controller.start(projectId: otherProjectId)

        XCTAssertNotEqual(first.id, second.id)
        XCTAssertEqual(controller.runningEntry?.id, second.id)

        let closedFirst = try repo.fetch(id: first.id!)
        XCTAssertNotNil(closedFirst?.endedAt)
    }

    func testInit_picksUpExistingRunningEntry() throws {
        var running = TimeEntry(id: nil, projectId: projectId, description: nil, startedAt: Date(), endedAt: nil)
        try repo.insert(&running)

        let freshController = TimerController(repository: repo)
        XCTAssertEqual(freshController.runningEntry?.id, running.id)
    }
}
