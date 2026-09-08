import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
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

    func rename(_ project: Project, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != project.name else { return }
        var updated = project
        updated.name = trimmed
        do {
            try projectRepo.update(updated)
            if let idx = projects.firstIndex(where: { $0.id == project.id }) {
                projects[idx] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateColor(of project: Project, to color: String) {
        var updated = project
        updated.color = color
        do {
            try projectRepo.update(updated)
            if let idx = projects.firstIndex(where: { $0.id == project.id }) {
                projects[idx] = updated
            }
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
