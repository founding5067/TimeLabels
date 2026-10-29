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
    internal static let dateLabelPattern = "MMM d, yyyy"

    internal static func makeDateLabelFormatter(calendar: Calendar) -> DateFormatter {
        makeFormatter(dateLabelPattern, calendar: calendar)
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

    // Chooses the largest unit in `smallest...largest` that fits at least once
    // into `seconds` (already clamped), falling back to `smallest`, and returns
    // the count of that unit (truncated, or rounded with `.nearest`). A
    // `largest` below `smallest` is treated as `smallest`.
    internal static func components(for seconds: TimeInterval, smallest: Unit, largest: Unit, rounding: Rounding = .down) -> (count: Int, unit: Unit) {
        let whole = Int(seconds)
        var unit = Unit.allCases.last { $0 >= smallest && $0 <= largest && whole >= $0.seconds } ?? smallest
        guard rounding == .nearest else { return (whole / unit.seconds, unit) }

        // A rounded count can reach the next unit up (59.5 minutes -> 60), so
        // keep moving up while it does and the range allows it.
        var count = roundedCount(seconds, unit)
        while unit < largest, let next = Unit(rawValue: unit.rawValue + 1), count * unit.seconds >= next.seconds {
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
    // Spacing is the caller's choice: `expand` only swaps the compact unit for
    // the full word, it never forces a space.
    internal static func phrase(count: Int, unit: Unit, expand: Bool, space: Bool, spellNumber: Bool) -> String {
        joined(count: count, unitText: pluralUnit(count: count, expanded: expand, unit: unit), space: space, spellNumber: spellNumber)
    }

    // Joins a count (digits or spelled out) to an already-chosen unit word.
    // This is the only place a space between number and unit is decided.
    internal static func joined(count: Int, unitText: String, space: Bool, spellNumber: Bool) -> String {
        let number = spellNumber ? spelledNumber(count) : String(count)
        return "\(number)\(space ? " " : "")\(unitText)"
    }

    // Spells integers into words ("25" -> "twenty-five"). Locale is pinned to
    // `en_US_POSIX` so the words are always the same English words. A formatter
    // is built per call because it is only used when `spellNumber` is on.
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
    internal static func pluralUnit(count: Int, expanded: Bool, unit: Unit) -> String {
        let one = count == 1
        if expanded {
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
