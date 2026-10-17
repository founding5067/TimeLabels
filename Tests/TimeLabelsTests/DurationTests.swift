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
