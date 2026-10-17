//
//  TimeLabel+Duration.swift
//

import Foundation

// MARK: - Duration style

/// How `TimeLabel.duration(_:style:expand:space:spellNumber:largestUnit:)` lays
/// out a length of time.
public enum DurationStyle: Sendable {
    /// "1h 30m" / "45s" — zero parts are dropped.
    case compact
    /// "1:30:00" / "4:05" — a timer-style readout.
    case countdown
}

extension TimeLabel {
    // MARK: - Duration

    /// A length of time (in **seconds**) as a plain duration, with no "In" or
    /// "ago" wrapper.
    ///
    /// - `.compact` (default): "1h 30m", "45s", "2h". Zero parts are dropped and
    ///   zero itself is "0s". `expand` swaps in full words ("1hour 30minutes")
    ///   and `space` adds a space before each unit ("1 h 30 m", or with `expand`
    ///   "1 hour 30 minutes"). `spellNumber` spells each count ("twoh thirtym";
    ///   add `space` for "two h thirty m"). Like everywhere else, only `space`
    ///   adds a space between a number and its unit; parts are always separated
    ///   by one space.
    ///   `largestUnit` caps the biggest unit used and defaults to `.hour`, so
    ///   100,000 seconds is "27h 46m 40s". With `largestUnit: .day` it is
    ///   "1d 3h 46m 40s"; `.week`, `.minute` and `.second` work too. Units above
    ///   the cap fold into it.
    /// - `.countdown`: "1:30:00" for an hour or more, otherwise "4:05".
    ///   `expand`, `space`, `spellNumber` and `largestUnit` are ignored.
    ///
    /// Negative and NaN inputs are treated as 0, and very large or infinite
    /// inputs are clamped, so this never traps.
    public static func duration(_ seconds: TimeInterval, style: DurationStyle = .compact, expand: Bool = false, space: Bool = false, spellNumber: Bool = false, largestUnit: Unit = .hour) -> String {
        let total = Int(clampedSeconds(seconds))

        switch style {
        case .countdown:
            let hours = total / 3600
            let minutes = (total % 3600) / 60
            let secs = total % 60
            if hours > 0 {
                return "\(hours):\(twoDigits(minutes)):\(twoDigits(secs))"
            }
            return "\(minutes):\(twoDigits(secs))"
        case .compact:
            // Walk from the largest allowed unit down to seconds, peeling off
            // whole units; anything above `largestUnit` stays in that unit.
            var remainder = total
            var words: [String] = []
            for unit in Unit.allCases.reversed() where unit <= largestUnit {
                let count = remainder / unit.seconds
                remainder %= unit.seconds
                if count > 0 {
                    words.append(compactPart(count: count, unit: unit, expand: expand, space: space, spellNumber: spellNumber))
                }
            }
            if words.isEmpty {
                words = [compactPart(count: 0, unit: .second, expand: expand, space: space, spellNumber: spellNumber)]
            }
            return words.joined(separator: " ")
        }
    }

    // MARK: - Helpers

    // Compact durations use "m" for minutes (not "min") so "1h 30m" stays short.
    private static func compactPart(count: Int, unit: Unit, expand: Bool, space: Bool, spellNumber: Bool) -> String {
        let unitText: String
        if expand {
            unitText = pluralUnit(count: count, expanded: true, unit: unit)
        } else {
            switch unit {
            case .minute: unitText = "m"
            default: unitText = pluralUnit(count: count, expanded: false, unit: unit)
            }
        }
        let number = spellNumber ? spelledNumber(count) : String(count)
        return "\(number)\(space ? " " : "")\(unitText)"
    }

    private static func twoDigits(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}
