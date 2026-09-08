import Charts
import SwiftUI

struct ReportsView: View {
    @StateObject private var viewModel: ReportsViewModel

    init(viewModel: ReportsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            if viewModel.projectTotals.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        barChart
                        breakdownList
                    }
                    .padding(20)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 450)
        .onAppear { viewModel.load() }
        .onChange(of: viewModel.period, perform: { _ in viewModel.load() })
        .onChange(of: viewModel.referenceDate, perform: { _ in viewModel.load() })
        .alert("Export Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 12) {
            Picker("", selection: $viewModel.period) {
                ForEach(ReportPeriod.allCases) { p in
                    Text(p.rawValue).tag(p)
                }
            }
            .pickerStyle(.segmented)
            .fixedSize()

            DatePicker("", selection: $viewModel.referenceDate, displayedComponents: .date)
                .labelsHidden()

            Spacer()

            Text(DurationFormatter.format(viewModel.totalSeconds))
                .font(.system(size: 13, weight: .semibold).monospacedDigit())

            Button("Export CSV") { viewModel.exportCSV() }
                .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Bar chart

    private var barChart: some View {
        Chart(viewModel.projectTotals, id: \.projectName) { total in
            BarMark(
                x: .value("Project", total.projectName),
                y: .value("Hours", total.totalSeconds / 3600)
            )
            .foregroundStyle(
                (total.color.flatMap { Color(hex: $0) }) ?? Color.secondary
            )
        }
        .chartYAxisLabel("Hours")
        .frame(height: 200)
    }

    // MARK: - Breakdown list

    private var breakdownList: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.projectTotals, id: \.projectName) { total in
                rowView(for: total)
                if total.projectName != viewModel.projectTotals.last?.projectName {
                    Divider()
                }
            }
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.separator, lineWidth: 0.5)
        )
    }

    private func rowView(for total: TimeAggregator.ProjectTotal) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill((total.color.flatMap { Color(hex: $0) }) ?? Color.secondary)
                .frame(width: 10, height: 10)
            Text(total.projectName)
                .font(.system(size: 13))
            Spacer()
            Text(DurationFormatter.format(total.totalSeconds))
                .font(.system(size: 13).monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No activity recorded for this period.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
