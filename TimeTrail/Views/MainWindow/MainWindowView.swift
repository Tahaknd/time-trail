import AppKit
import SwiftUI
import GRDB

private enum SidebarItem: String, CaseIterable, Identifiable {
    case timer = "Timer"
    case reports = "Reports"
    case projects = "Projects"
    case settings = "Settings"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .timer: return "play.circle.fill"
        case .reports: return "chart.bar.fill"
        case .projects: return "folder.fill"
        case .settings: return "gearshape.fill"
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
    @StateObject private var themeStore = AppThemeStore.shared

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) { item in
                Label(item.rawValue, systemImage: item.systemImage)
                    .tag(item)
                    .padding(.vertical, 2)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                sidebarHeader
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
            case .settings:
                AppSettingsTabView(themeStore: themeStore)
            }
        }
        .navigationTitle("TimeTrail")
        .frame(minWidth: 820, minHeight: 540)
        .tint(themeStore.theme.color)
    }

    private var sidebarHeader: some View {
        HStack(spacing: 8) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 24, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            Text("TimeTrail")
                .font(.system(size: 15, weight: .semibold))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }
}
