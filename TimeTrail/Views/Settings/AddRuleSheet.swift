import SwiftUI
import AppKit

// MARK: - Model

struct RunningApp: Identifiable {
    let id: String      // bundle identifier
    let name: String
    let icon: NSImage?

    static func fetchCurrentlyRunning() -> [RunningApp] {
        var seen = Set<String>()
        return NSWorkspace.shared.runningApplications
            .compactMap { app -> RunningApp? in
                guard let bundleId = app.bundleIdentifier,
                      let name = app.localizedName,
                      app.activationPolicy == .regular,
                      seen.insert(bundleId).inserted
                else { return nil }
                return RunningApp(id: bundleId, name: name, icon: app.icon)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

// MARK: - Sheet view

struct AddRuleSheet: View {
    let projectId: Int64
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var useManualBundleId = false
    @State private var manualBundleId = ""
    @State private var selectedBundleId = ""
    @State private var windowKeyword = ""
    @State private var runningApps: [RunningApp] = []

    private var effectiveBundleId: String {
        useManualBundleId ? manualBundleId : selectedBundleId
    }

    private var canAdd: Bool {
        !effectiveBundleId.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Add Rule")
                .font(.headline)
                .padding(.top, 20)
                .padding(.bottom, 4)

            Text("Map an app to this project by its bundle ID. Optionally filter by window title.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 12)

            Form {
                Section("App") {
                    Toggle("Enter bundle ID manually", isOn: $useManualBundleId)

                    if useManualBundleId {
                        TextField("com.example.MyApp", text: $manualBundleId)
                    } else {
                        appPicker
                    }
                }

                Section {
                    TextField("e.g. Invoice, GitHub, Figma", text: $windowKeyword)
                } header: {
                    Text("Window title keyword (optional)")
                } footer: {
                    Text("Leave blank to match any window for the selected app.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Add Rule") {
                    viewModel.addRule(
                        projectId: projectId,
                        bundleId: effectiveBundleId,
                        keyword: windowKeyword.isEmpty ? nil : windowKeyword
                    )
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canAdd)
            }
            .padding()
        }
        .frame(width: 420, height: 400)
        .onAppear {
            runningApps = RunningApp.fetchCurrentlyRunning()
            if let first = runningApps.first {
                selectedBundleId = first.id
            }
        }
    }

    @ViewBuilder
    private var appPicker: some View {
        if runningApps.isEmpty {
            Text("No regular apps currently running.")
                .foregroundStyle(.secondary)
        } else {
            Picker("Running app", selection: $selectedBundleId) {
                ForEach(runningApps) { app in
                    HStack(spacing: 6) {
                        if let icon = app.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 16, height: 16)
                        }
                        Text(app.name)
                        Text("(\(app.id))")
                            .foregroundStyle(.secondary)
                    }
                    .tag(app.id)
                }
            }
        }
    }
}
