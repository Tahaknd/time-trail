import SwiftUI

struct TimerTabView: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var pickedProjectId: Int64?
    @State private var descriptionText: String = ""
    @State private var tagsText: String = ""
    @State private var showingTagField = false
    @State private var editTarget: EditSheetTarget?
    @State private var hoveredEntryId: Int64?
    @State private var searchText: String = ""
    @State private var filterProjectId: Int64?
    @ObservedObject private var themeStore = AppThemeStore.shared

    var body: some View {
        VStack(spacing: 0) {
            timerBar
            Divider()
            entryList
        }
        .background(Color(nsColor: .textBackgroundColor))
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
        HStack(spacing: 14) {
            if let running = viewModel.runningEntry {
                projectBadge(color: viewModel.projectColor(for: running.projectId), name: viewModel.projectName(for: running.projectId))

                if let description = running.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 15))
                        .foregroundStyle(.primary)
                } else {
                    Text("No description")
                        .font(.system(size: 15))
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                TimelineView(.periodic(from: running.startedAt, by: 1)) { context in
                    Text(DurationFormatter.formatClock(context.date.timeIntervalSince(running.startedAt)))
                        .font(.system(size: 20, weight: .medium).monospacedDigit())
                        .foregroundStyle(.primary)
                }

                stopButton
            } else {
                Menu {
                    if viewModel.allProjects.isEmpty {
                        Text("No projects yet")
                    }
                    ForEach(viewModel.allProjects, id: \.id) { project in
                        Button {
                            pickedProjectId = project.id
                        } label: {
                            Label(project.name, systemImage: "circle.fill")
                        }
                    }
                } label: {
                    if let pickedProjectId {
                        projectBadge(color: viewModel.projectColor(for: pickedProjectId), name: viewModel.projectName(for: pickedProjectId))
                    } else {
                        projectBadge(color: nil, name: "Select project")
                    }
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                TextField("What are you working on?", text: $descriptionText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .onSubmit(startTimer)

                if showingTagField {
                    TextField("tags", text: $tagsText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .frame(width: 120)
                }

                Spacer(minLength: 8)

                Button {
                    showingTagField.toggle()
                } label: {
                    Image(systemName: showingTagField || !tagsText.isEmpty ? "tag.fill" : "tag")
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .foregroundStyle(showingTagField || !tagsText.isEmpty ? themeStore.theme.color : .secondary)
                .help("Add tags")

                Button {
                    editTarget = .new(defaultProjectId: pickedProjectId)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Add a manual entry")

                startButton
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .animation(.easeInOut(duration: 0.15), value: viewModel.runningEntry?.id)
    }

    private func projectBadge(color: String?, name: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color.map { Color(hex: $0) } ?? Color.secondary.opacity(0.4))
                .frame(width: 9, height: 9)
            Text(name)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(Capsule())
    }

    private var startButton: some View {
        Button(action: startTimer) {
            Image(systemName: "play.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(pickedProjectId == nil ? Color.gray.opacity(0.5) : themeStore.theme.color))
        }
        .buttonStyle(.plain)
        .disabled(pickedProjectId == nil || viewModel.allProjects.isEmpty)
    }

    private var stopButton: some View {
        Button {
            viewModel.stopTimer()
        } label: {
            Image(systemName: "stop.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.red))
        }
        .buttonStyle(.plain)
    }

    private func startTimer() {
        guard let pickedProjectId else { return }
        let trimmed = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let tags = TimeEntry.joinTags(tagsText.split(separator: ",").map(String.init))
        viewModel.startTimer(projectId: pickedProjectId, description: trimmed.isEmpty ? nil : trimmed, tags: tags)
        descriptionText = ""
        tagsText = ""
        showingTagField = false
    }

    // MARK: - Entry list

    private var filteredEntries: [TimeEntry] {
        var entries = viewModel.recentEntries.filter { $0.endedAt != nil }
        if let filterProjectId {
            entries = entries.filter { $0.projectId == filterProjectId }
        }
        let query = searchText.trimmingCharacters(in: .whitespaces)
        if !query.isEmpty {
            entries = entries.filter { entry in
                (entry.description?.localizedCaseInsensitiveContains(query) ?? false)
                    || viewModel.projectName(for: entry.projectId).localizedCaseInsensitiveContains(query)
                    || entry.tagList.contains { $0.localizedCaseInsensitiveContains(query) }
            }
        }
        return entries
    }

    private var hasAnyCompletedEntries: Bool {
        viewModel.recentEntries.contains { $0.endedAt != nil }
    }

    @ViewBuilder
    private var entryList: some View {
        if !hasAnyCompletedEntries {
            VStack(spacing: 14) {
                EmptyStateBadge(systemImage: "timer", color: themeStore.theme.color)
                Text("No entries yet")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Start a timer or add one manually.")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 0) {
                filterBar
                Divider()
                if filteredEntries.isEmpty {
                    VStack(spacing: 12) {
                        EmptyStateBadge(systemImage: "magnifyingglass", color: themeStore.theme.color)
                        Text("No matching entries")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            ForEach(groupedByDay(filteredEntries), id: \.day) { group in
                                Section {
                                    ForEach(Array(group.entries.enumerated()), id: \.element.id) { index, entry in
                                        entryRow(entry)
                                        if index < group.entries.count - 1 {
                                            Divider().padding(.leading, 44)
                                        }
                                    }
                                } header: {
                                    dayHeader(group)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var filterBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                TextField("Search entries", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .frame(maxWidth: 220)

            Menu {
                Button("All projects") { filterProjectId = nil }
                Divider()
                ForEach(viewModel.allProjects, id: \.id) { project in
                    Button(project.name) { filterProjectId = project.id }
                }
            } label: {
                Text(filterProjectId.map(viewModel.projectName) ?? "All projects")
                    .font(.system(size: 12))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private func dayHeader(_ group: DayGroup) -> some View {
        HStack {
            Text(group.label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text(DurationFormatter.format(group.totalSeconds))
                .font(.system(size: 12, weight: .semibold).monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func entryRow(_ entry: TimeEntry) -> some View {
        Button {
            editTarget = .existing(entry)
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(viewModel.projectColor(for: entry.projectId).map { Color(hex: $0) } ?? Color.secondary.opacity(0.4))
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.description?.isEmpty == false ? entry.description! : viewModel.projectName(for: entry.projectId))
                        .font(.system(size: 13))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Text(viewModel.projectName(for: entry.projectId))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(timeRange(entry))
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                }

                if !entry.tagList.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(entry.tagList, id: \.self) { tag in
                            TagChip(tag: tag)
                        }
                    }
                }

                Spacer()

                Text(DurationFormatter.format((entry.endedAt ?? Date()).timeIntervalSince(entry.startedAt)))
                    .font(.system(size: 13).monospacedDigit())
                    .foregroundStyle(.secondary)

                Button {
                    if let id = entry.id { viewModel.deleteEntry(id: id) }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .opacity(hoveredEntryId == entry.id ? 1 : 0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 9)
            .contentShape(Rectangle())
            .background(hoveredEntryId == entry.id ? Color(nsColor: .controlBackgroundColor) : Color.clear)
            .animation(.easeInOut(duration: 0.1), value: hoveredEntryId)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredEntryId = hovering ? entry.id : (hoveredEntryId == entry.id ? nil : hoveredEntryId)
        }
        .contextMenu {
            Button("Edit") { editTarget = .existing(entry) }
            Button("Delete", role: .destructive) {
                if let id = entry.id { viewModel.deleteEntry(id: id) }
            }
        }
    }

    private func timeRange(_ entry: TimeEntry) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        let start = formatter.string(from: entry.startedAt)
        let end = entry.endedAt.map { formatter.string(from: $0) } ?? "now"
        return "\(start) – \(end)"
    }

    // MARK: - Grouping

    private struct DayGroup {
        let day: Date
        let label: String
        let entries: [TimeEntry]
        let totalSeconds: TimeInterval
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
            let total = dayEntries.reduce(0.0) { $0 + ($1.endedAt ?? Date()).timeIntervalSince($1.startedAt) }
            return DayGroup(day: day, label: label, entries: dayEntries, totalSeconds: total)
        }
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
