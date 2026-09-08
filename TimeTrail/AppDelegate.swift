import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var trackingEngine: TrackingEngine?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupTrackingEngine()
    }

    func applicationWillTerminate(_ notification: Notification) {
        trackingEngine?.stop()
    }

    // MARK: - Private

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "clock", accessibilityDescription: "TimeTrail")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            withTitle: "Quit TimeTrail",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        statusItem?.menu = menu
    }

    private func setupTrackingEngine() {
        let db = DatabaseManager.shared.dbQueue
        let repository = ActivitySegmentRepository(db: db)
        let engine = TrackingEngine(repository: repository)
        engine.start()
        trackingEngine = engine
    }
}
