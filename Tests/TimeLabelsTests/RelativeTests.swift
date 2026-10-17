import Testing
import Foundation
@testable import TimeLabels

// Tests for TimeLabel+Relative.swift: timeRemaining, timeAgo and relative.

// MARK: - Test cases

private struct Case: Sendable, CustomTestStringConvertible {
    let seconds: TimeInterval
    let expand: Bool
    let space: Bool
    let expected: String
    var testDescription: String { "\(seconds)s expand=\(expand) space=\(space)" }
}

// MARK: - timeRemaining

private let remainingCases: [Case] = [
    // Minutes, plural.
    Case(seconds: 1800, expand: false, space: false, expected: "In 30mins"),
    Case(seconds: 1800, expand: false, space: true, expected: "In 30 mins"),
    // `expand` only picks the word; it never forces a space.
    Case(seconds: 1800, expand: true, space: false, expected: "In 30minutes"),
    Case(seconds: 1800, expand: true, space: true, expected: "In 30 minutes"),
    // Minutes, singular.
    Case(seconds: 60, expand: false, space: false, expected: "In 1min"),
    Case(seconds: 60, expand: false, space: true, expected: "In 1 min"),
    Case(seconds: 60, expand: true, space: false, expected: "In 1minute"),
    Case(seconds: 60, expand: true, space: true, expected: "In 1 minute"),
    // Zero.
    Case(seconds: 0, expand: false, space: false, expected: "In 0mins"),
    Case(seconds: 0, expand: false, space: true, expected: "In 0 mins"),
    Case(seconds: 0, expand: true, space: true, expected: "In 0 minutes"),
    // Hours, singular and plural.
    Case(seconds: 3600, expand: false, space: false, expected: "In 1h"),
    Case(seconds: 3600, expand: false, space: true, expected: "In 1 h"),
    Case(seconds: 3600, expand: true, space: false, expected: "In 1hour"),
    Case(seconds: 3600, expand: true, space: true, expected: "In 1 hour"),
    Case(seconds: 7200, expand: false, space: false, expected: "In 2h"),
    Case(seconds: 7200, expand: true, space: false, expected: "In 2hours"),
    Case(seconds: 86_400, expand: false, space: true, expected: "In 24 h"),
    Case(seconds: 3_600_000, expand: false, space: false, expected: "In 1000h"),
]

@Test(arguments: remainingCases)
private func timeRemaining_permutations(_ c: Case) {
    #expect(TimeLabel.timeRemaining(c.seconds, expand: c.expand, space: c.space) == c.expected)
}

@Test func timeRemaining_boundariesAndTruncation() {
    // Just under the hour stays in minutes; the hour boundary flips to hours.
    #expect(TimeLabel.timeRemaining(3599) == "In 59mins")
    #expect(TimeLabel.timeRemaining(3601) == "In 1h")
    #expect(TimeLabel.timeRemaining(7199) == "In 1h")
    // Under a minute reports 0 minutes.
    #expect(TimeLabel.timeRemaining(59) == "In 0mins")
    // Fractional seconds truncate.
    #expect(TimeLabel.timeRemaining(1800.5) == "In 30mins")
    #expect(TimeLabel.timeRemaining(0.5) == "In 0mins")
    #expect(TimeLabel.timeRemaining(3600.9) == "In 1h")
}

@Test func timeRemaining_invalidInputDoesNotTrap() {
    #expect(TimeLabel.timeRemaining(-1800) == "In 0mins")
    #expect(TimeLabel.timeRemaining(.nan) == "In 0mins")
    #expect(TimeLabel.timeRemaining(-.infinity) == "In 0mins")
    // Huge and infinite values clamp instead of crashing in `Int(...)`.
    #expect(TimeLabel.timeRemaining(.infinity) == TimeLabel.timeRemaining(1e15))
    #expect(TimeLabel.timeRemaining(1e300) == TimeLabel.timeRemaining(1e15))
    #expect(TimeLabel.timeRemaining(1e15).hasSuffix("h"))
}

// MARK: - spellNumber

