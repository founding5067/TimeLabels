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
// what actually exposes them to consumers of the Swift package. The helpers
// themselves live in extensions, one file per concern:
//   TimeLabel+Relative.swift    timeRemaining, timeAgo, relative
//   TimeLabel+Calendar.swift    time, dateLabel
//   TimeLabel+Duration.swift    duration
//   TimeLabel+Formatting.swift  internal shared helpers
public enum TimeLabel {
    /// A unit of time the relative helpers can report in. Use it with the
    /// `smallestUnit:` / `largestUnit:` parameters to choose the range of units a
    /// label may use. The defaults (`.minute` ... `.hour`) keep the original
    /// "5mins ago" / "72h ago" behavior.
    public enum Unit: Int, Comparable, CaseIterable, Sendable {
        case second, minute, hour, day, week

        public static func < (lhs: Unit, rhs: Unit) -> Bool { lhs.rawValue < rhs.rawValue }

        // Length of one of this unit, in seconds.
        internal var seconds: Int {
            switch self {
            case .second: return 1
            case .minute: return 60
            case .hour: return 3600
            case .day: return 86_400
            case .week: return 604_800
            }
        }
    }
}
