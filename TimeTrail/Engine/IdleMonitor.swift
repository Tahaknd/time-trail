import CoreGraphics
import Foundation

protocol IdleTimeProvider {
    var secondsSinceLastInput: TimeInterval { get }
}

/// Uses CGEventSource to measure real system idle time.
struct CGIdleTimeProvider: IdleTimeProvider {
    var secondsSinceLastInput: TimeInterval {
        // Take the minimum across relevant input event types so that
        // ANY recent input (mouse, keyboard, scroll) resets the idle clock.
        let types: [CGEventType] = [
            .mouseMoved, .leftMouseDown, .leftMouseUp,
            .rightMouseDown, .rightMouseUp, .otherMouseDown,
            .keyDown, .keyUp, .scrollWheel,
        ]
        return types
            .map { CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: $0) }
            .min() ?? 0
    }
}

final class IdleMonitor {
    let threshold: TimeInterval
    private let provider: IdleTimeProvider

    init(threshold: TimeInterval = 180, provider: IdleTimeProvider = CGIdleTimeProvider()) {
        self.threshold = threshold
        self.provider = provider
    }

    var isIdle: Bool {
        provider.secondsSinceLastInput >= threshold
    }

    var secondsSinceLastInput: TimeInterval {
        provider.secondsSinceLastInput
    }
}
