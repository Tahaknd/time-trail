import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow
            Divider().padding(.horizontal, 8)
            projectList
        }
        .frame(width: 260)
        .padding(.vertical, 4)
    }

    // MARK: - Subviews

    private var headerRow: some View {
        HStack {
            Text("Today")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            Text(DurationFormatter.format(viewModel.totalSeconds))
                .font(.system(size: 13, weight: .semibold).monospacedDigit())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var projectList: some View {
        if viewModel.projectTimes.isEmpty {
            Text("No activity recorded today")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
        } else {
            ForEach(viewModel.projectTimes, id: \.projectName) { item in
                projectRow(item)
            }
        }
    }

    private func projectRow(_ item: TimeAggregator.ProjectTotal) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(projectColor(item.color))
                .frame(width: 8, height: 8)
            Text(item.projectName)
                .font(.system(size: 12))
                .lineLimit(1)
            Spacer()
            Text(DurationFormatter.format(item.totalSeconds))
                .font(.system(size: 12).monospacedDigit())
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
    }

    private func projectColor(_ hex: String?) -> Color {
        guard let hex, !hex.isEmpty else { return .secondary }
        return Color(hex: hex)
    }
}
