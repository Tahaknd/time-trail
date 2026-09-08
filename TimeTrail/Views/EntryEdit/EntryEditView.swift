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

            DatePicker("Start", selection: $viewModel.startedAt)
            DatePicker("End", selection: $viewModel.endedAt)
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 260)
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
