import AppKit
import ApplicationServices

final class AccessibilityReader {
    /// Returns the focused window title for the given application, or nil if
    /// accessibility permission is not granted or the app doesn't expose a title.
    func windowTitle(for app: NSRunningApplication) -> String? {
        guard AXIsProcessTrusted() else { return nil }

        let pid = app.processIdentifier
        guard pid > 0 else { return nil }

        let axApp = AXUIElementCreateApplication(pid)

        var focusedWindowRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            axApp,
            kAXFocusedWindowAttribute as CFString,
            &focusedWindowRef
        ) == .success, let focusedWindowRef else {
            return nil
        }

        // kAXFocusedWindowAttribute always yields an AXUIElement on success.
        let window = focusedWindowRef as! AXUIElement

        var titleRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            window,
            kAXTitleAttribute as CFString,
            &titleRef
        ) == .success,
            let title = titleRef as? String,
            !title.isEmpty
        else {
            return nil
        }

        return title
    }
}
