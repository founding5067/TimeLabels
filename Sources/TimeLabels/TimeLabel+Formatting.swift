//
//  TimeLabel+Formatting.swift
//

import Foundation

// Internal building blocks shared by the public helpers. Nothing here is part
// of the package's public API; it is `internal` so tests can reach it.
extension TimeLabel {
    // Largest duration (in seconds) the relative helpers will format. Anything
    // bigger (including `.infinity`) is clamped so `Int(...)` can never trap.
    internal static let maxSeconds: TimeInterval = 1e15

    // DateFormatter is cheap enough to build per call and, unlike a shared
    // instance, can't be mutated by consumers. A fixed `en_US_POSIX` locale with
    // an explicit `dateFormat` keeps output identical across devices and OS
    // updates (a `.short` style would pick up CLDR changes such as U+202F
    // before AM/PM). It's `internal` so tests can assert the configuration.
    internal static func makeFormatter(_ pattern: String, calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        // `dateFormat` output uses the formatter's own `timeZone` property (not
        // the calendar's), so set it explicitly — otherwise output shifts by
        // the host machine's timezone.
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = pattern
        return formatter
    }

    internal static func makeDateLabelFormatter(calendar: Calendar) -> DateFormatter {
        makeFormatter("MMM d, yyyy", calendar: calendar)
    }

    // NaN and negatives become 0; huge values (incl. infinity) are capped so the
    // later `Int(...)` conversion can't trap.
    internal static func clampedSeconds(_ seconds: TimeInterval) -> TimeInterval {
        seconds.isNaN ? 0 : min(max(seconds, 0), maxSeconds)
    }

    // Chooses the largest unit in `smallest...largest` that fits at least once
    // into `seconds` (already clamped), falling back to `smallest`, and returns
    // the whole-number count of that unit. A `largest` below `smallest` is
    // treated as `smallest`.
    internal static func components(for seconds: TimeInterval, smallest: Unit, largest: Unit) -> (count: Int, unit: Unit) {
        let whole = Int(seconds)
        let unit = Unit.allCases.last { $0 >= smallest && $0 <= largest && whole >= $0.seconds } ?? smallest
        return (whole / unit.seconds, unit)
    }

    // "<number><unit>" shared by `timeRemaining`, `timeAgo` and `relative`.
    // Spacing is the caller's choice: `expand` only swaps the compact unit for
    // the full word, it never forces a space.
    internal static func phrase(count: Int, unit: Unit, expand: Bool, space: Bool, spellNumber: Bool) -> String {
        let number = spellNumber ? spelledNumber(count) : String(count)
        let unitText = pluralUnit(count: count, expanded: expand, unit: unit)
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
