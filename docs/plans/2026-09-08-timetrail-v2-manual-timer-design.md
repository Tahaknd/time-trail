# TimeTrail v2 — Manual Timer Pivot

## Why

v1's zero-interaction automatic tracking (app + window-title rules) can't
distinguish between projects worked on inside the same multi-purpose app
(e.g. everything done through one chat/editor client lands under one rule).
Fixing that properly needs either AI classification (out of scope, cost/
complexity) or the user telling the app what they're doing — which is what
manual timers are. This pivots TimeTrail to a Toggl-style manual model.

## Removed

- Automatic tracking: `TrackingEngine`, `IdleMonitor`, `AccessibilityReader`
- Rule matching: `RuleMatcher`, `project_rule` table, rule UI (`AddRuleSheet`)
- The `ActiveProjectStore` "Working on" auto-override (no longer needed —
  the running timer's project *is* the active project)
- Onboarding's Accessibility permission step and its polling checker —
  nothing in v2 needs window-title access, so this whole permission story
  (and the TCC debugging pain that came with it) goes away

## New data model

Replaces `activity_segment` with `time_entry`:

- `time_entry`: id, project_id (FK), description (nullable free text),
  started_at, ended_at (nullable — null means "running")

A migration drops `activity_segment` and `project_rule` (pre-launch, no
real user data to preserve) and creates `time_entry`.

## New flow

1. Menu bar → pick a project → **Start** → live elapsed timer runs
2. **Stop** ends the entry
3. Today's entries list under the timer; tapping one opens an edit sheet
   (change project, description, start/end time, or delete)
4. **"+ Manual Entry"** adds a past entry directly without running a timer

## Architecture

- `TimerController` (replaces `TrackingEngine`): owns the running entry.
  `start(projectId:description:)` inserts a `time_entry` with `endedAt =
  nil`; `stop()` sets `endedAt = now`. No background polling, no
  `NSWorkspace` observation — purely user-driven.
- `MenuBarViewModel`: exposes `runningEntry`, `projects`, `todayEntries`;
  drives start/stop/edit/delete/manual-add. A 1s UI timer (only while the
  dropdown is open, matching v1's existing pattern) re-renders elapsed time.
- `TimeAggregator`: sums `time_entry` durations grouped by `project_id`
  directly — no rule matching layer. Same `ProjectTotal` output shape, so
  `ReportsView` is unchanged.
- `CSVExporter`: same RFC 4180 CSV shape, now sourced from `time_entry`
  (date, project, description, duration_seconds).
- Settings: project CRUD only (name, color) — the rules section is removed
  from `ProjectDetailView`.
- Onboarding: single welcome screen, no permission gate.

## Testing

- `TimeEntryRepositoryTests`: CRUD + fetch-running + fetch-by-date-range.
- `TimeAggregatorTests` / `CSVExporterTests`: rewritten against `TimeEntry`
  (grouping, sorting, Unassigned-less since every entry has a project).
- `TimerController` start/stop transitions.
