import Foundation

enum DurationFormatter {
    /// Coarse "2h 34m" / "45m" / "0m" — used for summaries and past entries.
    static func format(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds))
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 {
            return "\(h)h \(m)m"
        } else if m > 0 {
            return "\(m)m"
        } else {
            return "0m"
        }
    }

    /// Precise "H:MM:SS" / "MM:SS" clock display — used for the live-running timer.
    static func formatClock(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}
