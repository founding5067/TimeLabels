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
    #expect(TimeLabel.date(fixedDate, now: fixedDate, calendar: utc) == "")
    // Earlier the same day is still today.
    #expect(TimeLabel.date(ago(12_600), now: fixedDate, calendar: utc) == "")
}

@Test func dateLabel_tomorrowIsLabelled() {
    let utc = utcCalendar()
    #expect(TimeLabel.date(fixedDate.addingTimeInterval(86_400), now: fixedDate, calendar: utc) == "Tomorrow")
    // Late tonight (23:59 UTC) is still today; just after midnight is tomorrow.
    let lateTonight = fixedDate.addingTimeInterval(8 * 3600 + 29 * 60)
    #expect(TimeLabel.date(lateTonight, now: fixedDate, calendar: utc) == "")
    #expect(TimeLabel.date(lateTonight.addingTimeInterval(120), now: fixedDate, calendar: utc) == "Tomorrow")
}

@Test func dateLabel_otherDaysAreFormatted() {
    let utc = utcCalendar()
    #expect(TimeLabel.date(fixedDate.addingTimeInterval(2 * 86_400), now: fixedDate, calendar: utc) == "Jan 3, 2021")
    #expect(TimeLabel.date(ago(86_400), now: fixedDate, calendar: utc) == "Dec 31, 2020")
    #expect(TimeLabel.date(ago(86_400 * 365), now: fixedDate, calendar: utc) == "Jan 2, 2020")
}

@Test func dateLabel_timezoneAffectsDetection() {
    // 15:30 UTC on Jan 1 is already Jan 2 (00:30) in Tokyo, so for a Tokyo
    // calendar "now" and an instant 2h earlier fall on different days.
    let tokyo = calendar("Asia/Tokyo")
    let utc = utcCalendar()
    let twoHoursEarlier = ago(2 * 3600) // 13:30 UTC = 22:30 Jan 1 in Tokyo
    #expect(TimeLabel.date(twoHoursEarlier, now: fixedDate, calendar: utc) == "")
    #expect(TimeLabel.date(twoHoursEarlier, now: fixedDate, calendar: tokyo) == "Jan 1, 2021")
}

// MARK: - dateLabel useRelativeDays

@Test func dateLabel_relativeDaysDefaultIsUnchanged() {
    let utc = utcCalendar()
    #expect(TimeLabel.date(ago(day), now: fixedDate, calendar: utc) == "Dec 31, 2020")
    #expect(TimeLabel.date(ahead(3 * day), now: fixedDate, calendar: utc) == "Jan 4, 2021")
}

