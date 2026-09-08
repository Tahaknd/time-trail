# Context Packet ctxpkt_8e81d57a67327ecacc76

- Title: Activity tracking engine
- Source Type: dependency_output
- Source Key: t_1788856096952_td3osl
- Content Type: markdown
- Strategy: markdown_focus
- Original Tokens: 428
- Compact Tokens: 244

## Original Content
All 27 tests pass. Here's what was built:

---

## Summary

**Files created:**

| File | Purpose |
|---|---|
| `TimeTrail/Engine/IdleMonitor.swift` | `IdleTimeProvider` protocol + `CGIdleTimeProvider` (real) + `IdleMonitor` class with injectable threshold |
| `TimeTrail/Engine/AccessibilityReader.swift` | Reads focused window title via `AXUIElement`; returns `nil` silently if Accessibility permission is absent |
| `TimeTrail/Engine/TrackingEngine.swift` | Core background service: app-switch listener, 5s idle poll, segment open/close logic, orphan cleanup on startup |
| `TimeTrailTests/IdleMonitorTests.swift` | 10 unit tests for threshold boundary, custom threshold, zero-idle, and provider passthrough |
| `TimeTrail/AppDelegate.swift` (updated) | Wires `TrackingEngine` into `applicationDidFinishLaunching` / `applicationWillTerminate` |

**Key design decisions:**

- **`IdleTimeProvider` protocol**: Decouples `IdleMonitor` from `CGEventSource` so tests run without a real HID session using a simple `MockIdleTimeProvider(secondsSinceLastInput:)`.
- **Idle polling at 5s**: Accurate enough for 3-minute thresholds, negligible CPU cost.
- **App switches while idle are ignored**: The engine only starts a new segment after the idle poll confirms the user has returned, using whatever app is frontmost at that moment.
- **Orphan cleanup**: On startup, any open segments from a previous crashed session are closed at `now`, preventing unbounded open segments accumulating in the database.
- **Accessibility permission is optional**: `AccessibilityReader` checks `AXIsProcessTrusted()` first and returns `nil` for `windowTitle` if not granted — the engine still records `appBundleId`/`appName` correctly.
