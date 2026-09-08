import XCTest
@testable import TimeTrail

final class TimeAggregatorTests: XCTestCase {

    // MARK: - Helpers

    private let t0 = Date(timeIntervalSinceReferenceDate: 0)

    private func seg(
        bundleId: String = "com.example.app",
        windowTitle: String? = nil,
        start: TimeInterval,
        end: TimeInterval?
    ) -> ActivitySegment {
        ActivitySegment(
            id: nil,
            appBundleId: bundleId,
            appName: "App",
            windowTitle: windowTitle,
            startedAt: t0.addingTimeInterval(start),
            endedAt: end.map { t0.addingTimeInterval($0) }
        )
    }

    private func project(id: Int64, name: String, color: String = "#AABBCC") -> Project {
        Project(id: id, name: name, color: color)
    }

    private func rule(projectId: Int64, bundleId: String, keyword: String? = nil) -> ProjectRule {
        ProjectRule(id: nil, projectId: projectId, appBundleId: bundleId, windowTitleKeyword: keyword)
    }

    // MARK: - Empty input

    func testEmpty_returnsEmpty() {
        let result = TimeAggregator.aggregate(segments: [], rules: [], projects: [], now: t0)
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Duration calculation

    func testClosedSegment_correctDuration() {
        let p = project(id: 1, name: "Work")
        let r = rule(projectId: 1, bundleId: "com.example.app")
        let s = seg(start: 0, end: 3600)

        let result = TimeAggregator.aggregate(segments: [s], rules: [r], projects: [p], now: t0)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].totalSeconds, 3600, accuracy: 0.001)
    }

    func testOpenSegment_usesNow() {
        let p = project(id: 1, name: "Work")
        let r = rule(projectId: 1, bundleId: "com.example.app")
        let s = seg(start: 0, end: nil)
        let now = t0.addingTimeInterval(1800)

        let result = TimeAggregator.aggregate(segments: [s], rules: [r], projects: [p], now: now)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].totalSeconds, 1800, accuracy: 0.001)
    }

    func testZeroDurationClosedSegment_excluded() {
        let p = project(id: 1, name: "Work")
        let r = rule(projectId: 1, bundleId: "com.example.app")
        let s = seg(start: 100, end: 100) // zero duration

        let result = TimeAggregator.aggregate(segments: [s], rules: [r], projects: [p], now: t0)

        XCTAssertTrue(result.isEmpty)
    }

    func testNegativeDurationSegment_excluded() {
        let p = project(id: 1, name: "Work")
        let r = rule(projectId: 1, bundleId: "com.example.app")
        let s = seg(start: 200, end: 100) // end before start

        let result = TimeAggregator.aggregate(segments: [s], rules: [r], projects: [p], now: t0)

        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Accumulation

    func testMultipleSegments_sameBucket_accumulates() {
        let p = project(id: 1, name: "Work")
        let r = rule(projectId: 1, bundleId: "com.example.app")
        let s1 = seg(start: 0, end: 1800)
        let s2 = seg(start: 2000, end: 3800)

        let result = TimeAggregator.aggregate(segments: [s1, s2], rules: [r], projects: [p], now: t0)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].totalSeconds, 3600, accuracy: 0.001)
    }

    // MARK: - Unassigned bucket

    func testUnmatchedSegment_goesToUnassigned() {
        let s = seg(bundleId: "com.other.app", start: 0, end: 600)

        let result = TimeAggregator.aggregate(segments: [s], rules: [], projects: [], now: t0)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].projectName, "Unassigned")
        XCTAssertNil(result[0].projectId)
    }

    func testUnassignedAppearsAfterAssignedProjects() {
        let p = project(id: 1, name: "Work")
        let r = rule(projectId: 1, bundleId: "com.example.app")
        let assigned = seg(bundleId: "com.example.app", start: 0, end: 100)
        let unassigned = seg(bundleId: "com.other.app", start: 0, end: 100)

        let result = TimeAggregator.aggregate(
            segments: [assigned, unassigned],
            rules: [r],
            projects: [p],
            now: t0
        )

        XCTAssertEqual(result.count, 2)
        XCTAssertNotNil(result[0].projectId)
        XCTAssertNil(result[1].projectId)
    }

    // MARK: - Sorting

    func testProjectsSortedByDurationDescending() {
        let p1 = project(id: 1, name: "Short")
        let p2 = project(id: 2, name: "Long")
        let r1 = rule(projectId: 1, bundleId: "com.short.app")
        let r2 = rule(projectId: 2, bundleId: "com.long.app")
        let short = seg(bundleId: "com.short.app", start: 0, end: 60)
        let long = seg(bundleId: "com.long.app", start: 0, end: 3600)

        let result = TimeAggregator.aggregate(
            segments: [short, long],
            rules: [r1, r2],
            projects: [p1, p2],
            now: t0
        )

        XCTAssertEqual(result[0].projectName, "Long")
        XCTAssertEqual(result[1].projectName, "Short")
    }

    // MARK: - Multiple projects

    func testTwoProjects_separateBuckets() throws {
        let p1 = project(id: 1, name: "Alpha")
        let p2 = project(id: 2, name: "Beta")
        let r1 = rule(projectId: 1, bundleId: "com.alpha.app")
        let r2 = rule(projectId: 2, bundleId: "com.beta.app")
        let s1 = seg(bundleId: "com.alpha.app", start: 0, end: 900)
        let s2 = seg(bundleId: "com.beta.app", start: 0, end: 1800)

        let result = TimeAggregator.aggregate(
            segments: [s1, s2],
            rules: [r1, r2],
            projects: [p1, p2],
            now: t0
        )

        XCTAssertEqual(result.count, 2)
        let totalMap = Dictionary(uniqueKeysWithValues: result.map { ($0.projectName, $0.totalSeconds) })
        let alpha = try XCTUnwrap(totalMap["Alpha"])
        let beta = try XCTUnwrap(totalMap["Beta"])
        XCTAssertEqual(alpha, 900, accuracy: 0.001)
        XCTAssertEqual(beta, 1800, accuracy: 0.001)
    }
}