@Test func timeRemaining_spelledNumber() {
    // spellNumber spells the NUMBER but keeps the unit compact, and does NOT
    // force a space — spacing is the user's choice via `space`.
    #expect(TimeLabel.timeRemaining(25 * 60, spellNumber: true) == "In twenty-fivemins")
    #expect(TimeLabel.timeRemaining(59 * 60, spellNumber: true) == "In fifty-ninemins")
    #expect(TimeLabel.timeRemaining(60, spellNumber: true) == "In onemin")
    #expect(TimeLabel.timeRemaining(0, spellNumber: true) == "In zeromins")
    #expect(TimeLabel.timeRemaining(3600, spellNumber: true) == "In oneh")
    #expect(TimeLabel.timeRemaining(1000 * 3600, spellNumber: true) == "In one thousandh")
    #expect(TimeLabel.timeRemaining(25 * 60, space: true, spellNumber: true) == "In twenty-five mins")
    #expect(TimeLabel.timeRemaining(60, space: true, spellNumber: true) == "In one min")
}

@Test func timeRemaining_spelledNumber_withExpand() {
    #expect(TimeLabel.timeRemaining(25 * 60, expand: true, spellNumber: true) == "In twenty-fiveminutes")
    #expect(TimeLabel.timeRemaining(60, expand: true, spellNumber: true) == "In oneminute")
    #expect(TimeLabel.timeRemaining(3600, expand: true, spellNumber: true) == "In onehour")
    #expect(TimeLabel.timeRemaining(1000 * 3600, expand: true, spellNumber: true) == "In one thousandhours")
    // Add `space: true` for the natural fully-spelled phrases.
    #expect(TimeLabel.timeRemaining(25 * 60, expand: true, space: true, spellNumber: true) == "In twenty-five minutes")
    #expect(TimeLabel.timeRemaining(60, expand: true, space: true, spellNumber: true) == "In one minute")
    #expect(TimeLabel.timeRemaining(3600, expand: true, space: true, spellNumber: true) == "In one hour")
    #expect(TimeLabel.timeRemaining(7200, expand: true, space: true, spellNumber: true) == "In two hours")
    #expect(TimeLabel.timeRemaining(1000 * 3600, expand: true, space: true, spellNumber: true) == "In one thousand hours")
}

// MARK: - timeAgo

private let agoCases: [Case] = [
    Case(seconds: 300, expand: false, space: false, expected: "5mins ago"),
    Case(seconds: 300, expand: false, space: true, expected: "5 mins ago"),
    Case(seconds: 300, expand: true, space: false, expected: "5minutes ago"),
    Case(seconds: 300, expand: true, space: true, expected: "5 minutes ago"),
    Case(seconds: 60, expand: false, space: false, expected: "1min ago"),
    Case(seconds: 60, expand: false, space: true, expected: "1 min ago"),
    Case(seconds: 60, expand: true, space: false, expected: "1minute ago"),
    Case(seconds: 60, expand: true, space: true, expected: "1 minute ago"),
    Case(seconds: 3600, expand: false, space: false, expected: "1h ago"),
    Case(seconds: 3600, expand: false, space: true, expected: "1 h ago"),
    Case(seconds: 3600, expand: true, space: false, expected: "1hour ago"),
    Case(seconds: 3600, expand: true, space: true, expected: "1 hour ago"),
    Case(seconds: 10_800, expand: false, space: false, expected: "3h ago"),
    Case(seconds: 10_800, expand: true, space: false, expected: "3hours ago"),
    Case(seconds: 10_800, expand: true, space: true, expected: "3 hours ago"),
    Case(seconds: 86_400, expand: false, space: true, expected: "24 h ago"),
]

@Test(arguments: agoCases)
private func timeAgo_permutations(_ c: Case) {
    #expect(TimeLabel.timeAgo(ago(c.seconds), now: fixedDate, expand: c.expand, space: c.space) == c.expected)
}

@Test func timeAgo_boundaries() {
    #expect(TimeLabel.timeAgo(ago(0), now: fixedDate) == "Just now")
    #expect(TimeLabel.timeAgo(ago(30), now: fixedDate) == "Just now")
    #expect(TimeLabel.timeAgo(ago(59.999), now: fixedDate) == "Just now")
    #expect(TimeLabel.timeAgo(ago(60), now: fixedDate) == "1min ago")
    #expect(TimeLabel.timeAgo(ago(119), now: fixedDate) == "1min ago")
    #expect(TimeLabel.timeAgo(ago(599), now: fixedDate) == "9mins ago")
    #expect(TimeLabel.timeAgo(ago(3599), now: fixedDate) == "59mins ago")
    #expect(TimeLabel.timeAgo(ago(3600), now: fixedDate) == "1h ago")
    #expect(TimeLabel.timeAgo(ago(7199), now: fixedDate) == "1h ago")
    #expect(TimeLabel.timeAgo(ago(7200), now: fixedDate) == "2h ago")
}

