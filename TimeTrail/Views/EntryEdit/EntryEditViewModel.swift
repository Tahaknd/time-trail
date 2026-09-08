import Foundation
import GRDB

@MainActor
final class EntryEditViewModel: ObservableObject {
    @Published var projectId: Int64?
    @Published var description: String = ""
    @Published var startedAt: Date
    @Published var endedAt: Date
    @Published private(set) var projects: [Project] = []
    @Published var errorMessage: String?

    let isNew: Bool
    private let existingId: Int64?
    private let entryRepo: TimeEntryRepository
    private let projectRepo: ProjectRepository

    init(db: DatabaseQueue, entry: TimeEntry?, defaultProjectId: Int64?) {
        entryRepo = TimeEntryRepository(db: db)
        projectRepo = ProjectRepository(db: db)

        if let entry {
            isNew = false
            existingId = entry.id
            projectId = entry.projectId
            description = entry.description ?? ""
            startedAt = entry.startedAt
            endedAt = entry.endedAt ?? Date()
        } else {
            isNew = true
            existingId = nil
            projectId = defaultProjectId
            let now = Date()
            startedAt = now.addingTimeInterval(-3600)
            endedAt = now
        }

        projects = (try? projectRepo.fetchAll()) ?? []
    }

    var canSave: Bool {
        projectId != nil && endedAt > startedAt
    }

    func save() -> Bool {
        guard let projectId else { return false }
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalDescription: String? = trimmedDescription.isEmpty ? nil : trimmedDescription

        do {
            if let existingId {
                let entry = TimeEntry(
                    id: existingId,
                    projectId: projectId,
                    description: finalDescription,
                    startedAt: startedAt,
                    endedAt: endedAt
                )
                try entryRepo.update(entry)
            } else {
                var entry = TimeEntry(
                    projectId: projectId,
                    description: finalDescription,
                    startedAt: startedAt,
                    endedAt: endedAt
                )
                try entryRepo.insert(&entry)
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func delete() -> Bool {
        guard let existingId else { return false }
        do {
            try entryRepo.delete(id: existingId)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
