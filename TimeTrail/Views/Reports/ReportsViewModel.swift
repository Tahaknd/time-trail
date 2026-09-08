import AppKit
import Foundation
import GRDB
import UniformTypeIdentifiers

enum ReportPeriod: String, CaseIterable, Identifiable {
    case daily = "Day"
    case weekly = "Week"
    var id: String { rawValue }
}

@MainActor
final class ReportsViewModel: ObservableObject {
    @Published var period: ReportPeriod = .daily
    @Published var referenceDate: Date = Date()
    @Published private(set) var projectTotals: [TimeAggregator.ProjectTotal] = []
    @Published private(set) var totalSeconds: TimeInterval = 0
    @Published var errorMessage: String?

    private let segmentRepo: ActivitySegmentRepository
    private let projectRepo: ProjectRepository
    private let ruleRepo: ProjectRuleRepository

    init(db: DatabaseQueue) {
        segmentRepo = ActivitySegmentRepository(db: db)
        projectRepo = ProjectRepository(db: db)
        ruleRepo = ProjectRuleRepository(db: db)
    }

    func load() {
        let (start, end) = dateRange
        do {
            let segments = try segmentRepo.fetchByDateRange(from: start, to: end)
            let projects = try projectRepo.fetchAll()
            let rules = try ruleRepo.fetchAll()
            let totals = TimeAggregator.aggregate(segments: segments, rules: rules, projects: projects)
            projectTotals = totals
            totalSeconds = totals.reduce(0) { $0 + $1.totalSeconds }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func exportCSV() {
        let (start, end) = dateRange
        guard
            let segments = try? segmentRepo.fetchByDateRange(from: start, to: end),
            let projects = try? projectRepo.fetchAll(),
            let rules = try? ruleRepo.fetchAll()
        else { return }

        let csv = CSVExporter.build(segments: segments, rules: rules, projects: projects)

        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.commaSeparatedText]
        panel.nameFieldStringValue = "timetrail-\(csvFilename).csv"
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try csv.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                Task { @MainActor in
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Private

    var dateRange: (Date, Date) {
        let cal = Calendar.current
        switch period {
        case .daily:
            let start = cal.startOfDay(for: referenceDate)
            let end = cal.date(byAdding: .day, value: 1, to: start)!
            return (start, end)
        case .weekly:
            // Week starts on Monday (ISO 8601)
            let weekday = cal.component(.weekday, from: referenceDate)
            let daysToMonday = (weekday + 5) % 7
            let monday = cal.date(byAdding: .day, value: -daysToMonday, to: cal.startOfDay(for: referenceDate))!
            let nextMonday = cal.date(byAdding: .day, value: 7, to: monday)!
            return (monday, nextMonday)
        }
    }

    private var csvFilename: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: referenceDate)
    }
}
