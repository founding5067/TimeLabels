import Testing
import Foundation
@testable import TimeLabels

// Tests for TimeLabel+Relative.swift: timeRemaining, timeAgo and relative.

// MARK: - Test cases

private struct Case: Sendable, CustomTestStringConvertible {
    let seconds: TimeInterval
    let expandUnits: Bool
    let addSpace: Bool
    let expected: String
    var testDescription: String { "\(seconds)s expandUnits=\(expandUnits) addSpace=\(addSpace)" }
}

// MARK: - timeRemaining

private let remainingCases: [Case] = [
    // Minutes, plural.
    Case(seconds: 1800, expandUnits: false, addSpace: false, expected: "In 30mins"),
    Case(seconds: 1800, expandUnits: false, addSpace: true, expected: "In 30 mins"),
    // `expandUnits` only picks the word; it never forces a space.
    Case(seconds: 1800, expandUnits: true, addSpace: false, expected: "In 30minutes"),
    Case(seconds: 1800, expandUnits: true, addSpace: true, expected: "In 30 minutes"),
    // Minutes, singular.
    Case(seconds: 60, expandUnits: false, addSpace: false, expected: "In 1min"),
    Case(seconds: 60, expandUnits: false, addSpace: true, expected: "In 1 min"),
    Case(seconds: 60, expandUnits: true, addSpace: false, expected: "In 1minute"),
    Case(seconds: 60, expandUnits: true, addSpace: true, expected: "In 1 minute"),
    // Zero.
    Case(seconds: 0, expandUnits: false, addSpace: false, expected: "In 0mins"),
    Case(seconds: 0, expandUnits: false, addSpace: true, expected: "In 0 mins"),
    Case(seconds: 0, expandUnits: true, addSpace: true, expected: "In 0 minutes"),
    // Hours, singular and plural.
    Case(seconds: 3600, expandUnits: false, addSpace: false, expected: "In 1h"),
    Case(seconds: 3600, expandUnits: false, addSpace: true, expected: "In 1 h"),
    Case(seconds: 3600, expandUnits: true, addSpace: false, expected: "In 1hour"),
    Case(seconds: 3600, expandUnits: true, addSpace: true, expected: "In 1 hour"),
    Case(seconds: 7200, expandUnits: false, addSpace: false, expected: "In 2h"),
    Case(seconds: 7200, expandUnits: true, addSpace: false, expected: "In 2hours"),
    Case(seconds: 86_400, expandUnits: false, addSpace: true, expected: "In 24 h"),
    Case(seconds: 3_600_000, expandUnits: false, addSpace: false, expected: "In 1000h"),
]