@Test func timeAgo_veryOldDateDoesNotTrap() {
    #expect(TimeLabel.timeAgo(.distantPast, now: fixedDate).hasSuffix("h ago"))
}

@Test func timeAgo_futureDateRendersAsDate() {
    let future = fixedDate.addingTimeInterval(86_400) // 2021-01-02
    let utc = utcCalendar()
    #expect(TimeLabel.timeAgo(future, now: fixedDate, calendar: utc) == "Jan 2, 2021")
    // Regardless of expand/space/spellNumber.
    #expect(TimeLabel.timeAgo(future, now: fixedDate, calendar: utc, expand: true, space: true, spellNumber: true) == "Jan 2, 2021")
    // The calendar's timezone picks the day: 16:00 UTC on Jan 1 is 01:00 Jan 2 in Tokyo.
    let nearFuture = fixedDate.addingTimeInterval(30 * 60)
    #expect(TimeLabel.timeAgo(nearFuture, now: fixedDate, calendar: calendar("Asia/Tokyo")) == "Jan 2, 2021")
    #expect(TimeLabel.timeAgo(nearFuture, now: fixedDate, calendar: utc) == "Jan 1, 2021")
}

@Test func timeAgo_spelledNumber() {
    let now = fixedDate
    #expect(TimeLabel.timeAgo(ago(300), now: now, spellNumber: true) == "fivemins ago")
    #expect(TimeLabel.timeAgo(ago(60), now: now, spellNumber: true) == "onemin ago")
    #expect(TimeLabel.timeAgo(ago(3 * 3600), now: now, spellNumber: true) == "threeh ago")
    #expect(TimeLabel.timeAgo(ago(1000 * 3600), now: now, spellNumber: true) == "one thousandh ago")
    #expect(TimeLabel.timeAgo(ago(300), now: now, space: true, spellNumber: true) == "five mins ago")
    #expect(TimeLabel.timeAgo(ago(60), now: now, space: true, spellNumber: true) == "one min ago")
}

@Test func timeAgo_spelledNumber_withExpand() {
    let now = fixedDate
    #expect(TimeLabel.timeAgo(ago(300), now: now, expand: true, spellNumber: true) == "fiveminutes ago")
    #expect(TimeLabel.timeAgo(ago(60), now: now, expand: true, spellNumber: true) == "oneminute ago")
    #expect(TimeLabel.timeAgo(ago(3 * 3600), now: now, expand: true, spellNumber: true) == "threehours ago")
    #expect(TimeLabel.timeAgo(ago(300), now: now, expand: true, space: true, spellNumber: true) == "five minutes ago")
    #expect(TimeLabel.timeAgo(ago(60), now: now, expand: true, space: true, spellNumber: true) == "one minute ago")
    #expect(TimeLabel.timeAgo(ago(3 * 3600), now: now, expand: true, space: true, spellNumber: true) == "three hours ago")
    #expect(TimeLabel.timeAgo(ago(1000 * 3600), now: now, expand: true, space: true, spellNumber: true) == "one thousand hours ago")
}

// MARK: - Units: days and weeks

@Test func defaultsStillUseHours() {
    // Without `largestUnit`, long gaps stay in hours exactly as before.
    #expect(TimeLabel.timeAgo(ago(3 * day), now: fixedDate) == "72h ago")
    #expect(TimeLabel.timeRemaining(3 * day) == "In 72h")
}

@Test func timeAgo_rollsUpToDaysAndWeeks() {
    #expect(TimeLabel.timeAgo(ago(day - 1), now: fixedDate, largestUnit: .day) == "23h ago")
    #expect(TimeLabel.timeAgo(ago(day), now: fixedDate, largestUnit: .day) == "1d ago")
    #expect(TimeLabel.timeAgo(ago(3 * day), now: fixedDate, largestUnit: .day) == "3d ago")
    // With `.day` as the cap, a week-plus gap stays in days.
    #expect(TimeLabel.timeAgo(ago(week), now: fixedDate, largestUnit: .day) == "7d ago")
    #expect(TimeLabel.timeAgo(ago(6 * day), now: fixedDate, largestUnit: .week) == "6d ago")
    #expect(TimeLabel.timeAgo(ago(week), now: fixedDate, largestUnit: .week) == "1w ago")
    #expect(TimeLabel.timeAgo(ago(2 * week + day), now: fixedDate, largestUnit: .week) == "2w ago")
}

