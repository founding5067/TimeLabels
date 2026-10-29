import Testing
import Foundation
@testable import TimeLabels

// Tests for the internal helpers in TimeLabel+Formatting.swift.

// MARK: - Spelled numbers

@Test func spelledNumber_helper() {
    let expected: [(Int, String)] = [
        (0, "zero"), (1, "one"), (5, "five"), (9, "nine"),
        (10, "ten"), (11, "eleven"), (15, "fifteen"), (19, "nineteen"), (20, "twenty"),
        (24, "twenty-four"), (25, "twenty-five"), (59, "fifty-nine"), (99, "ninety-nine"),
        (60, "sixty"), (100, "one hundred"), (300, "three hundred"), (1000, "one thousand"),
        (3600, "three thousand six hundred"), (100_000, "one hundred thousand"), (1_000_000, "one million"),
    ]
    for (value, words) in expected {
        #expect(TimeLabel.spelledNumber(value) == words)
    }
}

@Test func spelledNumber_neverFallsBackToDigits() {
    // `string(for:)` is non-nil for every in-range count; sample magnitude
    // boundaries to lock that in.
    let samples = [0, 1, 5, 9, 10, 19, 99, 100, 999, 1_000, 9_999, 10_000, 99_999, 100_000, 999_999, 1_000_000, 10_000_000, 100_000_000, 1_000_000_000]
    for c in samples {
        #expect(TimeLabel.spelledNumber(c) != String(c))
    }
}

// MARK: - Formatters

@Test func makeFormatterConfiguration() {
    let ny = calendar("America/New_York")
    let formatter = TimeLabel.makeFormatter("h:mm a", calendar: ny)
    #expect(formatter.locale.identifier == "en_US_POSIX")
    #expect(formatter.calendar == ny)
    #expect(formatter.timeZone == ny.timeZone)
    #expect(formatter.dateFormat == "h:mm a")
}

@Test func makeDateLabelFormatterConfiguration() {
    let utc = utcCalendar()
    let formatter = TimeLabel.makeDateLabelFormatter(calendar: utc)
    #expect(formatter.dateFormat == "MMM d, yyyy")
    #expect(formatter.timeZone == utc.timeZone)
}

// MARK: - Plural units

@Test func pluralUnit_helper() {
    #expect(TimeLabel.pluralUnit(count: 1, expanded: true, unit: .hour) == "hour")
    #expect(TimeLabel.pluralUnit(count: 2, expanded: true, unit: .hour) == "hours")
    #expect(TimeLabel.pluralUnit(count: 1, expanded: true, unit: .minute) == "minute")
    #expect(TimeLabel.pluralUnit(count: 30, expanded: true, unit: .minute) == "minutes")
    #expect(TimeLabel.pluralUnit(count: 1, expanded: false, unit: .hour) == "h")
    #expect(TimeLabel.pluralUnit(count: 2, expanded: false, unit: .hour) == "h")
    #expect(TimeLabel.pluralUnit(count: 1, expanded: false, unit: .minute) == "min")
    #expect(TimeLabel.pluralUnit(count: 30, expanded: false, unit: .minute) == "mins")
    // Seconds, days and weeks.
    #expect(TimeLabel.pluralUnit(count: 1, expanded: true, unit: .second) == "second")
    #expect(TimeLabel.pluralUnit(count: 5, expanded: true, unit: .second) == "seconds")
    #expect(TimeLabel.pluralUnit(count: 1, expanded: true, unit: .day) == "day")
    #expect(TimeLabel.pluralUnit(count: 3, expanded: true, unit: .day) == "days")
    #expect(TimeLabel.pluralUnit(count: 1, expanded: true, unit: .week) == "week")
    #expect(TimeLabel.pluralUnit(count: 2, expanded: true, unit: .week) == "weeks")
    #expect(TimeLabel.pluralUnit(count: 1, expanded: false, unit: .second) == "s")
    #expect(TimeLabel.pluralUnit(count: 3, expanded: false, unit: .day) == "d")
    #expect(TimeLabel.pluralUnit(count: 2, expanded: false, unit: .week) == "w")
}

// MARK: - Unit selection

@Test func components_rounding() {
    let down = TimeLabel.components(for: 5400, smallest: .minute, largest: .hour)
    #expect(down.count == 1 && down.unit == .hour)
    let nearest = TimeLabel.components(for: 5400, smallest: .minute, largest: .hour, rounding: .nearest)
    #expect(nearest.count == 2 && nearest.unit == .hour)
    let promoted = TimeLabel.components(for: 3570, smallest: .minute, largest: .hour, rounding: .nearest)
    #expect(promoted.count == 1 && promoted.unit == .hour)
    // A largest below smallest is still treated as smallest.
    let inverted = TimeLabel.components(for: 7200, smallest: .hour, largest: .minute, rounding: .nearest)
    #expect(inverted.count == 2 && inverted.unit == .hour)
}

// MARK: - Joining

@Test func joined_onlySpaceAddsASpace() {
    #expect(TimeLabel.joined(count: 5, unitText: "mins", space: false, spellNumber: false) == "5mins")
    #expect(TimeLabel.joined(count: 5, unitText: "mins", space: true, spellNumber: false) == "5 mins")
    #expect(TimeLabel.joined(count: 5, unitText: "mins", space: false, spellNumber: true) == "fivemins")
    #expect(TimeLabel.joined(count: 5, unitText: "mins", space: true, spellNumber: true) == "five mins")
}
