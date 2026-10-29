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

    // MARK: - Time range

    /// Two clock times joined by a spaced en dash, e.g. "11:00 AM – 1:30 PM".
    /// When both times fall on the same day and share AM or PM, the first one
    /// drops the suffix: "3:30 – 4:15 PM". With `use24Hour: true` both times
    /// are always written out: "15:30 – 16:15". The times are formatted as
    /// given, so an `end` before `start` isn't swapped or rejected.
    public static func timeRange(_ start: Date, _ end: Date, calendar: Calendar = .current, use24Hour: Bool = false) -> String {
        let endText = time(end, calendar: calendar, use24Hour: use24Hour)
        let isMorning = { (date: Date) in calendar.component(.hour, from: date) < 12 }
        if !use24Hour, calendar.isDate(start, inSameDayAs: end), isMorning(start) == isMorning(end) {
            return "\(makeFormatter("h:mm", calendar: calendar).string(from: start)) – \(endText)"
        }
        return "\(time(start, calendar: calendar, use24Hour: use24Hour)) – \(endText)"
    }

    // MARK: - Date label

    /// Empty for today, "Tomorrow" for tomorrow, otherwise the medium-style date
    /// (e.g. "Jun 20, 2026"). The `calendar:` parameter sets the timezone, which
    /// affects both the today/tomorrow detection and the formatted date. `now`
    /// defaults to the current time and is what "today" is measured against.
    /// `relativeDays: true` also labels yesterday ("Yesterday") and dates 2–6
    /// days away in either direction with the weekday name ("Monday"); anything
    /// further out stays a medium-style date.
    /// `omitCurrentYear: true` leaves the year off dates in the same year as
    /// `now` ("Jun 20"); dates in other years keep it ("Jun 20, 2025").
    /// `namesToday: true` returns "Today" instead of an empty string.
    /// `includesWeekday: true` puts the weekday in front of dated labels
    /// ("Saturday, Jun 20"); "Today", "Tomorrow", "Yesterday" and the
    /// `relativeDays` weekday names are left as they are.
    /// `abbreviatedWeekday: true` shortens every weekday name to three letters
    /// ("Sat", "Sat, Jun 20").
    public static func dateLabel(_ date: Date, now: Date = Date(), calendar: Calendar = .current, relativeDays: Bool = false, omitCurrentYear: Bool = false, namesToday: Bool = false, includesWeekday: Bool = false, abbreviatedWeekday: Bool = false) -> String {
        let today = namesToday ? "Today" : ""
        let dated = { () -> String in
            let medium = mediumDate(date, now: now, calendar: calendar, omitCurrentYear: omitCurrentYear)
            guard includesWeekday else { return medium }
            return "\(weekday(date, calendar: calendar, abbreviated: abbreviatedWeekday)), \(medium)"
        }
        if relativeDays {
            let start = calendar.startOfDay(for: now)
            let target = calendar.startOfDay(for: date)
            let days = calendar.dateComponents([.day], from: start, to: target).day ?? 0
            switch days {
            case 0: return today
            case 1: return "Tomorrow"
            case -1: return "Yesterday"
            case 2...6, -6 ... -2: return weekday(date, calendar: calendar, abbreviated: abbreviatedWeekday)
            default: return dated()
            }
        }
        if calendar.isDate(date, inSameDayAs: now) {
            return today
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(date, inSameDayAs: tomorrow) {
            return "Tomorrow"
        }
        return dated()
    }

    // MARK: - Date and time

    /// `dateLabel` and `time` together: "3:30 PM" today, "Tomorrow at 3:30 PM",
    /// or "Jun 20, 2026 at 3:30 PM". `relativeDays` and `omitCurrentYear` work
    /// as in `dateLabel` ("Yesterday at 3:30 PM", "Monday at 3:30 PM",
    /// "Jun 20 at 3:30 PM"), and `use24Hour` as in `time` ("Tomorrow at 15:30").
    /// `namesToday`, `includesWeekday` and `abbreviatedWeekday` also work as in
    /// `dateLabel` ("Today at 3:30 PM", "Sat, Jun 20 at 3:30 PM").
    /// `separator` goes between the date and the time, as given: " at " by
    /// default, or for example " · " ("Tomorrow · 3:30 PM") or " "
    /// ("Sat 3:30 PM"). Today's time stands alone unless `namesToday` is on.
    public static func dateTime(_ date: Date, now: Date = Date(), calendar: Calendar = .current, use24Hour: Bool = false, relativeDays: Bool = false, omitCurrentYear: Bool = false, namesToday: Bool = false, includesWeekday: Bool = false, abbreviatedWeekday: Bool = false, separator: String = " at ") -> String {
        let day = dateLabel(date, now: now, calendar: calendar, relativeDays: relativeDays, omitCurrentYear: omitCurrentYear, namesToday: namesToday, includesWeekday: includesWeekday, abbreviatedWeekday: abbreviatedWeekday)
        let clock = time(date, calendar: calendar, use24Hour: use24Hour)
        return day.isEmpty ? clock : "\(day)\(separator)\(clock)"
    }

    // MARK: - Helpers

    private static func mediumDate(_ date: Date, now: Date, calendar: Calendar, omitCurrentYear: Bool) -> String {
        if omitCurrentYear, calendar.component(.year, from: date) == calendar.component(.year, from: now) {
            return makeFormatter("MMM d", calendar: calendar).string(from: date)
        }
        return makeDateLabelFormatter(calendar: calendar).string(from: date)
    }

    private static func weekday(_ date: Date, calendar: Calendar, abbreviated: Bool) -> String {
        makeFormatter(abbreviated ? "EEE" : "EEEE", calendar: calendar).string(from: date)
    }
}
