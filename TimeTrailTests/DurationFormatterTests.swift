import XCTest
@testable import TimeTrail

final class DurationFormatterTests: XCTestCase {

    func testZeroSeconds_returnsZeroM() {
        XCTAssertEqual(DurationFormatter.format(0), "0m")
    }

    func testNegativeSeconds_treatedAsZero() {
        XCTAssertEqual(DurationFormatter.format(-60), "0m")
    }

    func testUnder60Seconds_returnsZeroM() {
        XCTAssertEqual(DurationFormatter.format(59), "0m")
    }

    func testExactlyOneMinute() {
        XCTAssertEqual(DurationFormatter.format(60), "1m")
    }

    func testJustUnderOneHour() {
        XCTAssertEqual(DurationFormatter.format(3599), "59m")
    }

    func testExactlyOneHour() {
        XCTAssertEqual(DurationFormatter.format(3600), "1h 0m")
    }

    func testOneHourThirtyMinutes() {
        XCTAssertEqual(DurationFormatter.format(5400), "1h 30m")
    }

    func testTwoHoursTwentyFourMinutes() {
        XCTAssertEqual(DurationFormatter.format(9240), "2h 34m")
    }

    func testLargeDuration() {
        XCTAssertEqual(DurationFormatter.format(8 * 3600 + 15 * 60), "8h 15m")
    }

    // MARK: - formatClock

    func testClock_zeroSeconds() {
        XCTAssertEqual(DurationFormatter.formatClock(0), "0:00")
    }

    func testClock_underOneMinute() {
        XCTAssertEqual(DurationFormatter.formatClock(45), "0:45")
    }

    func testClock_negativeTreatedAsZero() {
        XCTAssertEqual(DurationFormatter.formatClock(-10), "0:00")
    }

    func testClock_minutesAndSeconds() {
        XCTAssertEqual(DurationFormatter.formatClock(125), "2:05")
    }

    func testClock_exactlyOneHour() {
        XCTAssertEqual(DurationFormatter.formatClock(3600), "1:00:00")
    }

    func testClock_hoursMinutesSeconds() {
        XCTAssertEqual(DurationFormatter.formatClock(3661), "1:01:01")
    }
}