@Test(arguments: remainingCases)
private func timeRemaining_permutations(_ c: Case) {
    #expect(TimeLabel.timeRemaining(c.seconds, expandUnits: c.expandUnits, addSpace: c.addSpace) == c.expected)
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

// MARK: - spellNumbers

@Test func timeRemaining_spelledNumber() {
    // spellNumbers spells the NUMBER but keeps the unit compact, and does NOT
    // force a space — spacing is the user's choice via `addSpace`.
    #expect(TimeLabel.timeRemaining(25 * 60, spellNumbers: true) == "In twenty-fivemins")
    #expect(TimeLabel.timeRemaining(59 * 60, spellNumbers: true) == "In fifty-ninemins")
    #expect(TimeLabel.timeRemaining(60, spellNumbers: true) == "In onemin")
    #expect(TimeLabel.timeRemaining(0, spellNumbers: true) == "In zeromins")
    #expect(TimeLabel.timeRemaining(3600, spellNumbers: true) == "In oneh")
    #expect(TimeLabel.timeRemaining(1000 * 3600, spellNumbers: true) == "In one thousandh")
    #expect(TimeLabel.timeRemaining(25 * 60, addSpace: true, spellNumbers: true) == "In twenty-five mins")
    #expect(TimeLabel.timeRemaining(60, addSpace: true, spellNumbers: true) == "In one min")
}

@Test func timeRemaining_spelledNumber_withExpand() {
    #expect(TimeLabel.timeRemaining(25 * 60, expandUnits: true, spellNumbers: true) == "In twenty-fiveminutes")
    #expect(TimeLabel.timeRemaining(60, expandUnits: true, spellNumbers: true) == "In oneminute")
    #expect(TimeLabel.timeRemaining(3600, expandUnits: true, spellNumbers: true) == "In onehour")
    #expect(TimeLabel.timeRemaining(1000 * 3600, expandUnits: true, spellNumbers: true) == "In one thousandhours")
    // Add `addSpace: true` for the natural fully-spelled phrases.
    #expect(TimeLabel.timeRemaining(25 * 60, expandUnits: true, addSpace: true, spellNumbers: true) == "In twenty-five minutes")
    #expect(TimeLabel.timeRemaining(60, expandUnits: true, addSpace: true, spellNumbers: true) == "In one minute")
    #expect(TimeLabel.timeRemaining(3600, expandUnits: true, addSpace: true, spellNumbers: true) == "In one hour")
    #expect(TimeLabel.timeRemaining(7200, expandUnits: true, addSpace: true, spellNumbers: true) == "In two hours")
    #expect(TimeLabel.timeRemaining(1000 * 3600, expandUnits: true, addSpace: true, spellNumbers: true) == "In one thousand hours")
}

// MARK: - timeAgo

private let agoCases: [Case] = [
    Case(seconds: 300, expandUnits: false, addSpace: false, expected: "5mins ago"),
    Case(seconds: 300, expandUnits: false, addSpace: true, expected: "5 mins ago"),
    Case(seconds: 300, expandUnits: true, addSpace: false, expected: "5minutes ago"),
    Case(seconds: 300, expandUnits: true, addSpace: true, expected: "5 minutes ago"),
    Case(seconds: 60, expandUnits: false, addSpace: false, expected: "1min ago"),
    Case(seconds: 60, expandUnits: false, addSpace: true, expected: "1 min ago"),
    Case(seconds: 60, expandUnits: true, addSpace: false, expected: "1minute ago"),
    Case(seconds: 60, expandUnits: true, addSpace: true, expected: "1 minute ago"),
    Case(seconds: 3600, expandUnits: false, addSpace: false, expected: "1h ago"),
    Case(seconds: 3600, expandUnits: false, addSpace: true, expected: "1 h ago"),
    Case(seconds: 3600, expandUnits: true, addSpace: false, expected: "1hour ago"),
    Case(seconds: 3600, expandUnits: true, addSpace: true, expected: "1 hour ago"),
    Case(seconds: 10_800, expandUnits: false, addSpace: false, expected: "3h ago"),
    Case(seconds: 10_800, expandUnits: true, addSpace: false, expected: "3hours ago"),
    Case(seconds: 10_800, expandUnits: true, addSpace: true, expected: "3 hours ago"),
    Case(seconds: 86_400, expandUnits: false, addSpace: true, expected: "24 h ago"),
]

@Test(arguments: agoCases)
private func timeAgo_permutations(_ c: Case) {
    #expect(TimeLabel.timeAgo(ago(c.seconds), now: fixedDate, expandUnits: c.expandUnits, addSpace: c.addSpace) == c.expected)
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
    // Regardless of expandUnits/space/spellNumbers.
    #expect(TimeLabel.timeAgo(future, now: fixedDate, calendar: utc, expandUnits: true, addSpace: true, spellNumbers: true) == "Jan 2, 2021")
    // The calendar's timezone picks the day: 16:00 UTC on Jan 1 is 01:00 Jan 2 in Tokyo.
    let nearFuture = fixedDate.addingTimeInterval(30 * 60)
    #expect(TimeLabel.timeAgo(nearFuture, now: fixedDate, calendar: calendar("Asia/Tokyo")) == "Jan 2, 2021")
    #expect(TimeLabel.timeAgo(nearFuture, now: fixedDate, calendar: utc) == "Jan 1, 2021")
}

@Test func timeAgo_spelledNumber() {
    let now = fixedDate
    #expect(TimeLabel.timeAgo(ago(300), now: now, spellNumbers: true) == "fivemins ago")
    #expect(TimeLabel.timeAgo(ago(60), now: now, spellNumbers: true) == "onemin ago")
    #expect(TimeLabel.timeAgo(ago(3 * 3600), now: now, spellNumbers: true) == "threeh ago")
    #expect(TimeLabel.timeAgo(ago(1000 * 3600), now: now, spellNumbers: true) == "one thousandh ago")
    #expect(TimeLabel.timeAgo(ago(300), now: now, addSpace: true, spellNumbers: true) == "five mins ago")
    #expect(TimeLabel.timeAgo(ago(60), now: now, addSpace: true, spellNumbers: true) == "one min ago")
}

@Test func timeAgo_spelledNumber_withExpand() {
    let now = fixedDate
    #expect(TimeLabel.timeAgo(ago(300), now: now, expandUnits: true, spellNumbers: true) == "fiveminutes ago")
    #expect(TimeLabel.timeAgo(ago(60), now: now, expandUnits: true, spellNumbers: true) == "oneminute ago")
    #expect(TimeLabel.timeAgo(ago(3 * 3600), now: now, expandUnits: true, spellNumbers: true) == "threehours ago")
    #expect(TimeLabel.timeAgo(ago(300), now: now, expandUnits: true, addSpace: true, spellNumbers: true) == "five minutes ago")
    #expect(TimeLabel.timeAgo(ago(60), now: now, expandUnits: true, addSpace: true, spellNumbers: true) == "one minute ago")
    #expect(TimeLabel.timeAgo(ago(3 * 3600), now: now, expandUnits: true, addSpace: true, spellNumbers: true) == "three hours ago")
    #expect(TimeLabel.timeAgo(ago(1000 * 3600), now: now, expandUnits: true, addSpace: true, spellNumbers: true) == "one thousand hours ago")
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
    #expect(TimeLabel.timeAgo(threeDays, now: fixedDate, addSpace: true, largestUnit: .day) == "3 d ago")
    #expect(TimeLabel.timeAgo(threeDays, now: fixedDate, expandUnits: true, largestUnit: .day) == "3days ago")
    #expect(TimeLabel.timeAgo(threeDays, now: fixedDate, expandUnits: true, addSpace: true, largestUnit: .day) == "3 days ago")
    #expect(TimeLabel.timeAgo(ago(week), now: fixedDate, expandUnits: true, addSpace: true, largestUnit: .week) == "1 week ago")
    #expect(TimeLabel.timeAgo(ago(2 * week), now: fixedDate, expandUnits: true, addSpace: true, largestUnit: .week) == "2 weeks ago")
    #expect(TimeLabel.timeAgo(threeDays, now: fixedDate, addSpace: true, spellNumbers: true, largestUnit: .day) == "three d ago")
}

// MARK: - Units: seconds

@Test func secondsGranularity() {
    #expect(TimeLabel.timeRemaining(45, smallestUnit: .second) == "In 45s")
    #expect(TimeLabel.timeRemaining(0, smallestUnit: .second) == "In 0s")
    #expect(TimeLabel.timeRemaining(59, addSpace: true, smallestUnit: .second) == "In 59 s")
    #expect(TimeLabel.timeRemaining(1, expandUnits: true, addSpace: true, smallestUnit: .second) == "In 1 second")
    #expect(TimeLabel.timeRemaining(5, expandUnits: true, addSpace: true, smallestUnit: .second) == "In 5 seconds")
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
    #expect(TimeLabel.relative(ahead(2 * 3600), now: fixedDate, expandUnits: true, addSpace: true) == "In 2 hours")
    #expect(TimeLabel.relative(ago(2 * 3600), now: fixedDate, expandUnits: true, addSpace: true) == "2 hours ago")
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

// MARK: - DST

@Test func timeAgo_isPureArithmeticAcrossDST() {
    // Across New York's spring-forward, "yesterday at noon" is only 23 real
    // hours earlier. timeAgo counts elapsed time, not wall-clock days.
    let ny = calendar("America/New_York")
    let now = makeDate(2021, 3, 14, 12, 0, in: ny)
    let before = makeDate(2021, 3, 13, 12, 0, in: ny)
    #expect(TimeLabel.timeAgo(before, now: now, calendar: ny) == "23h ago")
    #expect(TimeLabel.timeAgo(now.addingTimeInterval(-86_400), now: now, calendar: ny) == "24h ago")
    #expect(TimeLabel.timeAgo(now.addingTimeInterval(-86_400), now: now, calendar: ny, largestUnit: .day) == "1d ago")
    #expect(TimeLabel.timeAgo(before, now: now, calendar: ny, largestUnit: .day) == "23h ago")
}

// MARK: - timeRemaining(until:)

@Test func timeRemainingUntil_matchesSeconds() {
    #expect(TimeLabel.timeRemaining(until: ahead(1800), now: fixedDate) == "In 30mins")
    #expect(TimeLabel.timeRemaining(until: ahead(2 * 3600), now: fixedDate, expandUnits: true, addSpace: true) == "In 2 hours")
    #expect(TimeLabel.timeRemaining(until: ahead(3 * day), now: fixedDate, largestUnit: .day) == "In 3d")
    #expect(TimeLabel.timeRemaining(until: ahead(45), now: fixedDate, smallestUnit: .second) == "In 45s")
    for seconds: TimeInterval in [0, 59, 60, 3599, 3600, 100_000] {
        #expect(TimeLabel.timeRemaining(until: ahead(seconds), now: fixedDate) == TimeLabel.timeRemaining(seconds))
    }
}

@Test func timeRemainingUntil_pastDateIsZero() {
    #expect(TimeLabel.timeRemaining(until: ago(300), now: fixedDate) == "In 0mins")
    #expect(TimeLabel.timeRemaining(until: fixedDate, now: fixedDate) == "In 0mins")
}

// MARK: - Rounding

@Test func rounding_defaultTruncates() {
    #expect(TimeLabel.timeRemaining(90 * 60) == "In 1h")
    #expect(TimeLabel.timeRemaining(90 * 60, rounding: .down) == "In 1h")
    #expect(TimeLabel.timeAgo(ago(90 * 60), now: fixedDate) == "1h ago")
    #expect(TimeLabel.relative(ahead(150), now: fixedDate) == "In 2mins")
}

@Test func rounding_nearest() {
    #expect(TimeLabel.timeRemaining(89 * 60, rounding: .nearest) == "In 1h")
    #expect(TimeLabel.timeRemaining(90 * 60, rounding: .nearest) == "In 2h")
    #expect(TimeLabel.timeRemaining(29, rounding: .nearest) == "In 0mins")
    #expect(TimeLabel.timeRemaining(30, rounding: .nearest) == "In 1min")
    #expect(TimeLabel.timeAgo(ago(90 * 60), now: fixedDate, rounding: .nearest) == "2h ago")
    #expect(TimeLabel.timeAgo(ago(90), now: fixedDate, rounding: .nearest) == "2mins ago")
    #expect(TimeLabel.relative(ahead(150), now: fixedDate, rounding: .nearest) == "In 3mins")
    #expect(TimeLabel.relative(ago(150), now: fixedDate, rounding: .nearest) == "3mins ago")
    #expect(TimeLabel.timeRemaining(5400, expandUnits: true, addSpace: true, rounding: .nearest) == "In 2 hours")
}

@Test func rounding_nearestMovesUpAUnit() {
    // 59.5 minutes rounds to 60, which reads as the next unit up.
    #expect(TimeLabel.timeRemaining(3570, rounding: .nearest) == "In 1h")
    // ...unless the range stops there.
    #expect(TimeLabel.timeRemaining(3570, largestUnit: .minute, rounding: .nearest) == "In 60mins")
    // 23.6 hours -> 24h -> 1d, and 6.5 days -> 7d -> 1w.
    #expect(TimeLabel.timeRemaining(84_960, rounding: .nearest) == "In 24h")
    #expect(TimeLabel.timeRemaining(84_960, largestUnit: .day, rounding: .nearest) == "In 1d")
    #expect(TimeLabel.timeRemaining(6.5 * day, largestUnit: .week, rounding: .nearest) == "In 1w")
    #expect(TimeLabel.timeRemaining(59.5, smallestUnit: .second, rounding: .nearest) == "In 1min")
}

@Test func rounding_nearestKeepsJustNowCutoff() {
    // "Just now" / "Now" still cover anything under one smallestUnit.
    #expect(TimeLabel.timeAgo(ago(45), now: fixedDate, rounding: .nearest) == "Just now")
    #expect(TimeLabel.relative(ahead(45), now: fixedDate, rounding: .nearest) == "Now")
}

@Test func rounding_nearestInvalidInputDoesNotTrap() {
    #expect(TimeLabel.timeRemaining(.nan, rounding: .nearest) == "In 0mins")
    #expect(TimeLabel.timeRemaining(-.infinity, rounding: .nearest) == "In 0mins")
    #expect(TimeLabel.timeRemaining(.infinity, largestUnit: .week, rounding: .nearest) == TimeLabel.timeRemaining(1e15, largestUnit: .week, rounding: .nearest))
    #expect(TimeLabel.timeRemaining(1e15, smallestUnit: .second, largestUnit: .second, rounding: .nearest) == "In 1000000000000000s")
}
