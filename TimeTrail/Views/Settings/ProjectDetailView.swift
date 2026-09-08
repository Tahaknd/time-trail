import SwiftUI

struct ProjectDetailView: View {
    let project: Project
    @ObservedObject var viewModel: SettingsViewModel

    @State private var editingName: String
    @State private var pickedColor: Color
    @State private var showingAddRule = false

    init(project: Project, viewModel: SettingsViewModel) {
        self.project = project
        self.viewModel = viewModel
        _editingName = State(initialValue: project.name)
        _pickedColor = State(initialValue: Color(hex: project.color))
    }

    private var projectRules: [ProjectRule] {
        guard let id = project.id else { return [] }
        return viewModel.rules[id] ?? []
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

            Section {
                if projectRules.isEmpty {
                    Text("No rules yet. Rules map app activity to this project.")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(projectRules, id: \.id) { rule in
                        RuleRowView(rule: rule) {
                            if let ruleId = rule.id, let projectId = project.id {
                                viewModel.deleteRule(id: ruleId, projectId: projectId)
                            }
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Rules")
                    Spacer()
                    Button {
                        showingAddRule = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                    .buttonStyle(.plain)
                }
            } footer: {
                if !projectRules.isEmpty {
                    Text("Activity matches a rule when the app bundle ID equals the rule's value and, if set, the window title contains the keyword.")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(project.name)
        .sheet(isPresented: $showingAddRule) {
            if let projectId = project.id {
                AddRuleSheet(projectId: projectId, viewModel: viewModel)
            }
        }
        .onChange(of: project.name) { newName in
            if editingName != newName { editingName = newName }
        }
    }
}

// MARK: - Rule row

struct RuleRowView: View {
    let rule: ProjectRule
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(rule.appBundleId)
                if let kw = rule.windowTitleKeyword {
                    Text("window contains \"\(kw)\"")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
        }
    }
}
