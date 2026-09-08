import AppKit
import SwiftUI
import GRDB

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?
    private var trackingEngine: TrackingEngine?
    private var settingsWindowController: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let db = DatabaseManager.shared.dbQueue
        statusItemController = StatusItemController(db: db)
        setupTrackingEngine(db: db)
    }

    func applicationWillTerminate(_ notification: Notification) {
        trackingEngine?.stop()
    }

    // MARK: - Private

    private func setupTrackingEngine(db: DatabaseQueue) {
        let repository = ActivitySegmentRepository(db: db)
        let engine = TrackingEngine(repository: repository)
        engine.start()
        trackingEngine = engine
    }

    // MARK: Settings window

    @objc func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = makeSettingsWindowController()
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindowController?.showWindow(nil)
    }

    private func makeSettingsWindowController() -> NSWindowController {
        let db = DatabaseManager.shared.dbQueue
        let vm = SettingsViewModel(
            projectRepo: ProjectRepository(db: db),
            ruleRepo: ProjectRuleRepository(db: db)
        )
        let rootView = SettingsView(viewModel: vm)
        let hostingController = NSHostingController(rootView: rootView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "TimeTrail Settings"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 720, height: 500))
        window.center()
        window.setFrameAutosaveName("com.timetrail.settingsWindow")

        return NSWindowController(window: window)
    }
}
