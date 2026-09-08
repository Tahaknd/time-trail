import AppKit
import SwiftUI

struct AccessibilityPermissionView: View {
    @ObservedObject var checker: AccessibilityPermissionChecker
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: checker.isGranted ? "checkmark.shield.fill" : "lock.shield")
                .font(.system(size: 64))
                .foregroundStyle(checker.isGranted ? Color.green : Color.orange)
                .animation(.default, value: checker.isGranted)

            Text("Accessibility Access")
                .font(.title.bold())

            Text("TimeTrail needs Accessibility access to read window titles for accurate project tagging. Without it, tracking still works — but only matches by app name.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 380)

            if !checker.isGranted {
                Button("Open System Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()

            Button("Continue") { onContinue() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!checker.isGranted)
        }
        .padding(40)
        .frame(width: 480, height: 400)
    }
}
