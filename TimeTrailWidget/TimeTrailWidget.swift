import SwiftUI
import WidgetKit

struct TimeTrailEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct TimeTrailTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimeTrailEntry {
        TimeTrailEntry(date: Date(), snapshot: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (TimeTrailEntry) -> Void) {
        completion(TimeTrailEntry(date: Date(), snapshot: WidgetSnapshotStore.read()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimeTrailEntry>) -> Void) {
        let snapshot = WidgetSnapshotStore.read()
        let entry = TimeTrailEntry(date: Date(), snapshot: snapshot)
        // The app pokes WidgetCenter.reloadAllTimelines() on every change, so
        // this is just a safety-net refresh — not the primary update path.
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct TimeTrailWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TimeTrailEntry

    var body: some View {
        if let projectName = entry.snapshot.runningProjectName,
           let startedAt = entry.snapshot.runningStartedAt {
            runningView(projectName: projectName, colorHex: entry.snapshot.runningProjectColorHex, startedAt: startedAt)
        } else {
            idleView
        }
    }

    // MARK: - Running

    private func runningView(projectName: String, colorHex: String?, startedAt: Date) -> some View {
        let color = colorHex.map { Color(hex: $0) } ?? .secondary
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Circle().fill(.green).frame(width: 8, height: 8)
                Text("RUNNING")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                Spacer()
            }
            Text(projectName)
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
            Text(timerInterval: startedAt...Date.distantFuture, countsDown: false)
                .font(.system(size: 22, weight: .bold).monospacedDigit())
                .foregroundStyle(color)

            if family == .systemMedium {
                Spacer()
                Divider()
                todayRow
            }
        }
        .padding(16)
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text("NOT TRACKING")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                Spacer()
            }
            Text(DurationFormatter.format(entry.snapshot.todayTotalSeconds))
                .font(.system(size: 22, weight: .bold).monospacedDigit())
            Text("tracked today")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            if family == .systemMedium {
                Spacer()
                Divider()
                topProjectsList
            } else {
                Spacer()
            }
        }
        .padding(16)
    }

    // MARK: - Shared pieces

    private var todayRow: some View {
        HStack {
            Text("Today")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
            Text(DurationFormatter.format(entry.snapshot.todayTotalSeconds))
                .font(.system(size: 12, weight: .semibold).monospacedDigit())
        }
    }

    private var topProjectsList: some View {
        VStack(alignment: .leading, spacing: 6) {
            if entry.snapshot.topProjectsToday.isEmpty {
                Text("No activity yet")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(entry.snapshot.topProjectsToday, id: \.name) { project in
                    HStack(spacing: 6) {
                        Circle().fill(Color(hex: project.colorHex)).frame(width: 6, height: 6)
                        Text(project.name)
                            .font(.system(size: 11))
                            .lineLimit(1)
                        Spacer()
                        Text(DurationFormatter.format(project.seconds))
                            .font(.system(size: 11).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

struct TimeTrailWidget: Widget {
    let kind = "TimeTrailWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimeTrailTimelineProvider()) { entry in
            if #available(macOS 14.0, *) {
                TimeTrailWidgetView(entry: entry)
                    .containerBackground(.background, for: .widget)
            } else {
                TimeTrailWidgetView(entry: entry)
                    .background(Color(nsColor: .windowBackgroundColor))
            }
        }
        .configurationDisplayName("TimeTrail")
        .description("See your running timer or today's tracked time at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct TimeTrailWidgetBundle: WidgetBundle {
    var body: some Widget {
        TimeTrailWidget()
    }
}
