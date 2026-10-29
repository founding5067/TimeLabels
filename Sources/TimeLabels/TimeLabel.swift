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
//   TimeLabel+Calendar.swift    time, timeRange, date, dateTime
//   TimeLabel+Duration.swift    duration
//   TimeLabel+Formatting.swift  internal shared helpers
//   Date+TimeLabel.swift        `Date` forwarding extensions
//   TimeLabelText.swift         self-refreshing SwiftUI view
//   TimeLabelPreviews.swift     SwiftUI previews (DEBUG only)
public enum TimeLabel {
    // MARK: - Unit

    /// A unit of time the relative helpers can report in. Use it with the
    /// `smallestUnit:` / `largestUnit:` parameters to choose the range of units a
    /// label may use. The defaults (`.minute` ... `.hour`) keep the original
    /// "5mins ago" / "72h ago" behavior. `duration` also takes a `largestUnit:`.
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

    // MARK: - Rounding

    /// How the relative helpers turn a gap into a whole number of units.
    ///
    /// This is a struct rather than an enum so new modes can be added later
    /// without breaking `switch` statements in your code.
    public struct Rounding: Sendable, Hashable {
        internal enum Mode: Sendable, Hashable { case down, nearest }
        internal let mode: Mode

        /// Drop any partial unit, so 89 minutes reads "1h". The default.
        public static let down = Rounding(mode: .down)
        /// Round to the nearest whole unit (halves round up), so 89 minutes
        /// reads "1h" and 90 minutes reads "2h". A result that reaches the
        /// next unit moves up to it: 59.5 minutes reads "1h", not "60mins".
        public static let nearest = Rounding(mode: .nearest)
    }
}
