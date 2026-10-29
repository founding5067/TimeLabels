//
//  Date+TimeLabel.swift
//

import Foundation

// Convenience wrappers so call sites can write `date.timeAgoLabel()` instead
// of `TimeLabel.timeAgo(date)`. Each one is named after the `TimeLabel`
// function plus "Label" and forwards to it with the same parameters and
// defaults; there is no extra logic here.
extension Date {
    // MARK: - Relative

    /// See `TimeLabel.timeRemaining(until:now:expandUnits:addSpace:spellNumbers:smallestUnit:largestUnit:rounding:)`.
    public func timeRemainingLabel(now: Date = Date(), expandUnits: Bool = false, addSpace: Bool = false, spellNumbers: Bool = false, smallestUnit: TimeLabel.Unit = .minute, largestUnit: TimeLabel.Unit = .hour, rounding: TimeLabel.Rounding = .down) -> String {
        TimeLabel.timeRemaining(until: self, now: now, expandUnits: expandUnits, addSpace: addSpace, spellNumbers: spellNumbers, smallestUnit: smallestUnit, largestUnit: largestUnit, rounding: rounding)
    }

    /// See `TimeLabel.timeAgo(_:now:calendar:expandUnits:addSpace:spellNumbers:smallestUnit:largestUnit:rounding:)`.
    public func timeAgoLabel(now: Date = Date(), calendar: Calendar = .current, expandUnits: Bool = false, addSpace: Bool = false, spellNumbers: Bool = false, smallestUnit: TimeLabel.Unit = .minute, largestUnit: TimeLabel.Unit = .hour, rounding: TimeLabel.Rounding = .down) -> String {
        TimeLabel.timeAgo(self, now: now, calendar: calendar, expandUnits: expandUnits, addSpace: addSpace, spellNumbers: spellNumbers, smallestUnit: smallestUnit, largestUnit: largestUnit, rounding: rounding)
    }

    /// See `TimeLabel.relative(_:now:expandUnits:addSpace:spellNumbers:smallestUnit:largestUnit:rounding:)`.
    public func relativeLabel(now: Date = Date(), expandUnits: Bool = false, addSpace: Bool = false, spellNumbers: Bool = false, smallestUnit: TimeLabel.Unit = .minute, largestUnit: TimeLabel.Unit = .hour, rounding: TimeLabel.Rounding = .down) -> String {
        TimeLabel.relative(self, now: now, expandUnits: expandUnits, addSpace: addSpace, spellNumbers: spellNumbers, smallestUnit: smallestUnit, largestUnit: largestUnit, rounding: rounding)
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

    /// See `TimeLabel.date(_:now:calendar:useRelativeDays:omitCurrentYear:nameToday:includeWeekday:abbreviateWeekday:)`.
    public func dateLabel(now: Date = Date(), calendar: Calendar = .current, useRelativeDays: Bool = false, omitCurrentYear: Bool = false, nameToday: Bool = false, includeWeekday: Bool = false, abbreviateWeekday: Bool = false) -> String {
        TimeLabel.date(self, now: now, calendar: calendar, useRelativeDays: useRelativeDays, omitCurrentYear: omitCurrentYear, nameToday: nameToday, includeWeekday: includeWeekday, abbreviateWeekday: abbreviateWeekday)
    }

    /// See `TimeLabel.dateTime(_:now:calendar:use24Hour:useRelativeDays:omitCurrentYear:nameToday:includeWeekday:abbreviateWeekday:separator:datedSeparator:)`.
    public func dateTimeLabel(now: Date = Date(), calendar: Calendar = .current, use24Hour: Bool = false, useRelativeDays: Bool = false, omitCurrentYear: Bool = false, nameToday: Bool = false, includeWeekday: Bool = false, abbreviateWeekday: Bool = false, separator: String = " at ", datedSeparator: String? = nil) -> String {
        TimeLabel.dateTime(self, now: now, calendar: calendar, use24Hour: use24Hour, useRelativeDays: useRelativeDays, omitCurrentYear: omitCurrentYear, nameToday: nameToday, includeWeekday: includeWeekday, abbreviateWeekday: abbreviateWeekday, separator: separator, datedSeparator: datedSeparator)
    }
}
