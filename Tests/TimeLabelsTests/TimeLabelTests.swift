import Testing
import Foundation
@testable import TimeLabels

// Fixed reference calendar/timezone so formatted output is deterministic across
// machines and timezones. All date-based assertions use UTC.
private func utcCalendar() -> Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "UTC")!
    return c
}

private func calendar(_ identifier: String) -> Calendar {
    var c = utcCalendar()
    c.timeZone = TimeZone(identifier: identifier)!
    return c
}

// 2021-01-01 15:30:00 UTC, used as a fixed "now" / "known" date.
private let fixedDate = Date(timeIntervalSince1970: 1_609_515_000)

// `date` that is `seconds` before `fixedDate`.
private func ago(_ seconds: TimeInterval) -> Date { fixedDate.addingTimeInterval(-seconds) }

private struct Case: Sendable, CustomTestStringConvertible {
    let seconds: TimeInterval
    let expand: Bool
    let space: Bool
    let expected: String
    var testDescription: String { "\(seconds)s expand=\(expand) space=\(space)" }
}

// ---- timeRemaining -------------------------------------------------------

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

// ---- spellNumber ---------------------------------------------------------

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

// ---- timeAgo -------------------------------------------------------------

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

// ---- time ----------------------------------------------------------------

@Test func time_exactOutput() {
    let utc = utcCalendar()
    #expect(TimeLabel.time(fixedDate, calendar: utc) == "3:30 PM")
    let noon = fixedDate.addingTimeInterval(-12_600)    // 12:00 UTC
    let midnight = fixedDate.addingTimeInterval(-55_800) // 00:00 UTC
    #expect(TimeLabel.time(noon, calendar: utc) == "12:00 PM")
    #expect(TimeLabel.time(midnight, calendar: utc) == "12:00 AM")
}

@Test func time_usesPlainSpaceSeparator() {
    // No narrow no-break space (U+202F) before AM/PM, whatever the OS ships.
    #expect(TimeLabel.time(fixedDate, calendar: utcCalendar()).contains("\u{202F}") == false)
}

@Test func time_timezoneShiftsOutput() {
    // 15:30 UTC is 10:30 AM EST (America/New_York is UTC-5 in January).
    #expect(TimeLabel.time(fixedDate, calendar: calendar("America/New_York")) == "10:30 AM")
    // 15:30 UTC + 9h = 12:30 AM next day in Asia/Tokyo.
    #expect(TimeLabel.time(fixedDate, calendar: calendar("Asia/Tokyo")) == "12:30 AM")
}

// ---- dateLabel -----------------------------------------------------------

@Test func dateLabel_todayIsEmpty() {
    let utc = utcCalendar()
    #expect(TimeLabel.dateLabel(fixedDate, now: fixedDate, calendar: utc) == "")
    // Earlier the same day is still today.
    #expect(TimeLabel.dateLabel(ago(12_600), now: fixedDate, calendar: utc) == "")
}

@Test func dateLabel_tomorrowIsLabelled() {
    let utc = utcCalendar()
    #expect(TimeLabel.dateLabel(fixedDate.addingTimeInterval(86_400), now: fixedDate, calendar: utc) == "Tomorrow")
    // Late tonight (23:59 UTC) is still today; just after midnight is tomorrow.
    let lateTonight = fixedDate.addingTimeInterval(8 * 3600 + 29 * 60)
    #expect(TimeLabel.dateLabel(lateTonight, now: fixedDate, calendar: utc) == "")
    #expect(TimeLabel.dateLabel(lateTonight.addingTimeInterval(120), now: fixedDate, calendar: utc) == "Tomorrow")
}

@Test func dateLabel_otherDaysAreFormatted() {
    let utc = utcCalendar()
    #expect(TimeLabel.dateLabel(fixedDate.addingTimeInterval(2 * 86_400), now: fixedDate, calendar: utc) == "Jan 3, 2021")
    #expect(TimeLabel.dateLabel(ago(86_400), now: fixedDate, calendar: utc) == "Dec 31, 2020")
    #expect(TimeLabel.dateLabel(ago(86_400 * 365), now: fixedDate, calendar: utc) == "Jan 2, 2020")
}

@Test func dateLabel_timezoneAffectsDetection() {
    // 15:30 UTC on Jan 1 is already Jan 2 (00:30) in Tokyo, so for a Tokyo
    // calendar "now" and an instant 2h earlier fall on different days.
    let tokyo = calendar("Asia/Tokyo")
    let utc = utcCalendar()
    let twoHoursEarlier = ago(2 * 3600) // 13:30 UTC = 22:30 Jan 1 in Tokyo
    #expect(TimeLabel.dateLabel(twoHoursEarlier, now: fixedDate, calendar: utc) == "")
    #expect(TimeLabel.dateLabel(twoHoursEarlier, now: fixedDate, calendar: tokyo) == "Jan 1, 2021")
}

// ---- Internal helpers (visible via @testable) ----------------------------

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

@Test func pluralUnit_helper() {
    #expect(TimeLabel.pluralUnit(count: 1, expanded: true, hours: true) == "hour")
    #expect(TimeLabel.pluralUnit(count: 2, expanded: true, hours: true) == "hours")
    #expect(TimeLabel.pluralUnit(count: 1, expanded: true, hours: false) == "minute")
    #expect(TimeLabel.pluralUnit(count: 30, expanded: true, hours: false) == "minutes")
    #expect(TimeLabel.pluralUnit(count: 1, expanded: false, hours: true) == "h")
    #expect(TimeLabel.pluralUnit(count: 2, expanded: false, hours: true) == "h")
    #expect(TimeLabel.pluralUnit(count: 1, expanded: false, hours: false) == "min")
    #expect(TimeLabel.pluralUnit(count: 30, expanded: false, hours: false) == "mins")
}
