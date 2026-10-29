//
//  TimeLabel+Relative.swift
//

import Foundation

// Labels that describe how far a moment is from now: "In 2h", "5mins ago".
extension TimeLabel {
    // MARK: - Time remaining

    /// "In 30mins" / "In 2h" — how much time is left until an event, for
    /// later today. The input is a number of **seconds** (e.g. `3_600` is 1
    /// hour). This is pure arithmetic, so there is no `calendar:` parameter and
    /// the timezone never affects the output. Negative and NaN inputs are
    /// treated as 0, and very large or infinite inputs are clamped.
    /// `smallestUnit` / `largestUnit` bound the units the label may use (for
    /// example `smallestUnit: .second` gives "In 45s", `largestUnit: .day` gives
    /// "In 3d"). The defaults are `.minute` and `.hour`.
    /// `expand` only chooses the word: "In 30 minutes" / "In 2 hours" (vs the
    /// compact "In 30mins" / "In 2h"). It never adds a space.
    /// `space` independently adds a space before the unit in the compact form:
    /// "In 30 mins" / "In 2 h". Combine it with `expand` if you want the space
    /// with the full word: "In 30 minutes".
    /// `spellNumber: true` spells the number while keeping the unit compact:
    /// "In twenty-fivemins". It does NOT add a space — spacing is controlled
    /// only by `space`, so pass `space: true` for "In twenty-five mins".
    /// `rounding: .nearest` rounds to the nearest unit instead of dropping the
    /// partial one: 90 minutes reads "In 2h" rather than "In 1h".
    public static func timeRemaining(_ seconds: TimeInterval, expand: Bool = false, space: Bool = false, spellNumber: Bool = false, smallestUnit: Unit = .minute, largestUnit: Unit = .hour, rounding: Rounding = .down) -> String {
        let (count, unit) = components(for: clampedSeconds(seconds), smallest: smallestUnit, largest: largestUnit, rounding: rounding)
        return "In \(phrase(count: count, unit: unit, expand: expand, space: space, spellNumber: spellNumber))"
    }

    /// `timeRemaining(_:)` measured from `now` to `date`, so you don't have to
    /// subtract the dates yourself. A `date` at or before `now` reads
    /// "In 0mins", exactly like passing a negative number of seconds; use
    /// `relative(_:)` if the label should flip to "ago" once the date passes.
    public static func timeRemaining(until date: Date, now: Date = Date(), expand: Bool = false, space: Bool = false, spellNumber: Bool = false, smallestUnit: Unit = .minute, largestUnit: Unit = .hour, rounding: Rounding = .down) -> String {
        timeRemaining(date.timeIntervalSince(now), expand: expand, space: space, spellNumber: spellNumber, smallestUnit: smallestUnit, largestUnit: largestUnit, rounding: rounding)
    }

    // MARK: - Time ago

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
    /// `smallestUnit` / `largestUnit` bound the units the label may use
    /// (`smallestUnit: .second` gives "30s ago", `largestUnit: .week` gives
    /// "2w ago"). "Just now" covers anything shorter than one `smallestUnit`.
    /// The defaults are `.minute` and `.hour`.
    /// `rounding: .nearest` rounds to the nearest unit (90 minutes reads
    /// "2h ago"); it doesn't move the "Just now" cutoff.
    public static func timeAgo(_ date: Date, now: Date = Date(), calendar: Calendar = .current, expand: Bool = false, space: Bool = false, spellNumber: Bool = false, smallestUnit: Unit = .minute, largestUnit: Unit = .hour, rounding: Rounding = .down) -> String {
        let diff = now.timeIntervalSince(date)
        if diff < 0 {
            return makeDateLabelFormatter(calendar: calendar).string(from: date)
        }

        let clamped = clampedSeconds(diff)
        if clamped < TimeInterval(smallestUnit.seconds) {
            return "Just now"
        }
        let (count, unit) = components(for: clamped, smallest: smallestUnit, largest: largestUnit, rounding: rounding)
        return "\(phrase(count: count, unit: unit, expand: expand, space: space, spellNumber: spellNumber)) ago"
    }

    // MARK: - Relative

    /// Picks "In 5mins" or "5mins ago" automatically from the sign of the
    /// difference between `date` and `now`. Anything shorter than one
    /// `smallestUnit` reads "Now" (future) or "Just now" (past/equal). The
    /// `expand`, `space`, `spellNumber`, `smallestUnit`, `largestUnit` and
    /// `rounding` parameters behave exactly as in `timeRemaining` and `timeAgo`.
    public static func relative(_ date: Date, now: Date = Date(), expand: Bool = false, space: Bool = false, spellNumber: Bool = false, smallestUnit: Unit = .minute, largestUnit: Unit = .hour, rounding: Rounding = .down) -> String {
        let diff = date.timeIntervalSince(now)
        let isFuture = diff > 0
        let clamped = clampedSeconds(abs(diff))
        if clamped < TimeInterval(smallestUnit.seconds) {
            return isFuture ? "Now" : "Just now"
        }
        let (count, unit) = components(for: clamped, smallest: smallestUnit, largest: largestUnit, rounding: rounding)
        let text = phrase(count: count, unit: unit, expand: expand, space: space, spellNumber: spellNumber)
        return isFuture ? "In \(text)" : "\(text) ago"
    }
}
