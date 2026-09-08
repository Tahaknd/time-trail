import SwiftUI

/// A soft tinted circle behind an SF Symbol — used for empty states across
/// the app so they read as intentional illustration rather than a bare
/// system-gray icon.
struct EmptyStateBadge: View {
    let systemImage: String
    var color: Color = AppThemeStore.shared.theme.color

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.12))
                .frame(width: 72, height: 72)
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(color)
        }
    }
}
