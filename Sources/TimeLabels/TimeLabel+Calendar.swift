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
    /// `useRelativeDays: true` also labels yesterday ("Yesterday") and dates 2–6
    /// days away in either direction with the weekday name ("Monday"); anything
    /// further out stays a medium-style date.
    /// `omitCurrentYear: true` leaves the year off dates in the same year as
    /// `now` ("Jun 20"); dates in other years keep it ("Jun 20, 2025").
    /// `nameToday: true` returns "Today" instead of an empty string.
    /// `includeWeekday: true` puts the weekday in front of medium-style dates
    /// ("Saturday, Jun 20"); "Today", "Tomorrow", "Yesterday" and the
    /// `useRelativeDays` weekday names are left as they are.
    /// `abbreviateWeekday: true` shortens every weekday name to three letters
    /// ("Sat", "Sat, Jun 20").
    public static func date(_ date: Date, now: Date = Date(), calendar: Calendar = .current, useRelativeDays: Bool = false, omitCurrentYear: Bool = false, nameToday: Bool = false, includeWeekday: Bool = false, abbreviateWeekday: Bool = false) -> String {
        dayLabel(date, now: now, calendar: calendar, useRelativeDays: useRelativeDays, omitCurrentYear: omitCurrentYear, nameToday: nameToday, includeWeekday: includeWeekday, abbreviateWeekday: abbreviateWeekday).text
    }

    // MARK: - Date and time

    /// `date` and `time` together: "3:30 PM" today, "Tomorrow at 3:30 PM",
    /// or "Jun 20, 2026 at 3:30 PM". `useRelativeDays` and `omitCurrentYear` work
    /// as in `date` ("Yesterday at 3:30 PM", "Monday at 3:30 PM",
    /// "Jun 20 at 3:30 PM"), and `use24Hour` as in `time` ("Tomorrow at 15:30").
    /// `nameToday`, `includeWeekday` and `abbreviateWeekday` also work as in
    /// `date` ("Today at 3:30 PM", "Sat, Jun 20 at 3:30 PM").
    /// `separator` goes between the date and the time, as given: " at " by
    /// default, or for example " · " ("Tomorrow · 3:30 PM") or " "
    /// ("Sat 3:30 PM"). `datedSeparator` replaces it after medium-style dates
    /// only, so a tight line can read "Sat 3:30 PM" but "Jun 20, 3:30 PM";
    /// `nil` (the default) uses `separator` there too. Today's time stands
    /// alone unless `nameToday` is on.
    public static func dateTime(_ date: Date, now: Date = Date(), calendar: Calendar = .current, use24Hour: Bool = false, useRelativeDays: Bool = false, omitCurrentYear: Bool = false, nameToday: Bool = false, includeWeekday: Bool = false, abbreviateWeekday: Bool = false, separator: String = " at ", datedSeparator: String? = nil) -> String {
        let day = dayLabel(date, now: now, calendar: calendar, useRelativeDays: useRelativeDays, omitCurrentYear: omitCurrentYear, nameToday: nameToday, includeWeekday: includeWeekday, abbreviateWeekday: abbreviateWeekday)
        let clock = time(date, calendar: calendar, use24Hour: use24Hour)
        if day.text.isEmpty { return clock }
        return "\(day.text)\(day.isDated ? datedSeparator ?? separator : separator)\(clock)"
    }

    // MARK: - Helpers

    // `date`'s text, and whether it's a medium-style date rather than a
    // named day ("Today", "Tomorrow", "Yesterday", a weekday), which is what
    // `dateTime`'s `datedSeparator` follows.
    private static func dayLabel(_ date: Date, now: Date, calendar: Calendar, useRelativeDays: Bool, omitCurrentYear: Bool, nameToday: Bool, includeWeekday: Bool, abbreviateWeekday: Bool) -> (text: String, isDated: Bool) {
        let today = (text: nameToday ? "Today" : "", isDated: false)
        let dated = { (text: mediumDate(date, now: now, calendar: calendar, omitCurrentYear: omitCurrentYear, includeWeekday: includeWeekday, abbreviateWeekday: abbreviateWeekday), isDated: true) }
        if useRelativeDays {
            let start = calendar.startOfDay(for: now)
            let target = calendar.startOfDay(for: date)
            let days = calendar.dateComponents([.day], from: start, to: target).day ?? 0
            switch days {
            case 0: return today
            case 1: return ("Tomorrow", false)
            case -1: return ("Yesterday", false)
            case 2...6, -6 ... -2: return (makeFormatter(abbreviateWeekday ? "EEE" : "EEEE", calendar: calendar).string(from: date), false)
            default: return dated()
            }
        }
        if calendar.isDate(date, inSameDayAs: now) {
            return today
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(date, inSameDayAs: tomorrow) {
            return ("Tomorrow", false)
        }
        return dated()
    }

    // One formatter for the whole date: "Jun 20, 2026", "Jun 20", or with the
    // weekday in front, "Sat, Jun 20". The year is compared in Gregorian years,
    // the same calendar the date is written in.
    private static func mediumDate(_ date: Date, now: Date, calendar: Calendar, omitCurrentYear: Bool, includeWeekday: Bool, abbreviateWeekday: Bool) -> String {
        let gregorian = gregorianCalendar(timeZoneOf: calendar)
        let omitsYear = omitCurrentYear && gregorian.component(.year, from: date) == gregorian.component(.year, from: now)
        let weekday = includeWeekday ? (abbreviateWeekday ? "EEE, " : "EEEE, ") : ""
        return makeFormatter(weekday + (omitsYear ? "MMM d" : mediumDatePattern), calendar: calendar).string(from: date)
    }
}
