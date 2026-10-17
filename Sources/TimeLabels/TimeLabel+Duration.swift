//
//  TimeLabel+Duration.swift
//

import Foundation

// MARK: - Duration style

/// How `TimeLabel.duration(_:style:expand:space:)` lays out a length of time.
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
    ///   "1 hour 30 minutes"). Parts are always separated by one space.
    /// - `.countdown`: "1:30:00" for an hour or more, otherwise "4:05".
    ///   `expand` and `space` are ignored.
    ///
    /// Negative and NaN inputs are treated as 0, and very large or infinite
    /// inputs are clamped, so this never traps.
    public static func duration(_ seconds: TimeInterval, style: DurationStyle = .compact, expand: Bool = false, space: Bool = false) -> String {
        let total = Int(clampedSeconds(seconds))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60

        switch style {
        case .countdown:
            let tail = "\(twoDigits(minutes)):\(twoDigits(secs))"
            return hours > 0 ? "\(hours):\(tail)" : "\(minutes):\(twoDigits(secs))"
        case .compact:
            let parts: [(count: Int, unit: Unit)] = [(hours, .hour), (minutes, .minute), (secs, .second)]
            var words = parts.filter { $0.count > 0 }.map { part in
                compactPart(count: part.count, unit: part.unit, expand: expand, space: space)
            }
            if words.isEmpty {
                words = [compactPart(count: 0, unit: .second, expand: expand, space: space)]
            }
            return words.joined(separator: " ")
        }
    }

    // MARK: - Helpers

    // Compact durations use "m" for minutes (not "min") so "1h 30m" stays short.
    private static func compactPart(count: Int, unit: Unit, expand: Bool, space: Bool) -> String {
        let unitText: String
        if expand {
            unitText = pluralUnit(count: count, expanded: true, unit: unit)
        } else {
            switch unit {
            case .minute: unitText = "m"
            default: unitText = pluralUnit(count: count, expanded: false, unit: unit)
            }
        }
        return "\(count)\(space ? " " : "")\(unitText)"
    }

    private static func twoDigits(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}
