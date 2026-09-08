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

        // Refresh the status-item title every 30 s even when the menu is closed.
        titleRefreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.viewModel.refresh()
            self?.updateButtonTitle()
        }
    }

    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        viewModel.refresh()
        updateButtonTitle()
        menuRefreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
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

        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(contentItem)
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Quit TimeTrail",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )

        statusItem.menu = menu
    }

    private func updateButtonTitle() {
        guard let button = statusItem.button else { return }
        button.title = " \(DurationFormatter.format(viewModel.totalSeconds))"
        button.image = NSImage(systemSymbolName: "clock.fill", accessibilityDescription: "TimeTrail")
        button.imagePosition = .imageLeft
    }
}
