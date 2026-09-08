import SwiftUI

struct ProjectEditView: View {
    @ObservedObject var viewModel: ProjectsViewModel
    let project: Project?
    let onClose: () -> Void

    @State private var name: String
    @State private var color: Color

    init(viewModel: ProjectsViewModel, project: Project?, onClose: @escaping () -> Void) {
        self.viewModel = viewModel
        self.project = project
        self.onClose = onClose
        _name = State(initialValue: project?.name ?? "")
        _color = State(initialValue: Color(hex: project?.color ?? "#0091FF"))
    }

    private var isNew: Bool { project == nil }

    var body: some View {
        Form {
            TextField("Name", text: $name)
            ColorPicker("Color", selection: $color, supportsOpacity: false)
        }
        .formStyle(.grouped)
        .frame(width: 340, height: 160)
        .safeAreaInset(edge: .bottom) {
            HStack {
                if let project, let id = project.id {
                    Button("Delete", role: .destructive) {
                        viewModel.deleteProject(id: id)
                        onClose()
                    }
                }
                Spacer()
                Button("Cancel") { onClose() }
                Button(isNew ? "Add" : "Save") {
                    if let project {
                        viewModel.update(project, name: name, color: color.hexString)
                    } else {
                        viewModel.addProject(name: name, color: color.hexString)
                    }
                    onClose()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
            .background(.bar)
        }
    }
}
