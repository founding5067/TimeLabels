//
//  Date+TimeLabel.swift
//

import Foundation

// Convenience wrappers so call sites can write `date.timeAgo()` instead of
// `TimeLabel.timeAgo(date)`. Each one forwards to `TimeLabel` with the same
// parameters and defaults; there is no extra logic here.
extension Date {
    /// See `TimeLabel.timeAgo(_:now:calendar:expand:space:spellNumber:smallestUnit:largestUnit:)`.
    public func timeAgo(now: Date = Date(), calendar: Calendar = .current, expand: Bool = false, space: Bool = false, spellNumber: Bool = false, smallestUnit: TimeLabel.Unit = .minute, largestUnit: TimeLabel.Unit = .hour) -> String {
        TimeLabel.timeAgo(self, now: now, calendar: calendar, expand: expand, space: space, spellNumber: spellNumber, smallestUnit: smallestUnit, largestUnit: largestUnit)
    }

    /// See `TimeLabel.relative(_:now:expand:space:spellNumber:smallestUnit:largestUnit:)`.
    public func relative(now: Date = Date(), expand: Bool = false, space: Bool = false, spellNumber: Bool = false, smallestUnit: TimeLabel.Unit = .minute, largestUnit: TimeLabel.Unit = .hour) -> String {
        TimeLabel.relative(self, now: now, expand: expand, space: space, spellNumber: spellNumber, smallestUnit: smallestUnit, largestUnit: largestUnit)
    }

    /// See `TimeLabel.time(_:calendar:use24Hour:)`.
    public func timeLabel(calendar: Calendar = .current, use24Hour: Bool = false) -> String {
        TimeLabel.time(self, calendar: calendar, use24Hour: use24Hour)
    }

    /// See `TimeLabel.dateLabel(_:now:calendar:relativeDays:)`.
    public func dateLabel(now: Date = Date(), calendar: Calendar = .current, relativeDays: Bool = false) -> String {
        TimeLabel.dateLabel(self, now: now, calendar: calendar, relativeDays: relativeDays)
    }
}
