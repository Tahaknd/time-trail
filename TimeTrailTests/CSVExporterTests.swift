import XCTest
@testable import TimeTrail

final class CSVExporterTests: XCTestCase {

    // Fixed reference epoch so date calculations are deterministic
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000) // 2023-11-14 22:13:20 UTC

    private func seg(
        bundleId: String = "com.example.app",
        appName: String = "TestApp",
        windowTitle: String? = nil,
        start: TimeInterval,
        end: TimeInterval?,
        overrideProjectId: Int64? = nil
    ) -> ActivitySegment {
        ActivitySegment(
            id: nil,
            appBundleId: bundleId,
            appName: appName,
            windowTitle: windowTitle,
            startedAt: t0.addingTimeInterval(start),
            endedAt: end.map { t0.addingTimeInterval($0) },
            overrideProjectId: overrideProjectId
        )
    }

    private func project(id: Int64, name: String) -> Project {
        Project(id: id, name: name, color: "#FF0000")
    }

    private func rule(projectId: Int64, bundleId: String, keyword: String? = nil) -> ProjectRule {
        ProjectRule(id: nil, projectId: projectId, appBundleId: bundleId, windowTitleKeyword: keyword)
    }

    // MARK: - Header

    func testCSVAlwaysHasHeader() {
        let csv = CSVExporter.build(segments: [], rules: [], projects: [], now: t0)
        XCTAssertTrue(csv.hasPrefix("date,project,app,duration_seconds\n"))
    }

    // MARK: - Empty input

    func testEmpty_onlyHeader() {
        let csv = CSVExporter.build(segments: [], rules: [], projects: [], now: t0)
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }
        XCTAssertEqual(lines.count, 1) // header only
    }

    // MARK: - Single segment

    func testSingleAssignedSegment_correctFields() {
        let p = project(id: 1, name: "Work")
        let r = rule(projectId: 1, bundleId: "com.example.app")
        let s = seg(appName: "TestApp", start: 0, end: 3600)

        let rows = CSVExporter.buildRows(segments: [s], rules: [r], projects: [p], now: t0)

        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].project, "Work")
        XCTAssertEqual(rows[0].app, "TestApp")
        XCTAssertEqual(rows[0].durationSeconds, 3600)
    }

    func testSingleUnassignedSegment_projectIsUnassigned() {
        let s = seg(appName: "UnknownApp", start: 0, end: 600)

        let rows = CSVExporter.buildRows(segments: [s], rules: [], projects: [], now: t0)

        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].project, "Unassigned")
        XCTAssertEqual(rows[0].durationSeconds, 600)
    }

    // MARK: - Duration calculation

    func testZeroDurationSegment_excluded() {
        let s = seg(start: 100, end: 100) // zero duration
        let rows = CSVExporter.buildRows(segments: [s], rules: [], projects: [], now: t0)
        XCTAssertTrue(rows.isEmpty)
    }

    func testOpenSegment_usesNow() {
        let s = seg(start: 0, end: nil)
        let now = t0.addingTimeInterval(1800)
        let rows = CSVExporter.buildRows(segments: [s], rules: [], projects: [], now: now)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].durationSeconds, 1800)
    }

    // MARK: - Aggregation

    func testSameProjectAndApp_accumulated() {
        let p = project(id: 1, name: "Work")
        let r = rule(projectId: 1, bundleId: "com.example.app")
        let s1 = seg(appName: "TestApp", start: 0, end: 1800)
        let s2 = seg(appName: "TestApp", start: 2000, end: 3800)

        let rows = CSVExporter.buildRows(segments: [s1, s2], rules: [r], projects: [p], now: t0)

        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].durationSeconds, 3600)
    }

    func testDifferentApps_separateRows() {
        let p = project(id: 1, name: "Work")
        let r1 = rule(projectId: 1, bundleId: "com.example.app1")
        let r2 = rule(projectId: 1, bundleId: "com.example.app2")
        let s1 = seg(bundleId: "com.example.app1", appName: "App1", start: 0, end: 900)
        let s2 = seg(bundleId: "com.example.app2", appName: "App2", start: 0, end: 1800)

        let rows = CSVExporter.buildRows(segments: [s1, s2], rules: [r1, r2], projects: [p], now: t0)

        XCTAssertEqual(rows.count, 2)
    }

    // MARK: - RFC 4180 escaping

    func testEscape_plain_unchanged() {
        XCTAssertEqual(CSVExporter.escape("HelloWorld"), "HelloWorld")
    }

    func testEscape_comma_wrapped() {
        XCTAssertEqual(CSVExporter.escape("Hello, World"), "\"Hello, World\"")
    }

    func testEscape_quote_doubled() {
        XCTAssertEqual(CSVExporter.escape("say \"hi\""), "\"say \"\"hi\"\"\"")
    }

    func testEscape_newline_wrapped() {
        XCTAssertEqual(CSVExporter.escape("line1\nline2"), "\"line1\nline2\"")
    }

    // MARK: - CSV string correctness

    func testCSVString_hasOneDataRowForOneSegment() {
        let p = project(id: 1, name: "Work")
        let r = rule(projectId: 1, bundleId: "com.example.app")
        let s = seg(appName: "TestApp", start: 0, end: 300)

        let csv = CSVExporter.build(segments: [s], rules: [r], projects: [p], now: t0)
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }

        XCTAssertEqual(lines.count, 2) // header + 1 data row
        XCTAssertTrue(lines[1].contains("Work"))
        XCTAssertTrue(lines[1].contains("TestApp"))
        XCTAssertTrue(lines[1].contains("300"))
    }

    // MARK: - Manual project override

    func testOverrideProjectId_winsOverRuleMatch() {
        let ruleProject = project(id: 1, name: "RuleMatched")
        let overrideProject = project(id: 2, name: "ManuallyPicked")
        let r = rule(projectId: 1, bundleId: "com.example.app")
        let s = seg(start: 0, end: 600, overrideProjectId: 2)

        let rows = CSVExporter.buildRows(
            segments: [s],
            rules: [r],
            projects: [ruleProject, overrideProject],
            now: t0
        )

        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].project, "ManuallyPicked")
    }
}
