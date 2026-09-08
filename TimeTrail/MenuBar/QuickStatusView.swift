import SwiftUI

/// Lightweight menu-bar quick-access content — the full timer + entries UI
/// lives in the main window; this is just start/stop + a shortcut to it.
struct QuickStatusView: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var pickedProjectId: Int64?
    let onOpenMainWindow: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let running = viewModel.runningEntry {
                HStack(spacing: 8) {
                    Circle()
                        .fill(projectColor(viewModel.projectColor(for: running.projectId)))
                        .frame(width: 8, height: 8)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(viewModel.projectName(for: running.projectId))
                            .font(.system(size: 12, weight: .medium))
                        TimelineView(.periodic(from: running.startedAt, by: 1)) { context in
                            Text(DurationFormatter.format(context.date.timeIntervalSince(running.startedAt)))
                                .font(.system(size: 11).monospacedDigit())
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Button("Stop") { viewModel.stopTimer() }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                }
            } else if viewModel.allProjects.isEmpty {
                Text("Add a project to get started")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            } else {
                HStack(spacing: 8) {
                    Menu {
                        ForEach(viewModel.allProjects, id: \.id) { project in
                            Button(project.name) { pickedProjectId = project.id }
                        }
                    } label: {
                        Text(pickedProjectId.map(viewModel.projectName) ?? "Select project")
                            .font(.system(size: 12))
                    }
                    .menuStyle(.borderlessButton)
                    Spacer()
                    Button("Start") {
                        guard let pickedProjectId else { return }
                        viewModel.startTimer(projectId: pickedProjectId)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(pickedProjectId == nil)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .onAppear {
            if pickedProjectId == nil {
                pickedProjectId = viewModel.allProjects.first?.id
            }
        }
        .frame(width: 240)
    }

    private func projectColor(_ hex: String?) -> Color {
        guard let hex, !hex.isEmpty else { return .secondary }
        return Color(hex: hex)
    }
}
