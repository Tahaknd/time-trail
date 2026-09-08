import XCTest
import GRDB
@testable import TimeTrail

final class ProjectRuleRepositoryTests: XCTestCase {
    var db: DatabaseQueue!
    var projectRepo: ProjectRepository!
    var ruleRepo: ProjectRuleRepository!
    var testProjectId: Int64!

    override func setUpWithError() throws {
        db = try DatabaseManager.inMemory()
        projectRepo = ProjectRepository(db: db)
        ruleRepo = ProjectRuleRepository(db: db)

        var project = Project(id: nil, name: "Test Project", color: "#FF0000")
        try projectRepo.insert(&project)
        testProjectId = project.id!
    }

    func testInsertAssignsId() throws {
        var rule = ProjectRule(id: nil, projectId: testProjectId, appBundleId: "com.apple.Safari", windowTitleKeyword: nil)
        try ruleRepo.insert(&rule)
        XCTAssertNotNil(rule.id)
    }

    func testFetchRoundTrip() throws {
        var rule = ProjectRule(id: nil, projectId: testProjectId, appBundleId: "com.apple.Safari", windowTitleKeyword: "GitHub")
        try ruleRepo.insert(&rule)

        let fetched = try ruleRepo.fetch(id: rule.id!)
        XCTAssertEqual(fetched?.appBundleId, "com.apple.Safari")
        XCTAssertEqual(fetched?.windowTitleKeyword, "GitHub")
        XCTAssertEqual(fetched?.projectId, testProjectId)
    }

    func testFetchRoundTripNilKeyword() throws {
        var rule = ProjectRule(id: nil, projectId: testProjectId, appBundleId: "com.apple.Xcode", windowTitleKeyword: nil)
        try ruleRepo.insert(&rule)

        let fetched = try ruleRepo.fetch(id: rule.id!)
        XCTAssertNil(fetched?.windowTitleKeyword)
    }

    func testFetchByProjectId() throws {
        var r1 = ProjectRule(id: nil, projectId: testProjectId, appBundleId: "com.a", windowTitleKeyword: nil)
        var r2 = ProjectRule(id: nil, projectId: testProjectId, appBundleId: "com.b", windowTitleKeyword: "Report")

        var otherProject = Project(id: nil, name: "Other", color: "#0000FF")
        try projectRepo.insert(&otherProject)
        var r3 = ProjectRule(id: nil, projectId: otherProject.id!, appBundleId: "com.c", windowTitleKeyword: nil)

        try ruleRepo.insert(&r1)
        try ruleRepo.insert(&r2)
        try ruleRepo.insert(&r3)

        let rules = try ruleRepo.fetchByProjectId(testProjectId)
        XCTAssertEqual(rules.count, 2)
        XCTAssertTrue(rules.allSatisfy { $0.projectId == testProjectId })
    }

    func testUpdate() throws {
        var rule = ProjectRule(id: nil, projectId: testProjectId, appBundleId: "com.a", windowTitleKeyword: nil)
        try ruleRepo.insert(&rule)

        var updated = rule
        updated.windowTitleKeyword = "Invoice"
        try ruleRepo.update(updated)

        let fetched = try ruleRepo.fetch(id: rule.id!)
        XCTAssertEqual(fetched?.windowTitleKeyword, "Invoice")
    }

    func testDelete() throws {
        var rule = ProjectRule(id: nil, projectId: testProjectId, appBundleId: "com.a", windowTitleKeyword: nil)
        try ruleRepo.insert(&rule)

        try ruleRepo.delete(id: rule.id!)

        let fetched = try ruleRepo.fetch(id: rule.id!)
        XCTAssertNil(fetched)
    }

    func testCascadeDeleteWhenProjectDeleted() throws {
        var rule = ProjectRule(id: nil, projectId: testProjectId, appBundleId: "com.a", windowTitleKeyword: nil)
        try ruleRepo.insert(&rule)

        try projectRepo.delete(id: testProjectId)

        let fetched = try ruleRepo.fetch(id: rule.id!)
        XCTAssertNil(fetched)
    }
}
