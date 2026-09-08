import SwiftUI
import GRDB

private enum SidebarItem: String, CaseIterable, Identifiable {
    case timer = "Timer"
    case reports = "Reports"
    case projects = "Projects"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .timer: return "play.circle.fill"
        case .reports: return "chart.bar.fill"
        case .projects: return "folder.fill"
        }
    }
}

struct MainWindowView: View {
    @State private var selection: SidebarItem? = .timer

    @StateObject private var timerViewModel = TimerViewModel(db: DatabaseManager.shared.dbQueue)
    @StateObject private var reportsViewModel = ReportsViewModel(db: DatabaseManager.shared.dbQueue)
    @StateObject private var projectsViewModel = ProjectsViewModel(
        projectRepo: ProjectRepository(db: DatabaseManager.shared.dbQueue)
    )

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) { item in
                Label(item.rawValue, systemImage: item.systemImage)
                    .tag(item)
                    .padding(.vertical, 2)
            }
            .navigationSplitViewColumnWidth(min: 170, ideal: 190)
        } detail: {
            switch selection {
            case .timer, .none:
                TimerTabView(viewModel: timerViewModel)
            case .reports:
                ReportsView(viewModel: reportsViewModel)
            case .projects:
                ProjectsTabView(viewModel: projectsViewModel)
            }
        }
        .navigationTitle("TimeTrail")
        .frame(minWidth: 820, minHeight: 540)
    }
}
