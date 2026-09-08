import AppKit
import SwiftUI
import GRDB

/// Owns the NSStatusItem and drives menu-bar display.
/// Must be created on the main thread; all methods are main-thread-only.
final class StatusItemController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let viewModel: MenuBarViewModel
    private let hosting: NSHostingView<MenuBarView>
    private var menuRefreshTimer: Timer?
    private var titleRefreshTimer: Timer?

    init(db: DatabaseQueue) {
        viewModel = MenuBarViewModel(db: db)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        hosting = NSHostingView(rootView: MenuBarView(viewModel: viewModel))
        super.init()

        hosting.sizingOptions = .intrinsicContentSize

        setupMenu()
        viewModel.refresh()
        updateButtonTitle()
        scheduleTitleRefresh()
    }

    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        viewModel.refresh()
        updateButtonTitle()
        menuRefreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.viewModel.refresh()
            self?.updateButtonTitle()
        }
    }

    func menuDidClose(_ menu: NSMenu) {
        menuRefreshTimer?.invalidate()
        menuRefreshTimer = nil
    }

    // MARK: - Private

    private func setupMenu() {
        let contentItem = NSMenuItem()
        contentItem.view = hosting

        // nil target routes through the responder chain to AppDelegate.openReports/openSettings
        let reportsItem = NSMenuItem(
            title: "Reports\u{2026}",
            action: NSSelectorFromString("openReports"),
            keyEquivalent: "r"
        )

        let settingsItem = NSMenuItem(
            title: "Settings\u{2026}",
            action: NSSelectorFromString("openSettings"),
            keyEquivalent: ","
        )

        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(contentItem)
        menu.addItem(.separator())
        menu.addItem(reportsItem)
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Quit TimeTrail",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )

        statusItem.menu = menu
    }

    /// Ticks every second while a timer is running (for a live-updating
    /// status-item title) and falls back to a slow 30 s cadence otherwise.
    private func scheduleTitleRefresh() {
        titleRefreshTimer?.invalidate()
        let interval: TimeInterval = viewModel.runningEntry != nil ? 1 : 30
        titleRefreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.viewModel.refresh()
            self.updateButtonTitle()
            self.scheduleTitleRefresh()
        }
    }

    private func updateButtonTitle() {
        guard let button = statusItem.button else { return }
        if let running = viewModel.runningEntry {
            let elapsed = Date().timeIntervalSince(running.startedAt)
            button.title = " \(DurationFormatter.format(elapsed))"
            button.image = NSImage(systemSymbolName: "record.circle.fill", accessibilityDescription: "TimeTrail — running")
        } else {
            button.title = " \(DurationFormatter.format(viewModel.totalSecondsToday))"
            button.image = NSImage(systemSymbolName: "clock.fill", accessibilityDescription: "TimeTrail")
        }
        button.imagePosition = .imageLeft
    }
}