@Test func timeRemaining_rollsUpToDaysAndWeeks() {
    #expect(TimeLabel.timeRemaining(3 * day, largestUnit: .day) == "In 3d")
    #expect(TimeLabel.timeRemaining(2 * week, largestUnit: .week) == "In 2w")
}

@Test func dayAndWeekUnits_expandAndSpace() {
    let threeDays = ago(3 * day)
    #expect(TimeLabel.timeAgo(threeDays, now: fixedDate, space: true, largestUnit: .day) == "3 d ago")
    #expect(TimeLabel.timeAgo(threeDays, now: fixedDate, expand: true, largestUnit: .day) == "3days ago")
    #expect(TimeLabel.timeAgo(threeDays, now: fixedDate, expand: true, space: true, largestUnit: .day) == "3 days ago")
    #expect(TimeLabel.timeAgo(ago(week), now: fixedDate, expand: true, space: true, largestUnit: .week) == "1 week ago")
    #expect(TimeLabel.timeAgo(ago(2 * week), now: fixedDate, expand: true, space: true, largestUnit: .week) == "2 weeks ago")
    #expect(TimeLabel.timeAgo(threeDays, now: fixedDate, space: true, spellNumber: true, largestUnit: .day) == "three d ago")
}

// MARK: - Units: seconds

@Test func secondsGranularity() {
    #expect(TimeLabel.timeRemaining(45, smallestUnit: .second) == "In 45s")
    #expect(TimeLabel.timeRemaining(0, smallestUnit: .second) == "In 0s")
    #expect(TimeLabel.timeRemaining(59, space: true, smallestUnit: .second) == "In 59 s")
    #expect(TimeLabel.timeRemaining(1, expand: true, space: true, smallestUnit: .second) == "In 1 second")
    #expect(TimeLabel.timeRemaining(5, expand: true, space: true, smallestUnit: .second) == "In 5 seconds")
    // Minutes still win once there is at least one.
    #expect(TimeLabel.timeRemaining(60, smallestUnit: .second) == "In 1min")
    #expect(TimeLabel.timeAgo(ago(30), now: fixedDate, smallestUnit: .second) == "30s ago")
    #expect(TimeLabel.timeAgo(ago(1), now: fixedDate, smallestUnit: .second) == "1s ago")
    #expect(TimeLabel.timeAgo(ago(0.5), now: fixedDate, smallestUnit: .second) == "Just now")
    // Default smallest unit is unchanged.
    #expect(TimeLabel.timeAgo(ago(30), now: fixedDate) == "Just now")
}

@Test func unitBoundsAreSafe() {
    // largestUnit below smallestUnit is treated as smallestUnit.
    #expect(TimeLabel.timeRemaining(7200, smallestUnit: .hour, largestUnit: .minute) == "In 2h")
    // Huge values clamp instead of trapping, in every unit.
    #expect(TimeLabel.timeRemaining(.infinity, largestUnit: .week).hasSuffix("w"))
    #expect(TimeLabel.timeRemaining(.nan, smallestUnit: .second) == "In 0s")
}

// MARK: - relative

@Test func relative_choosesDirection() {
    #expect(TimeLabel.relative(ahead(300), now: fixedDate) == "In 5mins")
    #expect(TimeLabel.relative(ago(300), now: fixedDate) == "5mins ago")
    #expect(TimeLabel.relative(ahead(2 * 3600), now: fixedDate, expand: true, space: true) == "In 2 hours")
    #expect(TimeLabel.relative(ago(2 * 3600), now: fixedDate, expand: true, space: true) == "2 hours ago")
    #expect(TimeLabel.relative(ahead(3 * day), now: fixedDate, largestUnit: .day) == "In 3d")
    #expect(TimeLabel.relative(ago(3 * day), now: fixedDate, largestUnit: .day) == "3d ago")
}

@Test func relative_nearZero() {
    #expect(TimeLabel.relative(fixedDate, now: fixedDate) == "Just now")
    #expect(TimeLabel.relative(ago(30), now: fixedDate) == "Just now")
    #expect(TimeLabel.relative(ahead(30), now: fixedDate) == "Now")
    #expect(TimeLabel.relative(ahead(30), now: fixedDate, smallestUnit: .second) == "In 30s")
    #expect(TimeLabel.relative(ahead(0.5), now: fixedDate, smallestUnit: .second) == "Now")
    #expect(TimeLabel.relative(.distantFuture, now: fixedDate).hasPrefix("In "))
    #expect(TimeLabel.relative(.distantPast, now: fixedDate).hasSuffix("h ago"))
}
