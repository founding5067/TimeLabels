import Testing
import Foundation
@testable import TimeLabels

// Tests for TimeLabel+Duration.swift.

// MARK: - Compact

@Test func duration_compact() {
    #expect(TimeLabel.duration(5400) == "1h 30m")
    #expect(TimeLabel.duration(45) == "45s")
    #expect(TimeLabel.duration(7200) == "2h")
    #expect(TimeLabel.duration(3661) == "1h 1m 1s")
    #expect(TimeLabel.duration(125) == "2m 5s")
    #expect(TimeLabel.duration(0) == "0s")
    #expect(TimeLabel.duration(59.9) == "59s")
}

@Test func duration_compactExpandAndSpace() {
    #expect(TimeLabel.duration(5400, addSpace: true) == "1 h 30 m")
    #expect(TimeLabel.duration(5400, expandUnits: true) == "1hour 30minutes")
    #expect(TimeLabel.duration(5400, expandUnits: true, addSpace: true) == "1 hour 30 minutes")
    #expect(TimeLabel.duration(1, expandUnits: true, addSpace: true) == "1 second")
    #expect(TimeLabel.duration(0, expandUnits: true, addSpace: true) == "0 seconds")
}

// MARK: - Countdown

@Test func duration_countdown() {
    #expect(TimeLabel.duration(5400, style: .countdown) == "1:30:00")
    #expect(TimeLabel.duration(245, style: .countdown) == "4:05")
    #expect(TimeLabel.duration(5, style: .countdown) == "0:05")
    #expect(TimeLabel.duration(0, style: .countdown) == "0:00")
    #expect(TimeLabel.duration(3600, style: .countdown) == "1:00:00")
    #expect(TimeLabel.duration(36_000 + 61, style: .countdown) == "10:01:01")
    // expandUnits / space are ignored.
    #expect(TimeLabel.duration(5400, style: .countdown, expandUnits: true, addSpace: true) == "1:30:00")
}

// MARK: - Invalid input

@Test func duration_invalidInputDoesNotTrap() {
    #expect(TimeLabel.duration(-5) == "0s")
    #expect(TimeLabel.duration(.nan) == "0s")
    #expect(TimeLabel.duration(-.infinity, style: .countdown) == "0:00")
    #expect(TimeLabel.duration(.infinity) == TimeLabel.duration(1e15))
    #expect(TimeLabel.duration(1e300, style: .countdown) == TimeLabel.duration(1e15, style: .countdown))
}

// MARK: - Larger units

@Test func duration_largestUnitDefaultIsHour() {
    #expect(TimeLabel.duration(100_000) == "27h 46m 40s")
    #expect(TimeLabel.duration(100_000, largestUnit: .hour) == TimeLabel.duration(100_000))
}

@Test func duration_largestUnit() {
    #expect(TimeLabel.duration(100_000, largestUnit: .day) == "1d 3h 46m 40s")
    // 1 week + 2 days + 3 hours + 4 minutes + 5 seconds.
    #expect(TimeLabel.duration(788_645, largestUnit: .week) == "1w 2d 3h 4m 5s")
    #expect(TimeLabel.duration(788_645, largestUnit: .day) == "9d 3h 4m 5s")
    #expect(TimeLabel.duration(5400, largestUnit: .minute) == "90m")
    #expect(TimeLabel.duration(5400, largestUnit: .second) == "5400s")
    #expect(TimeLabel.duration(86_400, largestUnit: .day) == "1d")
    #expect(TimeLabel.duration(0, largestUnit: .week) == "0s")
}

@Test func duration_largestUnit_expandAndSpace() {
    #expect(TimeLabel.duration(788_645, expandUnits: true, addSpace: true, largestUnit: .week) == "1 week 2 days 3 hours 4 minutes 5 seconds")
    #expect(TimeLabel.duration(86_400, expandUnits: true, largestUnit: .day) == "1day")
    #expect(TimeLabel.duration(172_800, addSpace: true, largestUnit: .day) == "2 d")
}

// MARK: - Spelled numbers

