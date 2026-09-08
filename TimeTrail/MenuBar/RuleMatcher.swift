import Foundation

enum RuleMatcher {
    struct Match: Equatable {
        let projectId: Int64
        let projectName: String
        let color: String
    }

    /// Returns the first matching project for a segment, or nil for Unassigned.
    /// Rules are evaluated in their array order; the first full match wins.
    /// A rule without a windowTitleKeyword matches on bundle ID alone.
    static func match(
        bundleId: String,
        windowTitle: String?,
        rules: [ProjectRule],
        projects: [Project]
    ) -> Match? {
        let projectIndex = Dictionary(
            uniqueKeysWithValues: projects.compactMap { p -> (Int64, Project)? in
                guard let id = p.id else { return nil }
                return (id, p)
            }
        )

        for rule in rules {
            guard rule.appBundleId == bundleId else { continue }

            if let keyword = rule.windowTitleKeyword {
                guard let title = windowTitle,
                      title.localizedCaseInsensitiveContains(keyword)
                else { continue }
            }

            guard let project = projectIndex[rule.projectId] else { continue }
            return Match(projectId: rule.projectId, projectName: project.name, color: project.color)
        }

        return nil
    }
}
