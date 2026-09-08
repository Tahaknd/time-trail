import SwiftUI

struct AppSettingsTabView: View {
    @ObservedObject var themeStore: AppThemeStore

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Accent Color")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            ForEach(AppTheme.allCases) { theme in
                                Button {
                                    themeStore.theme = theme
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(theme.color)
                                            .frame(width: 28, height: 28)
                                        if themeStore.theme == theme {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .help(theme.label)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
    }
}