@Test func duration_spellNumber() {
    // Like every other helper, spellNumbers never adds a space on its own.
    #expect(TimeLabel.duration(5400, spellNumbers: true) == "oneh thirtym")
    #expect(TimeLabel.duration(5400, addSpace: true, spellNumbers: true) == "one h thirty m")
    #expect(TimeLabel.duration(5400, expandUnits: true, addSpace: true, spellNumbers: true) == "one hour thirty minutes")
    #expect(TimeLabel.duration(0, spellNumbers: true) == "zeros")
    #expect(TimeLabel.duration(0, addSpace: true, spellNumbers: true) == "zero s")
    #expect(TimeLabel.duration(0, expandUnits: true, addSpace: true, spellNumbers: true) == "zero seconds")
    // The countdown style ignores spellNumbers and largestUnit.
    #expect(TimeLabel.duration(5400, style: .countdown, spellNumbers: true, largestUnit: .week) == "1:30:00")
}

@Test func duration_newParametersKeepInvalidInputSafe() {
    #expect(TimeLabel.duration(.nan, largestUnit: .week) == "0s")
    #expect(TimeLabel.duration(-.infinity, spellNumbers: true) == "zeros")
    #expect(TimeLabel.duration(.infinity, largestUnit: .week) == TimeLabel.duration(1e15, largestUnit: .week))
}

// MARK: - maximumParts

@Test func duration_maxParts() {
    #expect(TimeLabel.duration(100_000, maximumParts: 2) == "27h 46m")
    #expect(TimeLabel.duration(3661, maximumParts: 2) == "1h 1m")
    // Counting starts at the largest non-zero unit; an empty unit still uses a part.
    #expect(TimeLabel.duration(3601, maximumParts: 2) == "1h")
    #expect(TimeLabel.duration(45, maximumParts: 1) == "45s")
    #expect(TimeLabel.duration(788_645, largestUnit: .week, maximumParts: 3) == "1w 2d 3h")
    #expect(TimeLabel.duration(100_000, expandUnits: true, addSpace: true, maximumParts: 2) == "27 hours 46 minutes")
    #expect(TimeLabel.duration(0, maximumParts: 1) == "0s")
}

@Test func duration_maxPartsBounds() {
    // nil and anything at least as large as the unit count show every part.
    #expect(TimeLabel.duration(788_645, largestUnit: .week, maximumParts: 10) == TimeLabel.duration(788_645, largestUnit: .week))
    #expect(TimeLabel.duration(788_645, largestUnit: .week, maximumParts: nil) == "1w 2d 3h 4m 5s")
    // Zero and negative values are treated as 1.
    #expect(TimeLabel.duration(5400, maximumParts: 0) == "1h")
    #expect(TimeLabel.duration(5400, maximumParts: -3) == "1h")
    // The countdown style ignores it.
    #expect(TimeLabel.duration(5400, style: .countdown, maximumParts: 1) == "1:30:00")
    #expect(TimeLabel.duration(.nan, maximumParts: 1) == "0s")
}

// MARK: - Swift Duration

@Test func duration_swiftDuration() {
    #expect(TimeLabel.duration(.seconds(5400)) == "1h 30m")
    #expect(TimeLabel.duration(.seconds(5400)) == TimeLabel.duration(5400))
    #expect(TimeLabel.duration(.milliseconds(1500)) == "1s")
    #expect(TimeLabel.duration(.seconds(245), style: .countdown) == "4:05")
    #expect(TimeLabel.duration(.seconds(100_000), expandUnits: true, addSpace: true, largestUnit: .day, maximumParts: 2) == "1 day 3 hours")
    #expect(TimeLabel.duration(.seconds(5400), addSpace: true, spellNumbers: true) == "one h thirty m")
}

@Test func duration_swiftDurationInvalidInputDoesNotTrap() {
    #expect(TimeLabel.duration(.seconds(-5)) == "0s")
    #expect(TimeLabel.duration(.zero - .milliseconds(1)) == "0s")
    #expect(TimeLabel.duration(.seconds(Int64.max)) == TimeLabel.duration(1e15))
}
