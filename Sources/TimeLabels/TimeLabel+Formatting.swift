//
//  TimeLabel+Formatting.swift
//

import Foundation

// Internal building blocks shared by the public helpers. Nothing here is part
// of the package's public API; it is `internal` so tests can reach it.
extension TimeLabel {
    // MARK: - Limits

    // Largest duration (in seconds) the relative and duration helpers will
    // format. Anything bigger (including `.infinity`) is clamped so `Int(...)`
    // can never trap.
    internal static let maxSeconds: TimeInterval = 1e15

    // MARK: - Date formatters

    // DateFormatter is cheap enough to build per call and, unlike a shared
    // instance, can't be mutated by consumers. A fixed `en_US_POSIX` locale with
    // an explicit `dateFormat` keeps output identical across devices and OS
    // updates (a `.short` style would pick up CLDR changes such as U+202F
    // before AM/PM). It's `internal` so tests can assert the configuration.
    // Only the calendar's timezone is used: dates are always written in
    // Gregorian, even for a Hebrew or Japanese `calendar`.
    internal static func makeFormatter(_ pattern: String, calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = gregorianCalendar(timeZoneOf: calendar)
        // `dateFormat` output uses the formatter's own `timeZone` property (not
        // the calendar's), so set it explicitly — otherwise output shifts by
        // the host machine's timezone.
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = pattern
        return formatter
    }

    // The medium-style date: "Jun 20, 2026".
    internal static let mediumDatePattern = "MMM d, yyyy"

    internal static func makeMediumDateFormatter(calendar: Calendar) -> DateFormatter {
        makeFormatter(mediumDatePattern, calendar: calendar)
    }

    // The one place a medium-style date is written, for `date`, `dateTime` and
    // `timeAgo`: "Jun 20, 2026", "Jun 20" with `omitCurrentYear` in `now`'s
    // year, or with the weekday in front, "Sat, Jun 20". The year is compared
    // with the formatter's own (Gregorian) calendar, the one it writes in.
    internal static func mediumDate(_ date: Date, now: Date, calendar: Calendar, omitCurrentYear: Bool = false, includeWeekday: Bool = false, abbreviateWeekday: Bool = false) -> String {
        let formatter = makeMediumDateFormatter(calendar: calendar)
        let gregorian: Calendar = formatter.calendar
        if omitCurrentYear, gregorian.component(.year, from: date) == gregorian.component(.year, from: now) {
            formatter.dateFormat = "MMM d"
        }
        if includeWeekday {
            formatter.dateFormat = (abbreviateWeekday ? "EEE, " : "EEEE, ") + formatter.dateFormat
        }
        return formatter.string(from: date)
    }

    // A Gregorian calendar in `calendar`'s timezone.
    internal static func gregorianCalendar(timeZoneOf calendar: Calendar) -> Calendar {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        return gregorian
    }

    // MARK: - Clamping & unit selection

    // NaN and negatives become 0; huge values (incl. infinity) are capped so the
    // later `Int(...)` conversion can't trap.
    internal static func clampedSeconds(_ seconds: TimeInterval) -> TimeInterval {
        seconds.isNaN ? 0 : min(max(seconds, 0), maxSeconds)
    }

    // Chooses the largest unit in `smallestUnit...largestUnit` that fits at
    // least once into `seconds` (already clamped), falling back to
    // `smallestUnit`, and returns the count of that unit (truncated, or rounded
    // with `.nearest`). A `largestUnit` below `smallestUnit` is treated as
    // `smallestUnit`.
    internal static func components(for seconds: TimeInterval, smallestUnit: Unit, largestUnit: Unit, rounding: Rounding = .down) -> (count: Int, unit: Unit) {
        let whole = Int(seconds)
        var unit = Unit.allCases.last { $0 >= smallestUnit && $0 <= largestUnit && whole >= $0.seconds } ?? smallestUnit
        guard rounding == .nearest else { return (whole / unit.seconds, unit) }

        // A rounded count can reach the next unit up (59.5 minutes -> 60), so
        // keep moving up while it does and the range allows it.
        var count = roundedCount(seconds, unit)
        while unit < largestUnit, let next = Unit(rawValue: unit.rawValue + 1), count * unit.seconds >= next.seconds {
            unit = next
            count = roundedCount(seconds, unit)
        }
        return (count, unit)
    }

    private static func roundedCount(_ seconds: TimeInterval, _ unit: Unit) -> Int {
        Int((seconds / TimeInterval(unit.seconds)).rounded(.toNearestOrAwayFromZero))
    }

    // MARK: - Phrase building

    // "<number><unit>" shared by `timeRemaining`, `timeAgo` and `relative`.
    // Spacing is the caller's choice: `expandUnits` only swaps the compact unit
    // for the full word, it never forces a space.
    internal static func phrase(count: Int, unit: Unit, expandUnits: Bool, addSpace: Bool, spellNumbers: Bool) -> String {
        joined(count: count, unitText: pluralUnit(count: count, expandUnits: expandUnits, unit: unit), addSpace: addSpace, spellNumbers: spellNumbers)
    }

    // Joins a count (digits or spelled out) to an already-chosen unit word.
    // This is the only place a space between number and unit is decided.
    internal static func joined(count: Int, unitText: String, addSpace: Bool, spellNumbers: Bool) -> String {
        let number = spellNumbers ? spelledNumber(count) : String(count)
        return "\(number)\(addSpace ? " " : "")\(unitText)"
    }

    // Spells integers into words ("25" -> "twenty-five"). Locale is pinned to
    // `en_US_POSIX` so the words are always the same English words. A formatter
    // is built per call because it is only used when `spellNumbers` is on.
    internal static func spelledNumber(_ count: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        formatter.locale = Locale(identifier: "en_US_POSIX")
        // Foundation's `spellOut` spells every in-range integer, so
        // `string(for:)` is never nil; a nil here would be a real Foundation
        // bug worth crashing loudly on rather than emitting a wrong label.
        return formatter.string(for: count)!
    }

    // Picks the unit word for a count. Compact seconds, hours, days and weeks
    // are invariant ("s", "h", "d", "w"); minutes use "min"/"mins". The
    // expanded form uses full words with the correct singular/plural
    // ("minute"/"minutes", "hour"/"hours", ...).
    internal static func pluralUnit(count: Int, expandUnits: Bool, unit: Unit) -> String {
        let one = count == 1
        if expandUnits {
            switch unit {
            case .second: return one ? "second" : "seconds"
            case .minute: return one ? "minute" : "minutes"
            case .hour: return one ? "hour" : "hours"
            case .day: return one ? "day" : "days"
            case .week: return one ? "week" : "weeks"
            }
        }
        switch unit {
        case .second: return "s"
        case .minute: return one ? "min" : "mins"
        case .hour: return "h"
        case .day: return "d"
        case .week: return "w"
        }
    }
}
