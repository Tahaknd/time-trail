import SwiftUI

struct EntryEditView: View {
    @ObservedObject var viewModel: EntryEditViewModel
    let onClose: () -> Void

    var body: some View {
        Form {
            Picker("Project", selection: $viewModel.projectId) {
                Text("Select a project").tag(Int64?.none)
                ForEach(viewModel.projects, id: \.id) { project in
                    Text(project.name).tag(project.id)
                }
            }

            TextField("Description (optional)", text: $viewModel.description)

            VStack(alignment: .leading, spacing: 6) {
                TextField("Tags, comma separated", text: $viewModel.tagsText)
                if !viewModel.knownTags.isEmpty {
                    TagSuggestionRow(knownTags: viewModel.knownTags, tagsText: $viewModel.tagsText)
                }
            }

            DatePicker("Start", selection: $viewModel.startedAt)
            DatePicker("End", selection: $viewModel.endedAt)
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 320)
        .safeAreaInset(edge: .bottom) {
            HStack {
                if !viewModel.isNew {
                    Button("Delete", role: .destructive) {
                        if viewModel.delete() { onClose() }
                    }
                }
                Spacer()
                Button("Cancel") { onClose() }
                Button(viewModel.isNew ? "Add" : "Save") {
                    if viewModel.save() { onClose() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canSave)
            }
            .padding()
            .background(.bar)
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
                            Text(tag)
                                .font(.system(size: 11))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(nsColor: .controlBackgroundColor))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
