import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var projects: [Project] = []
    @Published private(set) var rules: [Int64: [ProjectRule]] = [:]
    @Published var errorMessage: String?

    private let projectRepo: ProjectRepository
    private let ruleRepo: ProjectRuleRepository

    init(projectRepo: ProjectRepository, ruleRepo: ProjectRuleRepository) {
        self.projectRepo = projectRepo
        self.ruleRepo = ruleRepo
        load()
    }

    func load() {
        do {
            projects = try projectRepo.fetchAll()
            var allRules: [Int64: [ProjectRule]] = [:]
            for project in projects {
                guard let pid = project.id else { continue }
                allRules[pid] = (try? ruleRepo.fetchByProjectId(pid)) ?? []
            }
            rules = allRules
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

    func addRule(projectId: Int64, bundleId: String, keyword: String?) {
        let trimmedId = bundleId.trimmingCharacters(in: .whitespaces)
        guard !trimmedId.isEmpty else { return }
        let trimmedKeyword = keyword?.trimmingCharacters(in: .whitespaces)
        let kw: String? = trimmedKeyword?.isEmpty == true ? nil : trimmedKeyword
        var rule = ProjectRule(id: nil, projectId: projectId, appBundleId: trimmedId, windowTitleKeyword: kw)
        do {
            try ruleRepo.insert(&rule)
            rules[projectId] = try ruleRepo.fetchByProjectId(projectId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteRule(id: Int64, projectId: Int64) {
        do {
            try ruleRepo.delete(id: id)
            rules[projectId] = try ruleRepo.fetchByProjectId(projectId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
