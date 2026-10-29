import Testing
import Foundation
@testable import TimeLabels

// Tests for TimeLabel+Calendar.swift: time, timeRange, dateLabel and dateTime.

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

// MARK: - timeRange

@Test func timeRange_sharedSuffix() {
    let utc = utcCalendar()
    #expect(TimeLabel.timeRange(fixedDate, ahead(45 * 60), calendar: utc) == "3:30 – 4:15 PM")
    // 9:00 to 10:00 UTC.
    #expect(TimeLabel.timeRange(ago(6.5 * 3600), ago(5.5 * 3600), calendar: utc) == "9:00 – 10:00 AM")
    // Tokyo is already 00:30 on Jan 2.
    #expect(TimeLabel.timeRange(fixedDate, ahead(3600), calendar: calendar("Asia/Tokyo")) == "12:30 – 1:30 AM")
}

@Test func timeRange_fullTimes() {
    let utc = utcCalendar()
    // Crossing noon.
    #expect(TimeLabel.timeRange(ago(4 * 3600), ago(3.25 * 3600), calendar: utc) == "11:30 AM – 12:15 PM")
    #expect(TimeLabel.timeRange(ago(4.5 * 3600), ago(2 * 3600), calendar: utc) == "11:00 AM – 1:30 PM")
    // Crossing midnight.
    #expect(TimeLabel.timeRange(ahead(8 * 3600), ahead(9 * 3600), calendar: utc) == "11:30 PM – 12:30 AM")
    // Same AM/PM but different days keeps both suffixes.
    #expect(TimeLabel.timeRange(fixedDate, ahead(day + 3600), calendar: utc) == "3:30 PM – 4:30 PM")
    // Reversed input is formatted as given.
    #expect(TimeLabel.timeRange(ahead(45 * 60), fixedDate, calendar: utc) == "4:15 – 3:30 PM")
}

@Test func timeRange_24Hour() {
    let utc = utcCalendar()
    #expect(TimeLabel.timeRange(fixedDate, ahead(45 * 60), calendar: utc, use24Hour: true) == "15:30 – 16:15")
    #expect(TimeLabel.timeRange(ahead(8 * 3600), ahead(9 * 3600), calendar: utc, use24Hour: true) == "23:30 – 00:30")
}

@Test func timeRange_usesSpacedEnDash() {
    #expect(TimeLabel.timeRange(fixedDate, ahead(3600), calendar: utcCalendar()).contains(" \u{2013} "))
}

// MARK: - dateLabel omitCurrentYear

@Test func dateLabel_omitCurrentYear() {
    let utc = utcCalendar()
    func label(_ d: Date, relativeDays: Bool = false) -> String {
        TimeLabel.dateLabel(d, now: fixedDate, calendar: utc, relativeDays: relativeDays, omitCurrentYear: true)
    }
    #expect(label(ahead(2 * day)) == "Jan 3")
    #expect(label(ago(day)) == "Dec 31, 2020")
    #expect(label(fixedDate) == "")
    #expect(label(ahead(day)) == "Tomorrow")
    #expect(label(ahead(7 * day), relativeDays: true) == "Jan 8")
    #expect(label(ago(7 * day), relativeDays: true) == "Dec 25, 2020")
    #expect(label(ahead(2 * day), relativeDays: true) == "Sunday")
}

@Test func dateLabel_omitCurrentYearHonorsTimezone() {
    // Dec 31 15:30 UTC is already Jan 1 in Tokyo, the same year as "now" there.
    #expect(TimeLabel.dateLabel(ago(day), now: fixedDate, calendar: calendar("Asia/Tokyo"), omitCurrentYear: true) == "Jan 1")
    #expect(TimeLabel.dateLabel(ago(day), now: fixedDate, calendar: utcCalendar(), omitCurrentYear: true) == "Dec 31, 2020")
}

// MARK: - dateTime

@Test func dateTime_combinesDateAndTime() {
    let utc = utcCalendar()
    #expect(TimeLabel.dateTime(fixedDate, now: fixedDate, calendar: utc) == "3:30 PM")
    #expect(TimeLabel.dateTime(ahead(day), now: fixedDate, calendar: utc) == "Tomorrow at 3:30 PM")
    #expect(TimeLabel.dateTime(ahead(2 * day), now: fixedDate, calendar: utc) == "Jan 3, 2021 at 3:30 PM")
    #expect(TimeLabel.dateTime(ahead(2 * day), now: fixedDate, calendar: utc, omitCurrentYear: true) == "Jan 3 at 3:30 PM")
    #expect(TimeLabel.dateTime(ago(day), now: fixedDate, calendar: utc, relativeDays: true) == "Yesterday at 3:30 PM")
    #expect(TimeLabel.dateTime(ago(2 * day), now: fixedDate, calendar: utc, relativeDays: true) == "Wednesday at 3:30 PM")
    #expect(TimeLabel.dateTime(ahead(day), now: fixedDate, calendar: utc, use24Hour: true) == "Tomorrow at 15:30")
}

// MARK: - dateLabel namesToday, includesWeekday, abbreviatedWeekday

