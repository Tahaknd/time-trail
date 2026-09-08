import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: MenuBarViewModel
    @State private var pickedProjectId: Int64?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow
            Divider().padding(.horizontal, 8)
            timerRow
            Divider().padding(.horizontal, 8)
            entryList
            Divider().padding(.horizontal, 8)
            manualEntryRow
        }
        .frame(width: 280)
        .padding(.vertical, 4)
        .onAppear {
            if pickedProjectId == nil {
                pickedProjectId = viewModel.allProjects.first?.id
            }
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text("Today")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            Text(DurationFormatter.format(viewModel.totalSecondsToday))
                .font(.system(size: 13, weight: .semibold).monospacedDigit())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Timer control

    @ViewBuilder
    private var timerRow: some View {
        if let running = viewModel.runningEntry {
            HStack(spacing: 8) {
                Circle()
                    .fill(projectColor(viewModel.projectColor(for: running.projectId)))
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 1) {
                    Text(viewModel.projectName(for: running.projectId))
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
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
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
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
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Today's entries

    @ViewBuilder
    private var entryList: some View {
        let completed = viewModel.todayEntries.filter { $0.endedAt != nil }
        if completed.isEmpty {
            Text("No entries yet today")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
        } else {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(completed, id: \.id) { entry in
                        entryRow(entry)
                    }
                }
            }
            .frame(maxHeight: 180)
        }
    }

    private func entryRow(_ entry: TimeEntry) -> some View {
        Button {
            EntryEditRequest.post(entry: entry, defaultProjectId: nil)
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(projectColor(viewModel.projectColor(for: entry.projectId)))
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 1) {
                    Text(viewModel.projectName(for: entry.projectId))
                        .font(.system(size: 12))
                        .lineLimit(1)
                    if let description = entry.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Text(DurationFormatter.format((entry.endedAt ?? Date()).timeIntervalSince(entry.startedAt)))
                    .font(.system(size: 12).monospacedDigit())
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Manual entry

    private var manualEntryRow: some View {
        Button {
            EntryEditRequest.post(entry: nil, defaultProjectId: pickedProjectId)
        } label: {
            Text("+ Manual Entry")
                .font(.system(size: 12))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private func projectColor(_ hex: String?) -> Color {
        guard let hex, !hex.isEmpty else { return .secondary }
        return Color(hex: hex)
    }
}
