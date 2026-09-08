import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case blue, purple, green, orange, pink, red

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blue: return Color(hex: "#0091FF")
        case .purple: return Color(hex: "#A855F7")
        case .green: return Color(hex: "#22C55E")
        case .orange: return Color(hex: "#F97316")
        case .pink: return Color(hex: "#EC4899")
        case .red: return Color(hex: "#EF4444")
        }
    }

    var label: String {
        rawValue.capitalized
    }
}

/// Wraps @AppStorage's string persistence with a typed AppTheme accessor.
final class AppThemeStore: ObservableObject {
    static let shared = AppThemeStore()

    @Published var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "appTheme") }
    }

    private init() {
        let stored = UserDefaults.standard.string(forKey: "appTheme") ?? AppTheme.blue.rawValue
        theme = AppTheme(rawValue: stored) ?? .blue
    }
}
