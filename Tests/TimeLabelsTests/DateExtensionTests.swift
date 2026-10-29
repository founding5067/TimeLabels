import Testing
import Foundation
@testable import TimeLabels

// Tests for Date+TimeLabel.swift: each extension forwards to TimeLabel.

@Test func dateExtensions_forwardToTimeLabel() {
    let utc = utcCalendar()
    let past = ago(300)
    #expect(past.timeAgo(now: fixedDate) == TimeLabel.timeAgo(past, now: fixedDate))
    #expect(past.timeAgo(now: fixedDate, expand: true, space: true) == "5 minutes ago")
    #expect(ahead(300).relative(now: fixedDate) == "In 5mins")
    #expect(past.relative(now: fixedDate) == "5mins ago")
    #expect(fixedDate.timeLabel(calendar: utc) == "3:30 PM")
    #expect(fixedDate.timeLabel(calendar: utc, use24Hour: true) == "15:30")
    #expect(ahead(day).dateLabel(now: fixedDate, calendar: utc) == "Tomorrow")
    #expect(ago(day).dateLabel(now: fixedDate, calendar: utc, relativeDays: true) == "Yesterday")
}

@Test func dateExtensions_forwardNewOptions() {
    let utc = utcCalendar()
    #expect(ahead(1800).timeRemaining(now: fixedDate) == "In 30mins")
    #expect(ahead(5400).timeRemaining(now: fixedDate, rounding: .nearest) == "In 2h")
    #expect(ago(90 * 60).timeAgo(now: fixedDate, rounding: .nearest) == "2h ago")
    #expect(ahead(150).relative(now: fixedDate, rounding: .nearest) == "In 3mins")
    #expect(fixedDate.timeRangeLabel(to: ahead(45 * 60), calendar: utc) == "3:30 – 4:15 PM")
    #expect(ahead(2 * day).dateLabel(now: fixedDate, calendar: utc, omitCurrentYear: true) == "Jan 3")
    #expect(ahead(day).dateTimeLabel(now: fixedDate, calendar: utc) == "Tomorrow at 3:30 PM")
    #expect(ago(day).dateTimeLabel(now: fixedDate, calendar: utc, use24Hour: true, relativeDays: true) == "Yesterday at 15:30")
}

@Test func dateExtensions_forwardWeekdayAndSeparatorOptions() {
    let utc = utcCalendar()
    #expect(fixedDate.dateLabel(now: fixedDate, calendar: utc, nameToday: true) == "Today")
    #expect(ahead(2 * day).dateLabel(now: fixedDate, calendar: utc, relativeDays: true, abbreviateWeekday: true) == "Sun")
    #expect(ahead(2 * day).dateLabel(now: fixedDate, calendar: utc, omitCurrentYear: true, includeWeekday: true) == "Sunday, Jan 3")
    #expect(ahead(day).dateTimeLabel(now: fixedDate, calendar: utc, separator: " · ") == "Tomorrow · 3:30 PM")
    #expect(ahead(7 * day).dateTimeLabel(now: fixedDate, calendar: utc, omitCurrentYear: true, separator: " ", datedSeparator: ", ") == "Jan 8, 3:30 PM")
    #expect(fixedDate.dateTimeLabel(now: fixedDate, calendar: utc, nameToday: true, separator: " ") == "Today 3:30 PM")
    #expect(ahead(2 * day).dateTimeLabel(now: fixedDate, calendar: utc, omitCurrentYear: true, includeWeekday: true, abbreviateWeekday: true) == "Sun, Jan 3 at 3:30 PM")
}
