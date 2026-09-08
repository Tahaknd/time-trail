import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "clock.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("Welcome to TimeTrail")
                .font(.largeTitle.bold())

            Text("TimeTrail automatically tracks which apps you use and attributes your time to projects — no manual timers needed.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 380)

            VStack(alignment: .leading, spacing: 12) {
                featureRow(icon: "cpu", text: "Automatic tracking — no start/stop buttons")
                featureRow(icon: "folder", text: "Project tagging by app or window title")
                featureRow(icon: "chart.bar", text: "Daily and weekly reports with CSV export")
                featureRow(icon: "menubar.rectangle", text: "Lives in your menu bar — no dock icon")
            }

            Spacer()

            Button("Get Started") { onContinue() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(40)
        .frame(width: 480, height: 460)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.accentColor)
            Text(text)
                .font(.system(size: 13))
        }
    }
}
