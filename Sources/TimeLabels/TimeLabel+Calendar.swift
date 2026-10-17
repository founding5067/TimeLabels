//
//  TimeLabel+Calendar.swift
//

import Foundation

// Labels tied to the calendar and clock: "3:30 PM", "Tomorrow".
extension TimeLabel {
    // MARK: - Clock time

    /// Short 12-hour clock time, e.g. "3:30 PM" (with an AM/PM suffix). The
    /// `calendar:` parameter sets the timezone used for the reading; it defaults
    /// to the current device timezone.
    /// Output is deterministic: a fixed `en_US_POSIX` locale and pattern always
    /// produce the 12-hour form with a plain space and no periods (never
    /// "3:30 p.m."), regardless of device locale or OS version.
    /// Pass `use24Hour: true` for the 24-hour form instead, e.g. "15:30" or
    /// "00:00".
    public static func time(_ date: Date, calendar: Calendar = .current, use24Hour: Bool = false) -> String {
        makeFormatter(use24Hour ? "HH:mm" : "h:mm a", calendar: calendar).string(from: date)
    }

    // MARK: - Date label

    /// Empty for today, "Tomorrow" for tomorrow, otherwise the medium-style date
    /// (e.g. "Jun 20, 2026"). The `calendar:` parameter sets the timezone, which
    /// affects both the today/tomorrow detection and the formatted date. `now`
    /// defaults to the current time and is what "today" is measured against.
    /// `relativeDays: true` also labels yesterday ("Yesterday") and dates 2–6
    /// days away in either direction with the weekday name ("Monday"); anything
    /// further out stays a medium-style date.
    public static func dateLabel(_ date: Date, now: Date = Date(), calendar: Calendar = .current, relativeDays: Bool = false) -> String {
        if relativeDays {
            let today = calendar.startOfDay(for: now)
            let target = calendar.startOfDay(for: date)
            let days = calendar.dateComponents([.day], from: today, to: target).day ?? 0
            switch days {
            case 0: return ""
            case 1: return "Tomorrow"
            case -1: return "Yesterday"
            case 2...6, -6 ... -2: return makeFormatter("EEEE", calendar: calendar).string(from: date)
            default: return makeDateLabelFormatter(calendar: calendar).string(from: date)
            }
        }
        if calendar.isDate(date, inSameDayAs: now) {
            return ""
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(date, inSameDayAs: tomorrow) {
            return "Tomorrow"
        }
        return makeDateLabelFormatter(calendar: calendar).string(from: date)
    }
}
