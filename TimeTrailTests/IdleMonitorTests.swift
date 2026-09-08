import XCTest
@testable import TimeTrail

struct MockIdleTimeProvider: IdleTimeProvider {
    var secondsSinceLastInput: TimeInterval
}

final class IdleMonitorTests: XCTestCase {

    // MARK: Default threshold

    func testDefaultThresholdIsThreeMinutes() {
        let monitor = IdleMonitor()
        XCTAssertEqual(monitor.threshold, 180)
    }

    // MARK: Threshold boundary

    func testNotIdleJustBelowThreshold() {
        let monitor = IdleMonitor(
            threshold: 180,
            provider: MockIdleTimeProvider(secondsSinceLastInput: 179.9)
        )
        XCTAssertFalse(monitor.isIdle)
    }

    func testIdleExactlyAtThreshold() {
        let monitor = IdleMonitor(
            threshold: 180,
            provider: MockIdleTimeProvider(secondsSinceLastInput: 180)
        )
        XCTAssertTrue(monitor.isIdle)
    }

    func testIdleAboveThreshold() {
        let monitor = IdleMonitor(
            threshold: 180,
            provider: MockIdleTimeProvider(secondsSinceLastInput: 600)
        )
        XCTAssertTrue(monitor.isIdle)
    }

    // MARK: Custom threshold

    func testCustomThresholdNotIdleBelowIt() {
        let monitor = IdleMonitor(
            threshold: 60,
            provider: MockIdleTimeProvider(secondsSinceLastInput: 59)
        )
        XCTAssertFalse(monitor.isIdle)
    }

    func testCustomThresholdIdleAtBoundary() {
        let monitor = IdleMonitor(
            threshold: 60,
            provider: MockIdleTimeProvider(secondsSinceLastInput: 60)
        )
        XCTAssertTrue(monitor.isIdle)
    }

    // MARK: Zero idle time (active user)

    func testZeroIdleTimeIsNotIdle() {
        let monitor = IdleMonitor(
            threshold: 180,
            provider: MockIdleTimeProvider(secondsSinceLastInput: 0)
        )
        XCTAssertFalse(monitor.isIdle)
    }

    // MARK: secondsSinceLastInput passthrough

    func testSecondsSinceLastInputReflectsProvider() {
        let monitor = IdleMonitor(
            threshold: 180,
            provider: MockIdleTimeProvider(secondsSinceLastInput: 42)
        )
        XCTAssertEqual(monitor.secondsSinceLastInput, 42)
    }

    // MARK: Very short threshold (stress)

    func testVeryShortThresholdTriggersImmediately() {
        let monitor = IdleMonitor(
            threshold: 0.1,
            provider: MockIdleTimeProvider(secondsSinceLastInput: 0.1)
        )
        XCTAssertTrue(monitor.isIdle)
    }

    func testVeryShortThresholdNotTriggeredWhenBelowIt() {
        let monitor = IdleMonitor(
            threshold: 0.1,
            provider: MockIdleTimeProvider(secondsSinceLastInput: 0.09)
        )
        XCTAssertFalse(monitor.isIdle)
    }
}
