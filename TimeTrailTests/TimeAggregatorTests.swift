import XCTest
@testable import TimeTrail

final class TimeAggregatorTests: XCTestCase {

    // MARK: - Helpers

    private let t0 = Date(timeIntervalSinceReferenceDate: 0)

    private func entry(
        projectId: Int64,
        start: TimeInterval,
        end: TimeInterval?
    ) -> TimeEntry {
        TimeEntry(
            id: nil,
            projectId: projectId,
            description: nil,
            startedAt: t0.addingTimeInterval(start),
            endedAt: end.map { t0.addingTimeInterval($0) }
        )
    }

    private func project(id: Int64, name: String, color: String = "#AABBCC") -> Project {
        Project(id: id, name: name, color: color)
    }

    // MARK: - Empty input

    func testEmpty_returnsEmpty() {
        let result = TimeAggregator.aggregate(entries: [], projects: [], now: t0)
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Duration calculation

    func testClosedEntry_correctDuration() {
        let p = project(id: 1, name: "Work")
        let e = entry(projectId: 1, start: 0, end: 3600)

        let result = TimeAggregator.aggregate(entries: [e], projects: [p], now: t0)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].totalSeconds, 3600, accuracy: 0.001)
    }

    func testOpenEntry_usesNow() {
        let p = project(id: 1, name: "Work")
        let e = entry(projectId: 1, start: 0, end: nil)
        let now = t0.addingTimeInterval(1800)

        let result = TimeAggregator.aggregate(entries: [e], projects: [p], now: now)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].totalSeconds, 1800, accuracy: 0.001)
    }

    func testZeroDurationClosedEntry_excluded() {
        let p = project(id: 1, name: "Work")
        let e = entry(projectId: 1, start: 100, end: 100) // zero duration

        let result = TimeAggregator.aggregate(entries: [e], projects: [p], now: t0)

        XCTAssertTrue(result.isEmpty)
    }

    func testNegativeDurationEntry_excluded() {
        let p = project(id: 1, name: "Work")
        let e = entry(projectId: 1, start: 200, end: 100) // end before start

        let result = TimeAggregator.aggregate(entries: [e], projects: [p], now: t0)

        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Accumulation

    func testMultipleEntries_sameProject_accumulates() {
        let p = project(id: 1, name: "Work")
        let e1 = entry(projectId: 1, start: 0, end: 1800)
        let e2 = entry(projectId: 1, start: 2000, end: 3800)

        let result = TimeAggregator.aggregate(entries: [e1, e2], projects: [p], now: t0)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].totalSeconds, 3600, accuracy: 0.001)
    }

    // MARK: - Deleted project fallback

    func testEntryReferencingUnknownProject_labeledDeletedProject() {
        let e = entry(projectId: 99, start: 0, end: 600)

        let result = TimeAggregator.aggregate(entries: [e], projects: [], now: t0)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].projectName, "Deleted project")
    }

    // MARK: - Sorting

    func testProjectsSortedByDurationDescending() {
        let p1 = project(id: 1, name: "Short")
        let p2 = project(id: 2, name: "Long")
        let short = entry(projectId: 1, start: 0, end: 60)
        let long = entry(projectId: 2, start: 0, end: 3600)

        let result = TimeAggregator.aggregate(entries: [short, long], projects: [p1, p2], now: t0)

        XCTAssertEqual(result[0].projectName, "Long")
        XCTAssertEqual(result[1].projectName, "Short")
    }

    // MARK: - Multiple projects

    func testTwoProjects_separateBuckets() throws {
        let p1 = project(id: 1, name: "Alpha")
        let p2 = project(id: 2, name: "Beta")
        let e1 = entry(projectId: 1, start: 0, end: 900)
        let e2 = entry(projectId: 2, start: 0, end: 1800)

        let result = TimeAggregator.aggregate(entries: [e1, e2], projects: [p1, p2], now: t0)

        XCTAssertEqual(result.count, 2)
        let totalMap = Dictionary(uniqueKeysWithValues: result.map { ($0.projectName, $0.totalSeconds) })
        let alpha = try XCTUnwrap(totalMap["Alpha"])
        let beta = try XCTUnwrap(totalMap["Beta"])
        XCTAssertEqual(alpha, 900, accuracy: 0.001)
        XCTAssertEqual(beta, 1800, accuracy: 0.001)
    }
}
