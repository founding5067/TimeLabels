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
    #expect(TimeLabel.duration(5400, space: true) == "1 h 30 m")
    #expect(TimeLabel.duration(5400, expand: true) == "1hour 30minutes")
    #expect(TimeLabel.duration(5400, expand: true, space: true) == "1 hour 30 minutes")
    #expect(TimeLabel.duration(1, expand: true, space: true) == "1 second")
    #expect(TimeLabel.duration(0, expand: true, space: true) == "0 seconds")
}

// MARK: - Countdown

@Test func duration_countdown() {
    #expect(TimeLabel.duration(5400, style: .countdown) == "1:30:00")
    #expect(TimeLabel.duration(245, style: .countdown) == "4:05")
    #expect(TimeLabel.duration(5, style: .countdown) == "0:05")
    #expect(TimeLabel.duration(0, style: .countdown) == "0:00")
    #expect(TimeLabel.duration(3600, style: .countdown) == "1:00:00")
    #expect(TimeLabel.duration(36_000 + 61, style: .countdown) == "10:01:01")
    // expand / space are ignored.
    #expect(TimeLabel.duration(5400, style: .countdown, expand: true, space: true) == "1:30:00")
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
    #expect(TimeLabel.duration(788_645, expand: true, space: true, largestUnit: .week) == "1 week 2 days 3 hours 4 minutes 5 seconds")
    #expect(TimeLabel.duration(86_400, expand: true, largestUnit: .day) == "1day")
    #expect(TimeLabel.duration(172_800, space: true, largestUnit: .day) == "2 d")
}

// MARK: - Spelled numbers

@Test func duration_spellNumber() {
    // Like every other helper, spellNumber never adds a space on its own.
    #expect(TimeLabel.duration(5400, spellNumber: true) == "oneh thirtym")
    #expect(TimeLabel.duration(5400, space: true, spellNumber: true) == "one h thirty m")
    #expect(TimeLabel.duration(5400, expand: true, space: true, spellNumber: true) == "one hour thirty minutes")
    #expect(TimeLabel.duration(0, spellNumber: true) == "zeros")
    #expect(TimeLabel.duration(0, space: true, spellNumber: true) == "zero s")
    #expect(TimeLabel.duration(0, expand: true, space: true, spellNumber: true) == "zero seconds")
    // The countdown style ignores spellNumber and largestUnit.
    #expect(TimeLabel.duration(5400, style: .countdown, spellNumber: true, largestUnit: .week) == "1:30:00")
}

@Test func duration_newParametersKeepInvalidInputSafe() {
    #expect(TimeLabel.duration(.nan, largestUnit: .week) == "0s")
    #expect(TimeLabel.duration(-.infinity, spellNumber: true) == "zeros")
    #expect(TimeLabel.duration(.infinity, largestUnit: .week) == TimeLabel.duration(1e15, largestUnit: .week))
}
