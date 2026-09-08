import XCTest
@testable import TimeTrail

final class CSVExporterTests: XCTestCase {

    // Fixed reference epoch so date calculations are deterministic
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000) // 2023-11-14 22:13:20 UTC

    private func entry(
        projectId: Int64,
        description: String? = nil,
        start: TimeInterval,
        end: TimeInterval?
    ) -> TimeEntry {
        TimeEntry(
            id: nil,
            projectId: projectId,
            description: description,
            startedAt: t0.addingTimeInterval(start),
            endedAt: end.map { t0.addingTimeInterval($0) }
        )
    }

    private func project(id: Int64, name: String) -> Project {
        Project(id: id, name: name, color: "#FF0000")
    }

    // MARK: - Header

    func testCSVAlwaysHasHeader() {
        let csv = CSVExporter.build(entries: [], projects: [], now: t0)
        XCTAssertTrue(csv.hasPrefix("date,project,description,duration_seconds\n"))
    }

    // MARK: - Empty input

    func testEmpty_onlyHeader() {
        let csv = CSVExporter.build(entries: [], projects: [], now: t0)
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }
        XCTAssertEqual(lines.count, 1) // header only
    }

    // MARK: - Single entry

    func testSingleEntry_correctFields() {
        let p = project(id: 1, name: "Work")
        let e = entry(projectId: 1, description: "Writing docs", start: 0, end: 3600)

        let rows = CSVExporter.buildRows(entries: [e], projects: [p], now: t0)

        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].project, "Work")
        XCTAssertEqual(rows[0].description, "Writing docs")
        XCTAssertEqual(rows[0].durationSeconds, 3600)
    }

    func testEntryReferencingDeletedProject() {
        let e = entry(projectId: 99, start: 0, end: 600)

        let rows = CSVExporter.buildRows(entries: [e], projects: [], now: t0)

        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].project, "Deleted project")
        XCTAssertEqual(rows[0].durationSeconds, 600)
    }

    // MARK: - Duration calculation

    func testZeroDurationEntry_excluded() {
        let p = project(id: 1, name: "Work")
        let e = entry(projectId: 1, start: 100, end: 100) // zero duration
        let rows = CSVExporter.buildRows(entries: [e], projects: [p], now: t0)
        XCTAssertTrue(rows.isEmpty)
    }

    func testOpenEntry_usesNow() {
        let p = project(id: 1, name: "Work")
        let e = entry(projectId: 1, start: 0, end: nil)
        let now = t0.addingTimeInterval(1800)
        let rows = CSVExporter.buildRows(entries: [e], projects: [p], now: now)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].durationSeconds, 1800)
    }

    // MARK: - Aggregation

    func testSameProjectAndDescription_accumulated() {
        let p = project(id: 1, name: "Work")
        let e1 = entry(projectId: 1, description: "Writing docs", start: 0, end: 1800)
        let e2 = entry(projectId: 1, description: "Writing docs", start: 2000, end: 3800)

        let rows = CSVExporter.buildRows(entries: [e1, e2], projects: [p], now: t0)

        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].durationSeconds, 3600)
    }

    func testDifferentDescriptions_separateRows() {
        let p = project(id: 1, name: "Work")
        let e1 = entry(projectId: 1, description: "Task A", start: 0, end: 900)
        let e2 = entry(projectId: 1, description: "Task B", start: 0, end: 1800)

        let rows = CSVExporter.buildRows(entries: [e1, e2], projects: [p], now: t0)

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

    func testCSVString_hasOneDataRowForOneEntry() {
        let p = project(id: 1, name: "Work")
        let e = entry(projectId: 1, description: "Writing docs", start: 0, end: 300)

        let csv = CSVExporter.build(entries: [e], projects: [p], now: t0)
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }

        XCTAssertEqual(lines.count, 2) // header + 1 data row
        XCTAssertTrue(lines[1].contains("Work"))
        XCTAssertTrue(lines[1].contains("Writing docs"))
        XCTAssertTrue(lines[1].contains("300"))
    }
}
