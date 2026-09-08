# Context Packet ctxpkt_ee2714dd6bb560d084d7

- Title: Menu bar UI
- Source Type: sibling_output
- Source Key: t_1788856119406_a516tn
- Content Type: markdown
- Strategy: markdown_focus
- Original Tokens: 385
- Compact Tokens: 252

## Original Content
All 45 tests pass and the commit is clean. Here's a summary of what was built:

**New files — `TimeTrail/MenuBar/`**

| File | Purpose |
|---|---|
| `DurationFormatter.swift` | `"2h 34m"` / `"45m"` / `"0m"` from a `TimeInterval` |
| `RuleMatcher.swift` | Pure function: bundle ID + optional case-insensitive window-title keyword → `Match?`; first rule wins |
| `TimeAggregator.swift` | Sums closed/open segment durations per project bucket; open segments use `now`; Unassigned appended last |
| `MenuBarViewModel.swift` | `ObservableObject` that queries `fetchByDateRange` for today, runs `TimeAggregator`, publishes `projectTimes` + `totalSeconds` |
| `MenuBarView.swift` | SwiftUI view (260 pt wide): header row (Today + total), per-project rows (color dot + name + duration), "No activity" empty state |
| `StatusItemController.swift` | Owns `NSStatusItem`; hosts `NSHostingView<MenuBarView>` as a custom `NSMenuItem`; `NSMenuDelegate` starts a 30 s refresh timer while menu is open; always-on 30 s title-refresh timer |

**Updated** — `AppDelegate.swift` now creates `StatusItemController(db:)` instead of a raw status item; added the missing `import GRDB`.

**New tests — 18 cases**
- `RuleMatcherTests`: bundle match, bundle mismatch, keyword match/mismatch/nil-title, no-keyword rule, first-rule-wins ordering, unknown project ID
- `TimeAggregatorTests`: empty, closed duration, open-segment uses now, zero/negative duration excluded, accumulation, Unassigned bucket, Unassigned ordered last, descending sort, two-project separation
