import SwiftUI

/// Deterministic color for a tag name — the same tag always renders with
/// the same color everywhere in the app, without needing to store one.
enum TagColor {
    private static let palette: [String] = [
        "#F97316", // orange
        "#22C55E", // green
        "#3B82F6", // blue
        "#A855F7", // purple
        "#EC4899", // pink
        "#EAB308", // yellow
        "#14B8A6", // teal
        "#EF4444", // red
    ]

    static func color(for tag: String) -> Color {
        var hash = 0
        for scalar in tag.unicodeScalars { hash = 31 &* hash &+ Int(scalar.value) }
        let index = abs(hash) % palette.count
        return Color(hex: palette[index])
    }
}

struct TagChip: View {
    let tag: String

    var body: some View {
        Text(tag)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(TagColor.color(for: tag))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(TagColor.color(for: tag).opacity(0.15))
            .clipShape(Capsule())
    }
}
