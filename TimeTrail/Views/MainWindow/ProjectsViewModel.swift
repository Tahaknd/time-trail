import SwiftUI

@MainActor
final class ProjectsViewModel: ObservableObject {
    @Published private(set) var projects: [Project] = []
    @Published var errorMessage: String?

    private let projectRepo: ProjectRepository

    init(projectRepo: ProjectRepository) {
        self.projectRepo = projectRepo
        load()
    }

    func load() {
        do {
            projects = try projectRepo.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addProject(name: String, color: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var project = Project(name: trimmed, color: color)
        do {
            try projectRepo.insert(&project)
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func update(_ project: Project, name: String, color: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var updated = project
        updated.name = trimmed
        updated.color = color
        do {
            try projectRepo.update(updated)
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteProject(id: Int64) {
        do {
            try projectRepo.delete(id: id)
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
