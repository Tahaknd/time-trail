import XCTest
import GRDB
@testable import TimeTrail

final class ProjectRepositoryTests: XCTestCase {
    var db: DatabaseQueue!
    var repo: ProjectRepository!

    override func setUpWithError() throws {
        db = try DatabaseManager.inMemory()
        repo = ProjectRepository(db: db)
    }

    func testInsertAssignsId() throws {
        var project = Project(id: nil, name: "Client Work", color: "#FF0000")
        try repo.insert(&project)
        XCTAssertNotNil(project.id)
    }

    func testFetchRoundTrip() throws {
        var project = Project(id: nil, name: "Client Work", color: "#FF0000")
        try repo.insert(&project)

        let fetched = try repo.fetch(id: project.id!)
        XCTAssertEqual(fetched?.name, "Client Work")
        XCTAssertEqual(fetched?.color, "#FF0000")
    }

    func testFetchAll() throws {
        var p1 = Project(id: nil, name: "Project A", color: "#FF0000")
        var p2 = Project(id: nil, name: "Project B", color: "#00FF00")
        try repo.insert(&p1)
        try repo.insert(&p2)

        let all = try repo.fetchAll()
        XCTAssertEqual(all.count, 2)
    }

    func testUpdate() throws {
        var project = Project(id: nil, name: "Old Name", color: "#FF0000")
        try repo.insert(&project)

        var updated = project
        updated.name = "New Name"
        updated.color = "#0000FF"
        try repo.update(updated)

        let fetched = try repo.fetch(id: project.id!)
        XCTAssertEqual(fetched?.name, "New Name")
        XCTAssertEqual(fetched?.color, "#0000FF")
    }

    func testDelete() throws {
        var project = Project(id: nil, name: "Delete Me", color: "#FF0000")
        try repo.insert(&project)

        try repo.delete(id: project.id!)

        let fetched = try repo.fetch(id: project.id!)
        XCTAssertNil(fetched)
    }

    func testFetchNonExistentReturnsNil() throws {
        let fetched = try repo.fetch(id: 999)
        XCTAssertNil(fetched)
    }
}