@Test func dateLabel_namesToday() {
    let utc = utcCalendar()
    #expect(TimeLabel.dateLabel(fixedDate, now: fixedDate, calendar: utc, namesToday: true) == "Today")
    #expect(TimeLabel.dateLabel(fixedDate, now: fixedDate, calendar: utc, relativeDays: true, namesToday: true) == "Today")
    // Other days are unchanged.
    #expect(TimeLabel.dateLabel(ahead(day), now: fixedDate, calendar: utc, namesToday: true) == "Tomorrow")
    #expect(TimeLabel.dateLabel(ahead(2 * day), now: fixedDate, calendar: utc, namesToday: true) == "Jan 3, 2021")
}

@Test func dateLabel_abbreviatedWeekday() {
    let utc = utcCalendar()
    func label(_ d: Date) -> String {
        TimeLabel.dateLabel(d, now: fixedDate, calendar: utc, relativeDays: true, abbreviatedWeekday: true)
    }
    #expect(label(ahead(2 * day)) == "Sun")
    #expect(label(ahead(6 * day)) == "Thu")
    #expect(label(ago(2 * day)) == "Wed")
    // Named days and dates are unchanged.
    #expect(label(ahead(day)) == "Tomorrow")
    #expect(label(ago(day)) == "Yesterday")
    #expect(label(ahead(7 * day)) == "Jan 8, 2021")
}

@Test func dateLabel_includesWeekday() {
    let utc = utcCalendar()
    func label(_ d: Date, relativeDays: Bool = false, abbreviated: Bool = false) -> String {
        TimeLabel.dateLabel(d, now: fixedDate, calendar: utc, relativeDays: relativeDays, omitCurrentYear: true, includesWeekday: true, abbreviatedWeekday: abbreviated)
    }
    #expect(label(ahead(2 * day)) == "Sunday, Jan 3")
    #expect(label(ahead(2 * day), abbreviated: true) == "Sun, Jan 3")
    #expect(label(ago(day), abbreviated: true) == "Thu, Dec 31, 2020")
    // Today, tomorrow and relativeDays weekday names don't get a second weekday.
    #expect(label(fixedDate) == "")
    #expect(label(ahead(day)) == "Tomorrow")
    #expect(label(ahead(2 * day), relativeDays: true) == "Sunday")
    #expect(label(ahead(8 * day), relativeDays: true, abbreviated: true) == "Sat, Jan 9")
    // Without omitCurrentYear the full medium date follows the weekday.
    #expect(TimeLabel.dateLabel(ahead(2 * day), now: fixedDate, calendar: utc, includesWeekday: true) == "Sunday, Jan 3, 2021")
}

@Test func dateLabel_weekdayHonorsTimezone() {
    // 15:30 UTC Friday is already 00:30 Saturday in Tokyo.
    let tokyo = calendar("Asia/Tokyo")
    #expect(TimeLabel.dateLabel(ahead(7 * day), now: ago(7 * day), calendar: tokyo, includesWeekday: true, abbreviatedWeekday: true) == "Sat, Jan 9, 2021")
}

// MARK: - dateTime separator and new options

@Test func dateTime_separator() {
    let utc = utcCalendar()
    #expect(TimeLabel.dateTime(ahead(day), now: fixedDate, calendar: utc, separator: " · ") == "Tomorrow · 3:30 PM")
    #expect(TimeLabel.dateTime(ahead(day), now: fixedDate, calendar: utc, separator: " ") == "Tomorrow 3:30 PM")
    // Today's time stands alone, so the separator isn't used.
    #expect(TimeLabel.dateTime(fixedDate, now: fixedDate, calendar: utc, separator: " · ") == "3:30 PM")
    #expect(TimeLabel.dateTime(fixedDate, now: fixedDate, calendar: utc, namesToday: true, separator: " ") == "Today 3:30 PM")
    #expect(TimeLabel.dateTime(fixedDate, now: fixedDate, calendar: utc, namesToday: true) == "Today at 3:30 PM")
}

@Test func dateTime_compactLabels() {
    let utc = utcCalendar()
    // A tight widget line: "Today 3:30 PM", "Sun 3:30 PM", "Jan 8 3:30 PM".
    func compact(_ d: Date, use24Hour: Bool = false) -> String {
        TimeLabel.dateTime(d, now: fixedDate, calendar: utc, use24Hour: use24Hour, relativeDays: true, omitCurrentYear: true, namesToday: true, abbreviatedWeekday: true, separator: " ")
    }
    #expect(compact(fixedDate) == "Today 3:30 PM")
    #expect(compact(ahead(day)) == "Tomorrow 3:30 PM")
    #expect(compact(ahead(2 * day)) == "Sun 3:30 PM")
    #expect(compact(ahead(7 * day)) == "Jan 8 3:30 PM")
    #expect(compact(ahead(2 * day), use24Hour: true) == "Sun 15:30")

    // A notification line: "3:30 PM", "Tomorrow · 3:30 PM", "Sun, Jan 3 · 3:30 PM".
    func dotted(_ d: Date, use24Hour: Bool = false) -> String {
        TimeLabel.dateTime(d, now: fixedDate, calendar: utc, use24Hour: use24Hour, omitCurrentYear: true, includesWeekday: true, abbreviatedWeekday: true, separator: " · ")
    }
    #expect(dotted(fixedDate) == "3:30 PM")
    #expect(dotted(ahead(day)) == "Tomorrow · 3:30 PM")
    #expect(dotted(ahead(2 * day)) == "Sun, Jan 3 · 3:30 PM")
    #expect(dotted(ago(day), use24Hour: true) == "Thu, Dec 31, 2020 · 15:30")
}
