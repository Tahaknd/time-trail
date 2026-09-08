import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var settingsWindowController: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
    }

    // MARK: Status item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "clock", accessibilityDescription: "TimeTrail")
        }

        let menu = NSMenu()
        menu.addItem(
            withTitle: "Settings\u{2026}",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        menu.addItem(NSMenuItem.separator())
        menu.addItem(
            withTitle: "Quit TimeTrail",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        statusItem?.menu = menu
    }

    // MARK: Settings window

    @objc private func openSettings() {
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
