import Foundation

/// Posted by the menu-bar dropdown to ask AppDelegate to open the entry
/// editor window — decouples the SwiftUI menu content (hosted inside an
/// NSMenuItem, not a real window) from window management.
enum EntryEditRequest {
    static let notificationName = Notification.Name("EntryEditRequest")
    static let entryKey = "entry"
    static let defaultProjectIdKey = "defaultProjectId"

    static func post(entry: TimeEntry?, defaultProjectId: Int64?) {
        var userInfo: [String: Any] = [:]
        if let entry { userInfo[entryKey] = entry }
        if let defaultProjectId { userInfo[defaultProjectIdKey] = defaultProjectId }
        NotificationCenter.default.post(name: notificationName, object: nil, userInfo: userInfo)
    }
}
