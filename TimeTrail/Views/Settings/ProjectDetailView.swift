import SwiftUI

struct ProjectDetailView: View {
    let project: Project
    @ObservedObject var viewModel: SettingsViewModel

    @State private var editingName: String
    @State private var pickedColor: Color

    init(project: Project, viewModel: SettingsViewModel) {
        self.project = project
        self.viewModel = viewModel
        _editingName = State(initialValue: project.name)
        _pickedColor = State(initialValue: Color(hex: project.color))
    }

    var body: some View {
        Form {
            Section("Project") {
                TextField("Name", text: $editingName)
                    .onSubmit { viewModel.rename(project, to: editingName) }

                ColorPicker("Color", selection: $pickedColor, supportsOpacity: false)
                    .onChange(of: pickedColor) { newColor in
                        viewModel.updateColor(of: project, to: newColor.hexString)
                    }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(project.name)
        .onChange(of: project.name) { newName in
            if editingName != newName { editingName = newName }
        }
    }
}
