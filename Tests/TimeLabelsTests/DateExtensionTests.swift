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
