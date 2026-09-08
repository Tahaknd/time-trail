# TimeTrail — Design

## Problem

Freelancers and hourly-billing consultants can't reliably answer "where did my
day go" or produce an accurate invoice. Manual timers get forgotten. Existing
tools (Timing, RescueTime, Toggl Track) solve this but are subscription-priced
and dashboard-heavy.

## Target user

Freelancers, consultants, and solo builders who bill by the hour or just want
an honest accounting of their workday, without remembering to start a timer.

## Positioning

Zero-interaction automatic tracking + a one-time purchase, positioned against
subscription fatigue. No AI, no backend, no recurring cost to run.

## MVP scope

1. **Automatic tracking** — Track active application via `NSWorkspace`
   notifications. Pause counting during idle (no keyboard/mouse input for a
   configurable threshold, default 3 minutes). No manual start/stop.
2. **Project tagging** — User creates named "Projects" and maps them to rules
   (app bundle ID, optionally a window-title keyword). Rule-based only, no ML.
   Untagged time falls into an "Unassigned" bucket.
3. **Menu bar summary** — Status item shows today's total; dropdown shows a
   per-project breakdown for today.
4. **Reports screen** — Daily/weekly view: list + bar chart of time per
   project. CSV export (date, project, app, duration) for invoicing.

## Out of scope (v1)

Multi-device sync, team/collaboration features, automatic invoice generation,
AI summarization, Pomodoro/focus features, notifications, Mac App Store
distribution.

## Architecture

- SwiftUI for all UI (menu bar dropdown, reports window, onboarding,
  settings).
- `NSStatusItem` for the menu bar presence.
- Local SQLite via GRDB for activity segments and project rules — single
  file under `~/Library/Application Support/TimeTrail/`.
- No backend, no network calls except update checks (Sparkle).

### Data model

- `activity_segment`: id, app_bundle_id, app_name, window_title, started_at,
  ended_at.
- `project`: id, name, color.
- `project_rule`: id, project_id, app_bundle_id, window_title_keyword
  (nullable).

### Permissions

Accessibility permission is required to read window titles (used for rule
matching beyond bundle ID). Requested via a first-run onboarding screen with
a direct link to System Settings.

## Distribution

Direct sale (not Mac App Store) via a simple license-key check, to avoid the
30% cut and IAP review overhead. Sparkle for auto-updates.

## Testing

- Unit tests for idle-detection threshold logic and rule-matching (app
  bundle ID / window-title keyword → project).
- Unit tests for time aggregation (segment list → per-project daily/weekly
  totals).
- Manual verification of the tracking loop and CSV export against a real
  work session (automated UI testing of a menu-bar-only app has low ROI for
  v1).

## Success criteria

A user can install the app, tag 2-3 projects, work normally for a day, and
get an accurate per-project time breakdown plus a CSV export — without ever
touching a start/stop button.
