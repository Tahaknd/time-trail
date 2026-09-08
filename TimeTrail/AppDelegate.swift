import AppKit
import SwiftUI
import GRDB

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?
    private var settingsWindowController: NSWindowController?
    private var reportsWindowController: NSWindowController?
    private var onboardingWindow: NSWindow?
    private var entryEditWindowController: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let db = DatabaseManager.shared.dbQueue
        statusItemController = StatusItemController(db: db)
        showOnboardingIfNeeded()

        NotificationCenter.default.addObserver(
            forName: EntryEditRequest.notificationName,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let entry = notification.userInfo?[EntryEditRequest.entryKey] as? TimeEntry
            let defaultProjectId = notification.userInfo?[EntryEditRequest.defaultProjectIdKey] as? Int64
            self?.openEntryEditor(entry: entry, defaultProjectId: defaultProjectId)
        }
    }

    // MARK: - Private

    private func showOnboardingIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: "didCompleteOnboarding") else { return }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 460),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to TimeTrail"
        window.isReleasedWhenClosed = false
        window.center()

        let onboardingView = OnboardingView {
            UserDefaults.standard.set(true, forKey: "didCompleteOnboarding")
            window.close()
        }
        window.contentView = NSHostingView(rootView: onboardingView)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindow = window
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
        let vm = SettingsViewModel(projectRepo: ProjectRepository(db: db))
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

    // MARK: Reports window

    @objc func openReports() {
        if reportsWindowController == nil {
            reportsWindowController = makeReportsWindowController()
        }
        NSApp.activate(ignoringOtherApps: true)
        reportsWindowController?.showWindow(nil)
    }

    private func makeReportsWindowController() -> NSWindowController {
        let db = DatabaseManager.shared.dbQueue
        let vm = ReportsViewModel(db: db)
        let rootView = ReportsView(viewModel: vm)
        let hostingController = NSHostingController(rootView: rootView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "TimeTrail Reports"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 700, height: 550))
        window.center()
        window.setFrameAutosaveName("com.timetrail.reportsWindow")

        return NSWindowController(window: window)
    }

    // MARK: Entry edit window

    private func openEntryEditor(entry: TimeEntry?, defaultProjectId: Int64?) {
        let db = DatabaseManager.shared.dbQueue
        let vm = EntryEditViewModel(db: db, entry: entry, defaultProjectId: defaultProjectId)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 260),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = entry == nil ? "New Entry" : "Edit Entry"
        window.isReleasedWhenClosed = false
        window.center()

        let rootView = EntryEditView(viewModel: vm) { [weak self] in
            window.close()
            self?.entryEditWindowController = nil
        }
        window.contentView = NSHostingView(rootView: rootView)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        entryEditWindowController = NSWindowController(window: window)
    }
}