@Test func dateLabel_relativeDays() {
    let utc = utcCalendar()
    func label(_ d: Date) -> String {
        TimeLabel.date(d, now: fixedDate, calendar: utc, useRelativeDays: true)
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
    #expect(TimeLabel.date(ago(2 * 3600), now: fixedDate, calendar: tokyo, useRelativeDays: true) == "Yesterday")
    #expect(TimeLabel.date(ago(2 * 3600), now: fixedDate, calendar: utcCalendar(), useRelativeDays: true) == "")
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
    #expect(TimeLabel.date(yesterdayNoon, now: now, calendar: ny, useRelativeDays: true) == "Yesterday")
    #expect(TimeLabel.date(tomorrowNoon, now: now, calendar: ny) == "Tomorrow")
    #expect(TimeLabel.date(tomorrowNoon, now: now, calendar: ny, useRelativeDays: true) == "Tomorrow")
}

@Test func dateLabel_fallBackDayIsOneDay() {
    // 2021-11-07 is a 25-hour day in New York; both ends of it are "today".
    let ny = calendar("America/New_York")
    let now = makeDate(2021, 11, 7, 23, 30, in: ny)
    let early = makeDate(2021, 11, 7, 0, 30, in: ny)
    #expect(TimeLabel.date(early, now: now, calendar: ny) == "")
    #expect(TimeLabel.date(early, now: now, calendar: ny, useRelativeDays: true) == "")
    // Just across midnight on either side is tomorrow / yesterday.
    let nextDay = makeDate(2021, 11, 8, 0, 15, in: ny)
    let previousDay = makeDate(2021, 11, 6, 23, 45, in: ny)
    #expect(TimeLabel.date(nextDay, now: now, calendar: ny) == "Tomorrow")
    #expect(TimeLabel.date(nextDay, now: now, calendar: ny, useRelativeDays: true) == "Tomorrow")
    #expect(TimeLabel.date(previousDay, now: now, calendar: ny, useRelativeDays: true) == "Yesterday")
}

@Test func dateLabel_yearBoundary() {
    let utc = utcCalendar()
    let newYearsEve = makeDate(2020, 12, 31, 20, 0, in: utc)
    let newYearsDay = makeDate(2021, 1, 1, 9, 0, in: utc)
    #expect(TimeLabel.date(newYearsDay, now: newYearsEve, calendar: utc) == "Tomorrow")
    #expect(TimeLabel.date(newYearsEve, now: newYearsDay, calendar: utc, useRelativeDays: true) == "Yesterday")
    // Jan 1 2021 was a Friday: two days on is Sunday, two days back is Wednesday.
    #expect(TimeLabel.date(makeDate(2021, 1, 3, 9, 0, in: utc), now: newYearsDay, calendar: utc, useRelativeDays: true) == "Sunday")
    #expect(TimeLabel.date(makeDate(2020, 12, 30, 9, 0, in: utc), now: newYearsDay, calendar: utc, useRelativeDays: true) == "Wednesday")
}

@Test func dateLabel_leapDay() {
    let utc = utcCalendar()
    // 2020 is a leap year: Feb 29 exists and Mar 1 is two days after Feb 28.
    let feb28 = makeDate(2020, 2, 28, 10, 0, in: utc)
    #expect(TimeLabel.date(makeDate(2020, 2, 29, 10, 0, in: utc), now: feb28, calendar: utc) == "Tomorrow")
    let mar1 = makeDate(2020, 3, 1, 10, 0, in: utc)
    #expect(TimeLabel.date(mar1, now: feb28, calendar: utc) == "Mar 1, 2020")
    #expect(TimeLabel.date(mar1, now: feb28, calendar: utc, useRelativeDays: true) == "Sunday")
    // 2021 is not: Mar 1 directly follows Feb 28.
    let feb28b = makeDate(2021, 2, 28, 10, 0, in: utc)
    #expect(TimeLabel.date(makeDate(2021, 3, 1, 10, 0, in: utc), now: feb28b, calendar: utc) == "Tomorrow")
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
    func label(_ d: Date, useRelativeDays: Bool = false) -> String {
        TimeLabel.date(d, now: fixedDate, calendar: utc, useRelativeDays: useRelativeDays, omitCurrentYear: true)
    }
    #expect(label(ahead(2 * day)) == "Jan 3")
    #expect(label(ago(day)) == "Dec 31, 2020")
    #expect(label(fixedDate) == "")
    #expect(label(ahead(day)) == "Tomorrow")
    #expect(label(ahead(7 * day), useRelativeDays: true) == "Jan 8")
    #expect(label(ago(7 * day), useRelativeDays: true) == "Dec 25, 2020")
    #expect(label(ahead(2 * day), useRelativeDays: true) == "Sunday")
}

@Test func dateLabel_omitCurrentYearHonorsTimezone() {
    // Dec 31 15:30 UTC is already Jan 1 in Tokyo, the same year as "now" there.
    #expect(TimeLabel.date(ago(day), now: fixedDate, calendar: calendar("Asia/Tokyo"), omitCurrentYear: true) == "Jan 1")
    #expect(TimeLabel.date(ago(day), now: fixedDate, calendar: utcCalendar(), omitCurrentYear: true) == "Dec 31, 2020")
}

// MARK: - dateTime

@Test func dateTime_combinesDateAndTime() {
    let utc = utcCalendar()
    #expect(TimeLabel.dateTime(fixedDate, now: fixedDate, calendar: utc) == "3:30 PM")
    #expect(TimeLabel.dateTime(ahead(day), now: fixedDate, calendar: utc) == "Tomorrow at 3:30 PM")
    #expect(TimeLabel.dateTime(ahead(2 * day), now: fixedDate, calendar: utc) == "Jan 3, 2021 at 3:30 PM")
    #expect(TimeLabel.dateTime(ahead(2 * day), now: fixedDate, calendar: utc, omitCurrentYear: true) == "Jan 3 at 3:30 PM")
    #expect(TimeLabel.dateTime(ago(day), now: fixedDate, calendar: utc, useRelativeDays: true) == "Yesterday at 3:30 PM")
    #expect(TimeLabel.dateTime(ago(2 * day), now: fixedDate, calendar: utc, useRelativeDays: true) == "Wednesday at 3:30 PM")
    #expect(TimeLabel.dateTime(ahead(day), now: fixedDate, calendar: utc, use24Hour: true) == "Tomorrow at 15:30")
}

// MARK: - dateLabel nameToday, includeWeekday, abbreviateWeekday

@Test func dateLabel_nameToday() {
    let utc = utcCalendar()
    #expect(TimeLabel.date(fixedDate, now: fixedDate, calendar: utc, nameToday: true) == "Today")
    #expect(TimeLabel.date(fixedDate, now: fixedDate, calendar: utc, useRelativeDays: true, nameToday: true) == "Today")
    // Other days are unchanged.
    #expect(TimeLabel.date(ahead(day), now: fixedDate, calendar: utc, nameToday: true) == "Tomorrow")
    #expect(TimeLabel.date(ahead(2 * day), now: fixedDate, calendar: utc, nameToday: true) == "Jan 3, 2021")
}

@Test func dateLabel_abbreviateWeekday() {
    let utc = utcCalendar()
    func label(_ d: Date) -> String {
        TimeLabel.date(d, now: fixedDate, calendar: utc, useRelativeDays: true, abbreviateWeekday: true)
    }
    #expect(label(ahead(2 * day)) == "Sun")
    #expect(label(ahead(6 * day)) == "Thu")
    #expect(label(ago(2 * day)) == "Wed")
    // Named days and dates are unchanged.
    #expect(label(ahead(day)) == "Tomorrow")
    #expect(label(ago(day)) == "Yesterday")
    #expect(label(ahead(7 * day)) == "Jan 8, 2021")
}

@Test func dateLabel_includeWeekday() {
    let utc = utcCalendar()
    func label(_ d: Date, useRelativeDays: Bool = false, abbreviated: Bool = false) -> String {
        TimeLabel.date(d, now: fixedDate, calendar: utc, useRelativeDays: useRelativeDays, omitCurrentYear: true, includeWeekday: true, abbreviateWeekday: abbreviated)
    }
    #expect(label(ahead(2 * day)) == "Sunday, Jan 3")
    #expect(label(ahead(2 * day), abbreviated: true) == "Sun, Jan 3")
    #expect(label(ago(day), abbreviated: true) == "Thu, Dec 31, 2020")
    // Today, tomorrow and useRelativeDays weekday names don't get a second weekday.
    #expect(label(fixedDate) == "")
    #expect(label(ahead(day)) == "Tomorrow")
    #expect(label(ahead(2 * day), useRelativeDays: true) == "Sunday")
    #expect(label(ahead(8 * day), useRelativeDays: true, abbreviated: true) == "Sat, Jan 9")
    // Without omitCurrentYear the full medium date follows the weekday.
    #expect(TimeLabel.date(ahead(2 * day), now: fixedDate, calendar: utc, includeWeekday: true) == "Sunday, Jan 3, 2021")
}

@Test func dateLabel_weekdayHonorsTimezone() {
    // 15:30 UTC Friday is already 00:30 Saturday in Tokyo.
    let tokyo = calendar("Asia/Tokyo")
    #expect(TimeLabel.date(ahead(7 * day), now: ago(7 * day), calendar: tokyo, includeWeekday: true, abbreviateWeekday: true) == "Sat, Jan 9, 2021")
}

// MARK: - dateTime separator and new options

@Test func dateTime_separator() {
    let utc = utcCalendar()
    #expect(TimeLabel.dateTime(ahead(day), now: fixedDate, calendar: utc, separator: " · ") == "Tomorrow · 3:30 PM")
    #expect(TimeLabel.dateTime(ahead(day), now: fixedDate, calendar: utc, separator: " ") == "Tomorrow 3:30 PM")
    // Today's time stands alone, so the separator isn't used.
    #expect(TimeLabel.dateTime(fixedDate, now: fixedDate, calendar: utc, separator: " · ") == "3:30 PM")
    #expect(TimeLabel.dateTime(fixedDate, now: fixedDate, calendar: utc, nameToday: true, separator: " ") == "Today 3:30 PM")
    #expect(TimeLabel.dateTime(fixedDate, now: fixedDate, calendar: utc, nameToday: true) == "Today at 3:30 PM")
}

@Test func dateTime_compactLabels() {
    let utc = utcCalendar()
    // A tight widget line: "Today 3:30 PM", "Sun 3:30 PM", "Jan 8 3:30 PM".
    func compact(_ d: Date, use24Hour: Bool = false) -> String {
        TimeLabel.dateTime(d, now: fixedDate, calendar: utc, use24Hour: use24Hour, useRelativeDays: true, omitCurrentYear: true, nameToday: true, abbreviateWeekday: true, separator: " ")
    }
    #expect(compact(fixedDate) == "Today 3:30 PM")
    #expect(compact(ahead(day)) == "Tomorrow 3:30 PM")
    #expect(compact(ahead(2 * day)) == "Sun 3:30 PM")
    #expect(compact(ahead(7 * day)) == "Jan 8 3:30 PM")
    #expect(compact(ahead(2 * day), use24Hour: true) == "Sun 15:30")

    // A notification line: "3:30 PM", "Tomorrow · 3:30 PM", "Sun, Jan 3 · 3:30 PM".
    func dotted(_ d: Date, use24Hour: Bool = false) -> String {
        TimeLabel.dateTime(d, now: fixedDate, calendar: utc, use24Hour: use24Hour, omitCurrentYear: true, includeWeekday: true, abbreviateWeekday: true, separator: " · ")
    }
    #expect(dotted(fixedDate) == "3:30 PM")
    #expect(dotted(ahead(day)) == "Tomorrow · 3:30 PM")
    #expect(dotted(ahead(2 * day)) == "Sun, Jan 3 · 3:30 PM")
    #expect(dotted(ago(day), use24Hour: true) == "Thu, Dec 31, 2020 · 15:30")
}

@Test func dateLabel_nameTodayWithWeekdayOptions() {
    let utc = utcCalendar()
    // Today stays "Today": includeWeekday only touches medium-style dates.
    #expect(TimeLabel.date(fixedDate, now: fixedDate, calendar: utc, nameToday: true, includeWeekday: true) == "Today")
    #expect(TimeLabel.date(fixedDate, now: fixedDate, calendar: utc, useRelativeDays: true, nameToday: true, includeWeekday: true, abbreviateWeekday: true) == "Today")
    #expect(TimeLabel.dateTime(fixedDate, now: fixedDate, calendar: utc, nameToday: true, includeWeekday: true, separator: " · ") == "Today · 3:30 PM")
}

// MARK: - dateTime datedSeparator

@Test func dateTime_datedSeparator() {
    let utc = utcCalendar()
    // The widget line: a space after named days, a comma after dates.
    func widget(_ d: Date) -> String {
        TimeLabel.dateTime(d, now: fixedDate, calendar: utc, useRelativeDays: true, omitCurrentYear: true, nameToday: true, abbreviateWeekday: true, separator: " ", datedSeparator: ", ")
    }
    #expect(widget(fixedDate) == "Today 3:30 PM")
    #expect(widget(ahead(day)) == "Tomorrow 3:30 PM")
    #expect(widget(ago(day)) == "Yesterday 3:30 PM")
    #expect(widget(ahead(2 * day)) == "Sun 3:30 PM")
    #expect(widget(ahead(7 * day)) == "Jan 8, 3:30 PM")
    #expect(widget(ago(7 * day)) == "Dec 25, 2020, 3:30 PM")
    // Without useRelativeDays, everything past tomorrow is a date.
    #expect(TimeLabel.dateTime(ahead(2 * day), now: fixedDate, calendar: utc, separator: " · ", datedSeparator: ", ") == "Jan 3, 2021, 3:30 PM")
    // nil falls back to separator.
    #expect(TimeLabel.dateTime(ahead(2 * day), now: fixedDate, calendar: utc, separator: " · ") == "Jan 3, 2021 · 3:30 PM")
}

// MARK: - Gregorian output

@Test func dateLabel_alwaysGregorian() {
    // Only the timezone of a non-Gregorian calendar is used.
    for identifier in [Calendar.Identifier.hebrew, .japanese, .buddhist, .islamic] {
        var other = Calendar(identifier: identifier)
        other.timeZone = TimeZone(identifier: "UTC")!
        #expect(TimeLabel.date(ahead(2 * day), now: fixedDate, calendar: other) == "Jan 3, 2021")
        #expect(TimeLabel.date(ahead(2 * day), now: fixedDate, calendar: other, omitCurrentYear: true, includeWeekday: true) == "Sunday, Jan 3")
        #expect(TimeLabel.date(ago(day), now: fixedDate, calendar: other, omitCurrentYear: true) == "Dec 31, 2020")
        #expect(TimeLabel.timeAgo(ahead(2 * day), now: fixedDate, calendar: other) == "Jan 3, 2021")
        #expect(TimeLabel.time(fixedDate, calendar: other) == "3:30 PM")
    }
}
