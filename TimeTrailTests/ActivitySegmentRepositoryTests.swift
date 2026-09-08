import XCTest
import GRDB
@testable import TimeTrail

final class ActivitySegmentRepositoryTests: XCTestCase {
    var db: DatabaseQueue!
    var repo: ActivitySegmentRepository!

    override func setUpWithError() throws {
        db = try DatabaseManager.inMemory()
        repo = ActivitySegmentRepository(db: db)
    }

    func testInsertAssignsId() throws {
        var segment = ActivitySegment(
            id: nil,
            appBundleId: "com.apple.Safari",
            appName: "Safari",
            windowTitle: "Apple",
            startedAt: Date(),
            endedAt: nil
        )
        try repo.insert(&segment)
        XCTAssertNotNil(segment.id)
    }

    func testFetchRoundTrip() throws {
        var segment = ActivitySegment(
            id: nil,
            appBundleId: "com.apple.Safari",
            appName: "Safari",
            windowTitle: "GitHub",
            startedAt: Date(timeIntervalSince1970: 1000),
            endedAt: nil
        )
        try repo.insert(&segment)

        let fetched = try repo.fetch(id: segment.id!)
        XCTAssertEqual(fetched?.appBundleId, "com.apple.Safari")
        XCTAssertEqual(fetched?.appName, "Safari")
        XCTAssertEqual(fetched?.windowTitle, "GitHub")
        XCTAssertNil(fetched?.endedAt)
    }

    func testFetchAll() throws {
        var s1 = ActivitySegment(id: nil, appBundleId: "com.a", appName: "A", windowTitle: nil, startedAt: Date(), endedAt: nil)
        var s2 = ActivitySegment(id: nil, appBundleId: "com.b", appName: "B", windowTitle: nil, startedAt: Date(), endedAt: nil)
        try repo.insert(&s1)
        try repo.insert(&s2)

        let all = try repo.fetchAll()
        XCTAssertEqual(all.count, 2)
    }

    func testUpdate() throws {
        var segment = ActivitySegment(id: nil, appBundleId: "com.a", appName: "A", windowTitle: nil, startedAt: Date(), endedAt: nil)
        try repo.insert(&segment)

        var updated = segment
        updated.endedAt = Date(timeIntervalSince1970: 9000)
        try repo.update(updated)

        let fetched = try repo.fetch(id: segment.id!)
        XCTAssertEqual(fetched?.endedAt?.timeIntervalSince1970 ?? 0, 9000, accuracy: 1)
    }

    func testDelete() throws {
        var segment = ActivitySegment(id: nil, appBundleId: "com.a", appName: "A", windowTitle: nil, startedAt: Date(), endedAt: nil)
        try repo.insert(&segment)

        try repo.delete(id: segment.id!)

        let fetched = try repo.fetch(id: segment.id!)
        XCTAssertNil(fetched)
    }

    func testFetchOpenReturnsOnlyOpenSegments() throws {
        var open = ActivitySegment(id: nil, appBundleId: "com.a", appName: "A", windowTitle: nil, startedAt: Date(), endedAt: nil)
        var closed = ActivitySegment(id: nil, appBundleId: "com.b", appName: "B", windowTitle: nil, startedAt: Date(), endedAt: Date())
        try repo.insert(&open)
        try repo.insert(&closed)

        let result = try repo.fetchOpen()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.appBundleId, "com.a")
    }

    func testFetchByDateRange() throws {
        let base = Date(timeIntervalSince1970: 86400)
        var inside = ActivitySegment(id: nil, appBundleId: "com.a", appName: "A", windowTitle: nil, startedAt: base + 3600, endedAt: nil)
        var before = ActivitySegment(id: nil, appBundleId: "com.b", appName: "B", windowTitle: nil, startedAt: base - 3600, endedAt: nil)
        var after = ActivitySegment(id: nil, appBundleId: "com.c", appName: "C", windowTitle: nil, startedAt: base + 90000, endedAt: nil)
        try repo.insert(&inside)
        try repo.insert(&before)
        try repo.insert(&after)

        let result = try repo.fetchByDateRange(from: base, to: base + 86400)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.appBundleId, "com.a")
    }
}
