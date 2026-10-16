//
//  TimeLabel.swift
//
//  Created by Cole Braswell on 9/25/26.
//

import Foundation

// Date/time formatting helpers that turn dates and durations into short,
// human-readable UI labels.
//
// The enum body is only used to namespace these helpers; the `public` keyword is
// what actually exposes them to consumers of the Swift package.
public enum TimeLabel {
    // Largest duration (in seconds) the relative helpers will format. Anything
    // bigger (including `.infinity`) is clamped so `Int(...)` can never trap.
    private static let maxSeconds: TimeInterval = 1e15

    /// "In 30mins" / "In 2h" — how much time is left until an event, for
    /// later today. The input is a number of **seconds** (e.g. `3_600` is 1
    /// hour). This is pure arithmetic, so there is no `calendar:` parameter and
    /// the timezone never affects the output. Negative and NaN inputs are
    /// treated as 0, and very large or infinite inputs are clamped.
    /// `expand` only chooses the word: "In 30 minutes" / "In 2 hours" (vs the
    /// compact "In 30mins" / "In 2h"). It never adds a space.
    /// `space` independently adds a space before the unit in the compact form:
    /// "In 30 mins" / "In 2 h". Combine it with `expand` if you want the space
    /// with the full word: "In 30 minutes".
    /// `spellNumber: true` spells the number while keeping the unit compact:
    /// "In twenty-fivemins". It does NOT add a space — spacing is controlled
    /// only by `space`, so pass `space: true` for "In twenty-five mins".
    public static func timeRemaining(_ seconds: TimeInterval, expand: Bool = false, space: Bool = false, spellNumber: Bool = false) -> String {
        let clamped = clampedSeconds(seconds)
        let isHour = clamped >= 3600
        let count = isHour ? Int(clamped) / 3600 : Int(clamped) / 60
        return "In \(phrase(count: count, hours: isHour, expand: expand, space: space, spellNumber: spellNumber))"
    }

    /// "Just now" / "5mins ago" / "3h ago" — an event that has already
    /// happened. `now` defaults to the current time, and the
    /// "Just now" → "X mins" → "X hours" transitions are based on the absolute
    /// time difference, so they don't depend on timezone. A `date` in the
    /// future (after `now`) is rendered as a plain medium-style date
    /// (e.g. "Jun 20, 2026"), where the `calendar:` timezone does matter.
    /// `expand` only chooses the word: "5 minutes ago" / "3 hours ago" (vs the
    /// compact "5mins ago" / "3h ago"). It never adds a space.
    /// `space` independently adds a space before the unit in the compact form:
    /// "5 mins ago" / "3 h ago". Combine it with `expand` if you want the space
    /// with the full word: "5 minutes ago".
    /// `spellNumber: true` spells the number while keeping the unit compact:
    /// "fivemins ago" / "threeh ago". It does NOT add a space — spacing is
    /// controlled only by `space`, so pass `space: true` for "five mins ago".
    public static func timeAgo(_ date: Date, now: Date = Date(), calendar: Calendar = .current, expand: Bool = false, space: Bool = false, spellNumber: Bool = false) -> String {
        let diff = now.timeIntervalSince(date)
        if diff < 0 {
            return makeDateLabelFormatter(calendar: calendar).string(from: date)
        }

        let clamped = clampedSeconds(diff)
        if clamped < 60 {
            return "Just now"
        }
        let isHour = clamped >= 3600
        let count = isHour ? Int(clamped) / 3600 : Int(clamped) / 60
        return "\(phrase(count: count, hours: isHour, expand: expand, space: space, spellNumber: spellNumber)) ago"
    }

    /// Short 12-hour clock time, e.g. "3:30 PM" (with an AM/PM suffix). The
    /// `calendar:` parameter sets the timezone used for the reading; it defaults
    /// to the current device timezone.
    /// Output is deterministic: a fixed `en_US_POSIX` locale and pattern always
    /// produce the 12-hour form with a plain space and no periods (never
    /// "3:30 p.m."), regardless of device locale or OS version.
    public static func time(_ date: Date, calendar: Calendar = .current) -> String {
        makeFormatter("h:mm a", calendar: calendar).string(from: date)
    }

    /// Empty for today, "Tomorrow" for tomorrow, otherwise the medium-style date
    /// (e.g. "Jun 20, 2026"). The `calendar:` parameter sets the timezone, which
    /// affects both the today/tomorrow detection and the formatted date. `now`
    /// defaults to the current time and is what "today" is measured against.
    public static func dateLabel(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> String {
        if calendar.isDate(date, inSameDayAs: now) {
            return ""
        }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
           calendar.isDate(date, inSameDayAs: tomorrow) {
            return "Tomorrow"
        }
        return makeDateLabelFormatter(calendar: calendar).string(from: date)
    }

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
    private static func clampedSeconds(_ seconds: TimeInterval) -> TimeInterval {
        seconds.isNaN ? 0 : min(max(seconds, 0), maxSeconds)
    }

    // "<number><unit>" shared by `timeRemaining` and `timeAgo`. Spacing is the
    // caller's choice: `expand` only swaps the compact unit for the full word,
    // it never forces a space.
    private static func phrase(count: Int, hours: Bool, expand: Bool, space: Bool, spellNumber: Bool) -> String {
        let number = spellNumber ? spelledNumber(count) : String(count)
        let unit = pluralUnit(count: count, expanded: expand, hours: hours)
        return "\(number)\(space ? " " : "")\(unit)"
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

    // Picks the unit word for a count. Compact hours are invariant ("h");
    // minutes use "min"/"mins". The expanded form uses full words with the
    // correct singular/plural ("minute"/"minutes", "hour"/"hours").
    internal static func pluralUnit(count: Int, expanded: Bool, hours: Bool) -> String {
        if expanded {
            return hours ? (count == 1 ? "hour" : "hours") : (count == 1 ? "minute" : "minutes")
        }
        return hours ? "h" : (count == 1 ? "min" : "mins")
    }
}
