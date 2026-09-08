import SwiftUI
import GRDB

private enum SidebarItem: String, CaseIterable, Identifiable {
    case timer = "Timer"
    case reports = "Reports"
    case projects = "Projects"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .timer: return "play.circle"
        case .reports: return "chart.bar"
        case .projects: return "folder"
        }
    }
}

struct MainWindowView: View {
    @State private var selection: SidebarItem? = .timer

    @StateObject private var timerViewModel = TimerViewModel(db: DatabaseManager.shared.dbQueue)
    @StateObject private var reportsViewModel = ReportsViewModel(db: DatabaseManager.shared.dbQueue)
    @StateObject private var settingsViewModel = SettingsViewModel(
        projectRepo: ProjectRepository(db: DatabaseManager.shared.dbQueue)
    )

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) { item in
                Label(item.rawValue, systemImage: item.systemImage)
                    .tag(item)
            }
            .navigationSplitViewColumnWidth(min: 140, ideal: 160)
        } detail: {
            switch selection {
            case .timer, .none:
                TimerTabView(viewModel: timerViewModel)
            case .reports:
                ReportsView(viewModel: reportsViewModel)
            case .projects:
                SettingsView(viewModel: settingsViewModel)
            }
        }
        .navigationTitle("TimeTrail")
        .frame(minWidth: 800, minHeight: 500)
    }
}
