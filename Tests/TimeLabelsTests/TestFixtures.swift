import Foundation

// Shared fixtures for every test file. A fixed reference calendar/timezone and
// a fixed "now" keep formatted output deterministic across machines and
// timezones. All date-based assertions use UTC unless a test says otherwise.

// MARK: - Calendars

func utcCalendar() -> Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "UTC")!
    return c
}

func calendar(_ identifier: String) -> Calendar {
    var c = utcCalendar()
    c.timeZone = TimeZone(identifier: identifier)!
    return c
}

// MARK: - Dates

// 2021-01-01 15:30:00 UTC (a Friday), used as a fixed "now" / "known" date.
let fixedDate = Date(timeIntervalSince1970: 1_609_515_000)

// `fixedDate` shifted `seconds` into the past / future.
func ago(_ seconds: TimeInterval) -> Date { fixedDate.addingTimeInterval(-seconds) }
func ahead(_ seconds: TimeInterval) -> Date { fixedDate.addingTimeInterval(seconds) }

let day: TimeInterval = 86_400
let week: TimeInterval = 604_800

// MARK: - Building dates

// A `Date` from calendar components, read in `calendar`'s timezone.
func makeDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0, in calendar: Calendar) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}
