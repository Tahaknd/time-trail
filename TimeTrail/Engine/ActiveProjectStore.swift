import Foundation

/// Holds the user's manual "I'm working on this project right now" override.
/// When set, new activity segments are stamped with this project directly,
/// bypassing rule matching — for apps used across multiple projects (e.g. a
/// terminal or chat client) where app/window-title rules can't disambiguate.
final class ActiveProjectStore {
    static let shared = ActiveProjectStore()

    static let didChangeNotification = Notification.Name("ActiveProjectStore.didChange")

    private let defaultsKey = "activeOverrideProjectId"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var currentProjectId: Int64? {
        get {
            let value = defaults.integer(forKey: defaultsKey)
            return value == 0 ? nil : Int64(value)
        }
        set {
            if let newValue {
                defaults.set(Int(newValue), forKey: defaultsKey)
            } else {
                defaults.removeObject(forKey: defaultsKey)
            }
            NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
        }
    }
}
