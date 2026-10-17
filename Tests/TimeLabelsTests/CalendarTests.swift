import Testing
import Foundation
@testable import TimeLabels

// Tests for TimeLabel+Calendar.swift: time and dateLabel.

// MARK: - time

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

@Test func time_24Hour() {
    let utc = utcCalendar()
    #expect(TimeLabel.time(fixedDate, calendar: utc, use24Hour: true) == "15:30")
    #expect(TimeLabel.time(fixedDate.addingTimeInterval(-55_800), calendar: utc, use24Hour: true) == "00:00")
    #expect(TimeLabel.time(fixedDate.addingTimeInterval(-12_600), calendar: utc, use24Hour: true) == "12:00")
    #expect(TimeLabel.time(fixedDate, calendar: calendar("Asia/Tokyo"), use24Hour: true) == "00:30")
    // Default is still 12-hour.
    #expect(TimeLabel.time(fixedDate, calendar: utc) == "3:30 PM")
}

// MARK: - dateLabel

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

// MARK: - dateLabel relativeDays

@Test func dateLabel_relativeDaysDefaultIsUnchanged() {
    let utc = utcCalendar()
    #expect(TimeLabel.dateLabel(ago(day), now: fixedDate, calendar: utc) == "Dec 31, 2020")
    #expect(TimeLabel.dateLabel(ahead(3 * day), now: fixedDate, calendar: utc) == "Jan 4, 2021")
}

@Test func dateLabel_relativeDays() {
    let utc = utcCalendar()
    func label(_ d: Date) -> String {
        TimeLabel.dateLabel(d, now: fixedDate, calendar: utc, relativeDays: true)
    }
    #expect(label(fixedDate) == "")
    #expect(label(ahead(day)) == "Tomorrow")
    #expect(label(ago(day)) == "Yesterday")
    // Friday Jan 1 + 2 days = Sunday; - 2 days = Wednesday.
    #expect(label(ahead(2 * day)) == "Sunday")
    #expect(label(ago(2 * day)) == "Wednesday")
    // 6 days is the last weekday name; 7 falls back to the date.
    #expect(label(ahead(6 * day)) == "Thursday")
    #expect(label(ago(6 * day)) == "Saturday")
    #expect(label(ahead(7 * day)) == "Jan 8, 2021")
    #expect(label(ago(7 * day)) == "Dec 25, 2020")
}

@Test func dateLabel_relativeDaysHonorsTimezone() {
    // 15:30 UTC Jan 1 is 00:30 Jan 2 in Tokyo, so 13:30 UTC is "Yesterday" there.
    let tokyo = calendar("Asia/Tokyo")
    #expect(TimeLabel.dateLabel(ago(2 * 3600), now: fixedDate, calendar: tokyo, relativeDays: true) == "Yesterday")
    #expect(TimeLabel.dateLabel(ago(2 * 3600), now: fixedDate, calendar: utcCalendar(), relativeDays: true) == "")
}

// MARK: - DST and calendar edge cases

@Test func dateLabel_springForwardDayIsStillAdjacent() {
    // 2021-03-14 is a 23-hour day in New York (clocks jump 2:00 -> 3:00), so
    // "yesterday at noon" is only 23 real hours away. Days are counted on the
    // calendar, not as 24-hour blocks.
    let ny = calendar("America/New_York")
    let now = makeDate(2021, 3, 14, 12, 0, in: ny)
    let yesterdayNoon = makeDate(2021, 3, 13, 12, 0, in: ny)
    let tomorrowNoon = makeDate(2021, 3, 15, 12, 0, in: ny)
    #expect(now.timeIntervalSince(yesterdayNoon) == 23 * 3600)
    #expect(TimeLabel.dateLabel(yesterdayNoon, now: now, calendar: ny, relativeDays: true) == "Yesterday")
    #expect(TimeLabel.dateLabel(tomorrowNoon, now: now, calendar: ny) == "Tomorrow")
    #expect(TimeLabel.dateLabel(tomorrowNoon, now: now, calendar: ny, relativeDays: true) == "Tomorrow")
}

@Test func dateLabel_fallBackDayIsOneDay() {
    // 2021-11-07 is a 25-hour day in New York; both ends of it are "today".
    let ny = calendar("America/New_York")
    let now = makeDate(2021, 11, 7, 23, 30, in: ny)
    let early = makeDate(2021, 11, 7, 0, 30, in: ny)
    #expect(TimeLabel.dateLabel(early, now: now, calendar: ny) == "")
    #expect(TimeLabel.dateLabel(early, now: now, calendar: ny, relativeDays: true) == "")
    // Just across midnight on either side is tomorrow / yesterday.
    let nextDay = makeDate(2021, 11, 8, 0, 15, in: ny)
    let previousDay = makeDate(2021, 11, 6, 23, 45, in: ny)
    #expect(TimeLabel.dateLabel(nextDay, now: now, calendar: ny) == "Tomorrow")
    #expect(TimeLabel.dateLabel(nextDay, now: now, calendar: ny, relativeDays: true) == "Tomorrow")
    #expect(TimeLabel.dateLabel(previousDay, now: now, calendar: ny, relativeDays: true) == "Yesterday")
}

@Test func dateLabel_yearBoundary() {
    let utc = utcCalendar()
    let newYearsEve = makeDate(2020, 12, 31, 20, 0, in: utc)
    let newYearsDay = makeDate(2021, 1, 1, 9, 0, in: utc)
    #expect(TimeLabel.dateLabel(newYearsDay, now: newYearsEve, calendar: utc) == "Tomorrow")
    #expect(TimeLabel.dateLabel(newYearsEve, now: newYearsDay, calendar: utc, relativeDays: true) == "Yesterday")
    // Jan 1 2021 was a Friday: two days on is Sunday, two days back is Wednesday.
    #expect(TimeLabel.dateLabel(makeDate(2021, 1, 3, 9, 0, in: utc), now: newYearsDay, calendar: utc, relativeDays: true) == "Sunday")
    #expect(TimeLabel.dateLabel(makeDate(2020, 12, 30, 9, 0, in: utc), now: newYearsDay, calendar: utc, relativeDays: true) == "Wednesday")
}

@Test func dateLabel_leapDay() {
    let utc = utcCalendar()
    // 2020 is a leap year: Feb 29 exists and Mar 1 is two days after Feb 28.
    let feb28 = makeDate(2020, 2, 28, 10, 0, in: utc)
    #expect(TimeLabel.dateLabel(makeDate(2020, 2, 29, 10, 0, in: utc), now: feb28, calendar: utc) == "Tomorrow")
    let mar1 = makeDate(2020, 3, 1, 10, 0, in: utc)
    #expect(TimeLabel.dateLabel(mar1, now: feb28, calendar: utc) == "Mar 1, 2020")
    #expect(TimeLabel.dateLabel(mar1, now: feb28, calendar: utc, relativeDays: true) == "Sunday")
    // 2021 is not: Mar 1 directly follows Feb 28.
    let feb28b = makeDate(2021, 2, 28, 10, 0, in: utc)
    #expect(TimeLabel.dateLabel(makeDate(2021, 3, 1, 10, 0, in: utc), now: feb28b, calendar: utc) == "Tomorrow")
}
