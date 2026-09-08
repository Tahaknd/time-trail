import SwiftUI

struct EntryEditView: View {
    @ObservedObject var viewModel: EntryEditViewModel
    let onClose: () -> Void
    @ObservedObject private var themeStore = AppThemeStore.shared

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    fieldBlock(label: "Project") {
                        Menu {
                            ForEach(viewModel.projects, id: \.id) { project in
                                Button(project.name) { viewModel.projectId = project.id }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(currentProjectColor)
                                    .frame(width: 9, height: 9)
                                Text(currentProjectName)
                                    .font(.system(size: 13, weight: .medium))
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .menuStyle(.borderlessButton)
                    }

                    fieldBlock(label: "Description") {
                        TextField("What did you work on?", text: $viewModel.description)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    fieldBlock(label: "Tags") {
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Comma separated", text: $viewModel.tagsText)
                                .textFieldStyle(.plain)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(nsColor: .controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            if !viewModel.knownTags.isEmpty {
                                TagSuggestionRow(knownTags: viewModel.knownTags, tagsText: $viewModel.tagsText)
                            }
                        }
                    }

                    HStack(spacing: 16) {
                        fieldBlock(label: "Start") {
                            DatePicker("", selection: $viewModel.startedAt)
                                .labelsHidden()
                        }
                        fieldBlock(label: "End") {
                            DatePicker("", selection: $viewModel.endedAt)
                                .labelsHidden()
                        }
                    }
                }
                .padding(20)
            }

            Divider()
            footer
        }
        .frame(width: 400, height: 420)
        .background(Color(nsColor: .textBackgroundColor))
        .tint(themeStore.theme.color)
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var header: some View {
        HStack {
            Text(viewModel.isNew ? "New Entry" : "Edit Entry")
                .font(.system(size: 15, weight: .semibold))
            Spacer()
            Button {
                onClose()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var footer: some View {
        HStack {
            if !viewModel.isNew {
                Button("Delete", role: .destructive) {
                    if viewModel.delete() { onClose() }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
            }
            Spacer()
            Button("Cancel") { onClose() }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            Button(viewModel.isNew ? "Add" : "Save") {
                if viewModel.save() { onClose() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canSave)
        }
        .padding(16)
    }

    private func fieldBlock<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var currentProjectName: String {
        guard let id = viewModel.projectId else { return "Select project" }
        return viewModel.projects.first(where: { $0.id == id })?.name ?? "Select project"
    }

    private var currentProjectColor: Color {
        guard let id = viewModel.projectId,
              let hex = viewModel.projects.first(where: { $0.id == id })?.color
        else { return .secondary.opacity(0.4) }
        return Color(hex: hex)
    }
}

/// Tappable chips of previously-used tags not already present in the field.
struct TagSuggestionRow: View {
    let knownTags: [String]
    @Binding var tagsText: String

    private var currentTags: Set<String> {
        Set(tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
    }

    var body: some View {
        let suggestions = knownTags.filter { !currentTags.contains($0) }
        if !suggestions.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(suggestions, id: \.self) { tag in
                        Button {
                            let existing = tagsText.trimmingCharacters(in: .whitespaces)
                            tagsText = existing.isEmpty ? tag : "\(existing), \(tag)"
                        } label: {
                            TagChip(tag: tag)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
