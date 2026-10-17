import Foundation

// Shared fixtures for every test file. A fixed reference calendar/timezone and
// a fixed "now" keep formatted output deterministic across machines and
// timezones. All date-based assertions use UTC unless a test says otherwise.

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

// 2021-01-01 15:30:00 UTC (a Friday), used as a fixed "now" / "known" date.
let fixedDate = Date(timeIntervalSince1970: 1_609_515_000)

// `fixedDate` shifted `seconds` into the past / future.
func ago(_ seconds: TimeInterval) -> Date { fixedDate.addingTimeInterval(-seconds) }
func ahead(_ seconds: TimeInterval) -> Date { fixedDate.addingTimeInterval(seconds) }

let day: TimeInterval = 86_400
let week: TimeInterval = 604_800
