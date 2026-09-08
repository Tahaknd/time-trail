import XCTest
@testable import TimeTrail

final class RuleMatcherTests: XCTestCase {

    // MARK: - Helpers

    private func makeProject(id: Int64, name: String = "ProjectA", color: String = "#FF0000") -> Project {
        Project(id: id, name: name, color: color)
    }

    private func makeRule(id: Int64 = 1, projectId: Int64, bundleId: String, keyword: String? = nil) -> ProjectRule {
        ProjectRule(id: id, projectId: projectId, appBundleId: bundleId, windowTitleKeyword: keyword)
    }

    // MARK: - Bundle ID only

    func testBundleIdMatch_returnsProject() {
        let project = makeProject(id: 1)
        let rule = makeRule(projectId: 1, bundleId: "com.example.app")

        let result = RuleMatcher.match(
            bundleId: "com.example.app",
            windowTitle: nil,
            rules: [rule],
            projects: [project]
        )

        XCTAssertEqual(result?.projectId, 1)
        XCTAssertEqual(result?.projectName, "ProjectA")
    }

    func testBundleIdMismatch_returnsNil() {
        let project = makeProject(id: 1)
        let rule = makeRule(projectId: 1, bundleId: "com.example.app")

        let result = RuleMatcher.match(
            bundleId: "com.other.app",
            windowTitle: nil,
            rules: [rule],
            projects: [project]
        )

        XCTAssertNil(result)
    }

    func testNoRules_returnsNil() {
        let project = makeProject(id: 1)

        let result = RuleMatcher.match(
            bundleId: "com.example.app",
            windowTitle: nil,
            rules: [],
            projects: [project]
        )

        XCTAssertNil(result)
    }

    // MARK: - Window title keyword

    func testWindowTitleKeyword_matchesCaseSensitive() {
        let project = makeProject(id: 1)
        let rule = makeRule(projectId: 1, bundleId: "com.apple.safari", keyword: "GitHub")

        let result = RuleMatcher.match(
            bundleId: "com.apple.safari",
            windowTitle: "GitHub – Pull Request",
            rules: [rule],
            projects: [project]
        )

        XCTAssertNotNil(result)
    }

    func testWindowTitleKeyword_caseInsensitive() {
        let project = makeProject(id: 1)
        let rule = makeRule(projectId: 1, bundleId: "com.apple.safari", keyword: "github")

        let result = RuleMatcher.match(
            bundleId: "com.apple.safari",
            windowTitle: "GITHUB – Pull Request",
            rules: [rule],
            projects: [project]
        )

        XCTAssertNotNil(result)
    }

    func testWindowTitleKeyword_mismatch_returnsNil() {
        let project = makeProject(id: 1)
        let rule = makeRule(projectId: 1, bundleId: "com.apple.safari", keyword: "Jira")

        let result = RuleMatcher.match(
            bundleId: "com.apple.safari",
            windowTitle: "GitHub – Pull Request",
            rules: [rule],
            projects: [project]
        )

        XCTAssertNil(result)
    }

    func testWindowTitleKeyword_nilTitle_returnsNil() {
        let project = makeProject(id: 1)
        let rule = makeRule(projectId: 1, bundleId: "com.apple.safari", keyword: "GitHub")

        let result = RuleMatcher.match(
            bundleId: "com.apple.safari",
            windowTitle: nil,
            rules: [rule],
            projects: [project]
        )

        XCTAssertNil(result)
    }

    func testBundleIdRule_noKeyword_nilTitleStillMatches() {
        let project = makeProject(id: 1)
        let rule = makeRule(projectId: 1, bundleId: "com.example.app", keyword: nil)

        let result = RuleMatcher.match(
            bundleId: "com.example.app",
            windowTitle: nil,
            rules: [rule],
            projects: [project]
        )

        XCTAssertNotNil(result)
    }

    // MARK: - Multiple rules

    func testFirstMatchingRuleWins() {
        let p1 = makeProject(id: 1, name: "First")
        let p2 = makeProject(id: 2, name: "Second")
        let rule1 = makeRule(id: 1, projectId: 1, bundleId: "com.example.app")
        let rule2 = makeRule(id: 2, projectId: 2, bundleId: "com.example.app")

        let result = RuleMatcher.match(
            bundleId: "com.example.app",
            windowTitle: nil,
            rules: [rule1, rule2],
            projects: [p1, p2]
        )

        XCTAssertEqual(result?.projectName, "First")
    }

    func testMoreSpecificKeywordRuleOrderedFirst_wins() {
        let p1 = makeProject(id: 1, name: "Specific")
        let p2 = makeProject(id: 2, name: "General")
        let keywordRule = makeRule(id: 1, projectId: 1, bundleId: "com.apple.safari", keyword: "Jira")
        let generalRule = makeRule(id: 2, projectId: 2, bundleId: "com.apple.safari")

        let result = RuleMatcher.match(
            bundleId: "com.apple.safari",
            windowTitle: "Jira – Sprint Board",
            rules: [keywordRule, generalRule],
            projects: [p1, p2]
        )

        XCTAssertEqual(result?.projectName, "Specific")
    }

    func testRuleWithUnknownProjectId_skipped() {
        // Rule references a project that doesn't exist in the projects array.
        let rule = makeRule(projectId: 99, bundleId: "com.example.app")

        let result = RuleMatcher.match(
            bundleId: "com.example.app",
            windowTitle: nil,
            rules: [rule],
            projects: []
        )

        XCTAssertNil(result)
    }
}
