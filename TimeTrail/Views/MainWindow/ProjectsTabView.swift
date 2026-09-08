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
                    ForEach(viewModel.projects, id: \.id) { project in
                        row(project)
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    private func row(_ project: Project) -> some View {
        let color = Color(hex: project.color)
        return Button {
            editTarget = .existing(project)
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 4, height: 26)
                Text(project.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(hoveredProjectId == project.id ? color.opacity(0.10) : Color(nsColor: .controlBackgroundColor).opacity(0.5))
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.vertical, 3)
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
