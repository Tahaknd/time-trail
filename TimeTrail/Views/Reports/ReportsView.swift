import Charts
import SwiftUI

struct ReportsView: View {
    @StateObject private var viewModel: ReportsViewModel
    @State private var showingDatePicker = false

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
        .background(Color(nsColor: .textBackgroundColor))
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
        HStack(spacing: 16) {
            Picker("", selection: $viewModel.period) {
                ForEach(ReportPeriod.allCases) { p in
                    Text(p.rawValue).tag(p)
                }
            }
            .pickerStyle(.segmented)
            .fixedSize()

            dateNavigator

            Spacer()

            Text(DurationFormatter.format(viewModel.totalSeconds))
                .font(.system(size: 15, weight: .semibold).monospacedDigit())

            Button {
                viewModel.exportCSV()
            } label: {
                Label("Export CSV", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var dateNavigator: some View {
        HStack(spacing: 4) {
            Button {
                viewModel.goToPreviousPeriod()
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Button {
                showingDatePicker = true
            } label: {
                Text(viewModel.dateRangeLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(minWidth: 130)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showingDatePicker) {
                VStack(spacing: 8) {
                    DatePicker(
                        "",
                        selection: $viewModel.referenceDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()

                    Button("Today") {
                        viewModel.goToToday()
                        showingDatePicker = false
                    }
                    .buttonStyle(.bordered)
                }
                .padding(12)
            }

            Button {
                viewModel.goToNextPeriod()
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            if !viewModel.isCurrentPeriod {
                Button("Today") {
                    viewModel.goToToday()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .padding(.leading, 4)
            }
        }
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
            .cornerRadius(4)
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
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text("No activity recorded")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            Text("Nothing tracked for this period yet.")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
