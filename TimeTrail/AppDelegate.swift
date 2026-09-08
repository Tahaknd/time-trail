import AppKit
import SwiftUI
import GRDB

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?
    private var onboardingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        let db = DatabaseManager.shared.dbQueue
        statusItemController = StatusItemController(db: db) { [weak self] in
            self?.openMainWindow()
        }
        showOnboardingIfNeeded()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            openMainWindow()
        }
        return true
    }

    // MARK: - Private

    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.isVisible || $0.canBecomeKey }) {
            window.makeKeyAndOrderFront(nil)
        }
    }

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
}
