import Foundation
import WidgetKit

/// Lightweight cross-process snapshot the main app writes and the widget
/// reads. The widget extension is sandboxed and can't open the app's
/// SQLite database directly, so the app pushes a small summary here
/// instead — via an App Group shared UserDefaults suite.
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
    private static let key = "widgetSnapshot"

    static func write(_ snapshot: WidgetSnapshot) {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = try? JSONEncoder().encode(snapshot)
        else { return }
        defaults.set(data, forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func read() -> WidgetSnapshot {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else { return .empty }
        return snapshot
    }
}
