import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @State private var selectedProjectId: Int64?
    @State private var showingAddProject = false
    @State private var newProjectName = ""
    @State private var newProjectColor = Color.blue

    init(viewModel: SettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var selectedProject: Project? {
        viewModel.projects.first { $0.id == selectedProjectId }
    }

    var body: some View {
        NavigationSplitView {
            projectSidebar
        } detail: {
            if let project = selectedProject {
                ProjectDetailView(project: project, viewModel: viewModel)
            } else {
                Text("Select a project to edit its name and color.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 700, minHeight: 450)
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showingAddProject) {
            addProjectSheet
        }
    }

    // MARK: Sidebar

    private var projectSidebar: some View {
        List(selection: $selectedProjectId) {
            Section("Projects") {
                ForEach(viewModel.projects) { project in
                    ProjectRowView(project: project)
                        .tag(project.id)
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            sidebarToolbar
        }
        .navigationTitle("TimeTrail")
    }

    private var sidebarToolbar: some View {
        HStack(spacing: 0) {
            Button {
                newProjectName = ""
                newProjectColor = .blue
                showingAddProject = true
            } label: {
                Image(systemName: "plus")
                    .frame(width: 28, height: 24)
            }
            .buttonStyle(.plain)

            Divider().frame(height: 16)

            Button {
                guard let id = selectedProjectId else { return }
                viewModel.deleteProject(id: id)
                selectedProjectId = viewModel.projects.first?.id
            } label: {
                Image(systemName: "minus")
                    .frame(width: 28, height: 24)
            }
            .buttonStyle(.plain)
            .disabled(selectedProjectId == nil)

            Spacer()
        }
        .padding(.horizontal, 4)
        .frame(height: 28)
        .background(.bar)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    // MARK: Add-project sheet

    private var addProjectSheet: some View {
        VStack(spacing: 20) {
            Text("New Project")
                .font(.headline)

            Form {
                TextField("Name", text: $newProjectName)
                    .onSubmit { commitAddProject() }
                ColorPicker("Color", selection: $newProjectColor, supportsOpacity: false)
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") { showingAddProject = false }
                Spacer()
                Button("Add") { commitAddProject() }
                    .buttonStyle(.borderedProminent)
                    .disabled(newProjectName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(width: 320, height: 220)
    }

    private func commitAddProject() {
        guard !newProjectName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        viewModel.addProject(name: newProjectName, color: newProjectColor.hexString)
        showingAddProject = false
        selectedProjectId = viewModel.projects.last?.id
    }
}

// MARK: - Project row

struct ProjectRowView: View {
    let project: Project

    var body: some View {
        Label {
            Text(project.name)
        } icon: {
            Circle()
                .fill(Color(hex: project.color))
                .frame(width: 10, height: 10)
        }
    }
}

// MARK: - Identifiable

extension Project: Identifiable {}
