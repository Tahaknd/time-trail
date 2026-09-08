import Foundation
import WidgetKit

/// Lightweight cross-process snapshot the main app writes and the widget
/// reads. The widget extension is sandboxed and can't open the app's
/// SQLite database directly, so the app pushes a small summary here
/// instead — as a JSON file in the shared App Group container.
struct WidgetSnapshot: Codable {
    struct ProjectTotal: Codable {
        let name: String
        let colorHex: String
        let seconds: TimeInterval
    }

    var runningProjectName: String?
    var runningProjectColorHex: String?
    var runningStartedAt: Date?
    var todayTotalSeconds: TimeInterval
    var topProjectsToday: [ProjectTotal]
    var updatedAt: Date

    static let empty = WidgetSnapshot(
        runningProjectName: nil,
        runningProjectColorHex: nil,
        runningStartedAt: nil,
        todayTotalSeconds: 0,
        topProjectsToday: [],
        updatedAt: Date()
    )
}

enum WidgetSnapshotStore {
    static let appGroupID = "group.com.timetrail.shared"
    private static let fileName = "widget-snapshot.json"

    /// The main app is deliberately NOT sandboxed (to keep its existing SQLite
    /// DB path), while the widget extension IS sandboxed. UserDefaults(suiteName:)
    /// depends on both sides agreeing on the same sandbox container conventions,
    /// which breaks down across that asymmetry — the main app's writes can
    /// silently fail to land where the widget reads from. Writing directly to
    /// the App Group's shared container directory works for both sandboxed and
    /// non-sandboxed processes as long as they hold the entitlement, so it's
    /// used here instead.
    private static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(fileName)
    }

    static func write(_ snapshot: WidgetSnapshot) {
        // Under XCTest the host app launches via testmanagerd instead of a
        // normal install, and touching the App Group container there has
        // previously caused indefinite hangs before the test runner could
        // connect. Widget syncing is meaningless during tests anyway, so
        // skip it entirely.
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }

        guard let url = fileURL, let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: url, options: .atomic)
        DispatchQueue.global(qos: .utility).async {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    static func read() -> WidgetSnapshot {
        guard let url = fileURL,
              let data = try? Data(contentsOf: url),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else { return .empty }
        return snapshot
    }
}
