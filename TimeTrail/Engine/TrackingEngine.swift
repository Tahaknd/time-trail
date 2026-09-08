import AppKit

/// Orchestrates automatic activity tracking. Must be started from the main thread.
/// All internal state is accessed only from the main thread (timer + workspace
/// notifications both deliver there), so no additional locking is needed.
final class TrackingEngine {
    private let repository: ActivitySegmentRepository
    private let idleMonitor: IdleMonitor
    private let accessibilityReader: AccessibilityReader

    private var currentSegment: ActivitySegment?
    private var isIdle = false
    private var pollTimer: Timer?

    private let pollInterval: TimeInterval = 5

    init(
        repository: ActivitySegmentRepository,
        idleMonitor: IdleMonitor = IdleMonitor(),
        accessibilityReader: AccessibilityReader = AccessibilityReader()
    ) {
        self.repository = repository
        self.idleMonitor = idleMonitor
        self.accessibilityReader = accessibilityReader
    }

    func start() {
        closeOrphanedSegments()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )

        pollTimer = Timer.scheduledTimer(
            withTimeInterval: pollInterval,
            repeats: true
        ) { [weak self] _ in
            self?.checkIdleState()
        }

        isIdle = idleMonitor.isIdle
        if !isIdle, let frontApp = NSWorkspace.shared.frontmostApplication {
            startSegment(for: frontApp)
        }
    }

    func stop() {
        closeCurrentSegment()
        pollTimer?.invalidate()
        pollTimer = nil
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    // MARK: - Private

    @objc private func appDidActivate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                as? NSRunningApplication
        else { return }

        // If idle, ignore app switches — a new segment starts when the user returns.
        guard !isIdle else { return }

        closeCurrentSegment()
        startSegment(for: app)
    }

    private func checkIdleState() {
        let wasIdle = isIdle
        isIdle = idleMonitor.isIdle

        if !wasIdle && isIdle {
            // Just became idle — seal the current segment.
            closeCurrentSegment()
        } else if wasIdle && !isIdle {
            // Just returned from idle — begin tracking the current frontmost app.
            if let frontApp = NSWorkspace.shared.frontmostApplication {
                startSegment(for: frontApp)
            }
        }
    }

    private func startSegment(for app: NSRunningApplication) {
        let windowTitle = accessibilityReader.windowTitle(for: app)
        var segment = ActivitySegment(
            id: nil,
            appBundleId: app.bundleIdentifier ?? "",
            appName: app.localizedName ?? "",
            windowTitle: windowTitle,
            startedAt: Date(),
            endedAt: nil
        )
        try? repository.insert(&segment)
        currentSegment = segment
    }

    private func closeCurrentSegment() {
        guard var segment = currentSegment else { return }
        segment.endedAt = Date()
        try? repository.update(segment)
        currentSegment = nil
    }

    /// Closes any segments left open from a previous session (e.g. after a crash).
    private func closeOrphanedSegments() {
        guard let open = try? repository.fetchOpen(), !open.isEmpty else { return }
        let now = Date()
        for segment in open {
            var closed = segment
            closed.endedAt = now
            try? repository.update(closed)
        }
    }
}
