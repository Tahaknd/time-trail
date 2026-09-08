import SwiftUI

struct TimerTabView: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var pickedProjectId: Int64?
    @State private var descriptionText: String = ""
    @State private var editTarget: EditSheetTarget?

    var body: some View {
        VStack(spacing: 0) {
            timerBar
            Divider()
            entryList
        }
        .onAppear {
            viewModel.refresh()
            if pickedProjectId == nil {
                pickedProjectId = viewModel.allProjects.first?.id
            }
        }
        .sheet(item: $editTarget) { target in
            EntryEditView(
                viewModel: EntryEditViewModel(
                    db: DatabaseManager.shared.dbQueue,
                    entry: target.entry,
                    defaultProjectId: target.defaultProjectId
                ),
                onClose: {
                    editTarget = nil
                    viewModel.refresh()
                }
            )
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Timer bar

    @ViewBuilder
    private var timerBar: some View {
        if let running = viewModel.runningEntry {
            HStack(spacing: 12) {
                Circle()
                    .fill(projectColor(viewModel.projectColor(for: running.projectId)))
                    .frame(width: 10, height: 10)
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.projectName(for: running.projectId))
                        .font(.system(size: 14, weight: .medium))
                    if let description = running.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                TimelineView(.periodic(from: running.startedAt, by: 1)) { context in
                    Text(DurationFormatter.format(context.date.timeIntervalSince(running.startedAt)))
                        .font(.system(size: 16).monospacedDigit())
                }
                Button("Stop") { viewModel.stopTimer() }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.large)
            }
            .padding(16)
        } else {
            HStack(spacing: 12) {
                Menu {
                    ForEach(viewModel.allProjects, id: \.id) { project in
                        Button(project.name) { pickedProjectId = project.id }
                    }
                } label: {
                    Text(pickedProjectId.map(viewModel.projectName) ?? "Select project")
                }
                .frame(width: 160)

                TextField("What are you working on?", text: $descriptionText)
                    .textFieldStyle(.roundedBorder)

                Button("Start") {
                    guard let pickedProjectId else { return }
                    let trimmed = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
                    viewModel.startTimer(projectId: pickedProjectId, description: trimmed.isEmpty ? nil : trimmed)
                    descriptionText = ""
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(pickedProjectId == nil || viewModel.allProjects.isEmpty)

                Button {
                    editTarget = .new(defaultProjectId: pickedProjectId)
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add a manual entry")
            }
            .padding(16)
        }
    }

    // MARK: - Entry list

    @ViewBuilder
    private var entryList: some View {
        let completed = viewModel.recentEntries.filter { $0.endedAt != nil }
        if completed.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "clock")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text("No entries yet. Start a timer or add one manually.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(groupedByDay(completed), id: \.day) { group in
                    Section(group.label) {
                        ForEach(group.entries, id: \.id) { entry in
                            entryRow(entry)
                        }
                    }
                }
            }
        }
    }

    private func entryRow(_ entry: TimeEntry) -> some View {
        Button {
            editTarget = .existing(entry)
        } label: {
            HStack(spacing: 10) {
                Circle()
                    .fill(projectColor(viewModel.projectColor(for: entry.projectId)))
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.projectName(for: entry.projectId))
                        .font(.system(size: 13, weight: .medium))
                    if let description = entry.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(DurationFormatter.format((entry.endedAt ?? Date()).timeIntervalSince(entry.startedAt)))
                    .font(.system(size: 13).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions {
            Button("Delete", role: .destructive) {
                if let id = entry.id { viewModel.deleteEntry(id: id) }
            }
        }
    }

    // MARK: - Grouping

    private struct DayGroup {
        let day: Date
        let label: String
        let entries: [TimeEntry]
    }

    private func groupedByDay(_ entries: [TimeEntry]) -> [DayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.startedAt) }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        return grouped.keys.sorted(by: >).map { day in
            let label: String
            if calendar.isDateInToday(day) {
                label = "Today"
            } else if calendar.isDateInYesterday(day) {
                label = "Yesterday"
            } else {
                label = formatter.string(from: day)
            }
            let dayEntries = (grouped[day] ?? []).sorted { $0.startedAt > $1.startedAt }
            return DayGroup(day: day, label: label, entries: dayEntries)
        }
    }

    private func projectColor(_ hex: String?) -> Color {
        guard let hex, !hex.isEmpty else { return .secondary }
        return Color(hex: hex)
    }
}

// MARK: - Sheet target

enum EditSheetTarget: Identifiable {
    case new(defaultProjectId: Int64?)
    case existing(TimeEntry)

    var id: String {
        switch self {
        case .new: return "new"
        case .existing(let entry): return "existing-\(entry.id ?? 0)"
        }
    }

    var entry: TimeEntry? {
        if case .existing(let entry) = self { return entry }
        return nil
    }

    var defaultProjectId: Int64? {
        if case .new(let projectId) = self { return projectId }
        return nil
    }
}
