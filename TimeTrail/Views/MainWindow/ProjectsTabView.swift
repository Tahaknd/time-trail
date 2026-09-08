import SwiftUI

struct ProjectsTabView: View {
    @ObservedObject var viewModel: ProjectsViewModel
    @State private var editTarget: ProjectEditTarget?
    @State private var hoveredProjectId: Int64?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .background(Color(nsColor: .textBackgroundColor))
        .onAppear { viewModel.load() }
        .sheet(item: $editTarget) { target in
            ProjectEditView(viewModel: viewModel, project: target.project) {
                editTarget = nil
            }
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

    private var header: some View {
        HStack {
            Text("Projects")
                .font(.system(size: 15, weight: .semibold))
            Spacer()
            Button {
                editTarget = .new
            } label: {
                Image(systemName: "plus")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.projects.isEmpty {
            VStack(spacing: 14) {
                EmptyStateBadge(systemImage: "folder")
                Text("No projects yet")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                Button("Add Project") { editTarget = .new }
                    .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.projects.enumerated()), id: \.element.id) { index, project in
                        row(project)
                        if index < viewModel.projects.count - 1 {
                            Divider().padding(.leading, 44)
                        }
                    }
                }
            }
        }
    }

    private func row(_ project: Project) -> some View {
        Button {
            editTarget = .existing(project)
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: project.color))
                    .frame(width: 12, height: 12)
                Text(project.name)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .background(hoveredProjectId == project.id ? Color(nsColor: .controlBackgroundColor) : Color.clear)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredProjectId = hovering ? project.id : (hoveredProjectId == project.id ? nil : hoveredProjectId)
        }
        .contextMenu {
            Button("Edit") { editTarget = .existing(project) }
            Button("Delete", role: .destructive) {
                if let id = project.id { viewModel.deleteProject(id: id) }
            }
        }
    }
}

enum ProjectEditTarget: Identifiable {
    case new
    case existing(Project)

    var id: String {
        switch self {
        case .new: return "new"
        case .existing(let project): return "existing-\(project.id ?? 0)"
        }
    }

    var project: Project? {
        if case .existing(let project) = self { return project }
        return nil
    }
}
