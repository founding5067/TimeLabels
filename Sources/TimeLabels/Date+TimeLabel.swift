//
//  Date+TimeLabel.swift
//

import Foundation

// Convenience wrappers so call sites can write `date.timeAgo()` instead of
// `TimeLabel.timeAgo(date)`. Each one forwards to `TimeLabel` with the same
// parameters and defaults; there is no extra logic here.
extension Date {
    // MARK: - Relative

    /// See `TimeLabel.timeRemaining(until:now:expand:space:spellNumber:smallestUnit:largestUnit:rounding:)`.
    public func timeRemaining(now: Date = Date(), expand: Bool = false, space: Bool = false, spellNumber: Bool = false, smallestUnit: TimeLabel.Unit = .minute, largestUnit: TimeLabel.Unit = .hour, rounding: TimeLabel.Rounding = .down) -> String {
        TimeLabel.timeRemaining(until: self, now: now, expand: expand, space: space, spellNumber: spellNumber, smallestUnit: smallestUnit, largestUnit: largestUnit, rounding: rounding)
    }

    /// See `TimeLabel.timeAgo(_:now:calendar:expand:space:spellNumber:smallestUnit:largestUnit:rounding:)`.
    public func timeAgo(now: Date = Date(), calendar: Calendar = .current, expand: Bool = false, space: Bool = false, spellNumber: Bool = false, smallestUnit: TimeLabel.Unit = .minute, largestUnit: TimeLabel.Unit = .hour, rounding: TimeLabel.Rounding = .down) -> String {
        TimeLabel.timeAgo(self, now: now, calendar: calendar, expand: expand, space: space, spellNumber: spellNumber, smallestUnit: smallestUnit, largestUnit: largestUnit, rounding: rounding)
    }

    /// See `TimeLabel.relative(_:now:expand:space:spellNumber:smallestUnit:largestUnit:rounding:)`.
    public func relative(now: Date = Date(), expand: Bool = false, space: Bool = false, spellNumber: Bool = false, smallestUnit: TimeLabel.Unit = .minute, largestUnit: TimeLabel.Unit = .hour, rounding: TimeLabel.Rounding = .down) -> String {
        TimeLabel.relative(self, now: now, expand: expand, space: space, spellNumber: spellNumber, smallestUnit: smallestUnit, largestUnit: largestUnit, rounding: rounding)
    }

    // MARK: - Calendar

    /// See `TimeLabel.time(_:calendar:use24Hour:)`.
    public func timeLabel(calendar: Calendar = .current, use24Hour: Bool = false) -> String {
        TimeLabel.time(self, calendar: calendar, use24Hour: use24Hour)
    }

    /// See `TimeLabel.timeRange(_:_:calendar:use24Hour:)`.
    public func timeRangeLabel(to end: Date, calendar: Calendar = .current, use24Hour: Bool = false) -> String {
        TimeLabel.timeRange(self, end, calendar: calendar, use24Hour: use24Hour)
    }

    /// See `TimeLabel.dateLabel(_:now:calendar:relativeDays:omitCurrentYear:)`.
    public func dateLabel(now: Date = Date(), calendar: Calendar = .current, relativeDays: Bool = false, omitCurrentYear: Bool = false) -> String {
        TimeLabel.dateLabel(self, now: now, calendar: calendar, relativeDays: relativeDays, omitCurrentYear: omitCurrentYear)
    }

    /// See `TimeLabel.dateTime(_:now:calendar:use24Hour:relativeDays:omitCurrentYear:)`.
    public func dateTimeLabel(now: Date = Date(), calendar: Calendar = .current, use24Hour: Bool = false, relativeDays: Bool = false, omitCurrentYear: Bool = false) -> String {
        TimeLabel.dateTime(self, now: now, calendar: calendar, use24Hour: use24Hour, relativeDays: relativeDays, omitCurrentYear: omitCurrentYear)
    }
}
