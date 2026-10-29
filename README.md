# TimeLabels

[![CI](https://github.com/founding5067/TimeLabels/actions/workflows/test.yml/badge.svg)](https://github.com/founding5067/TimeLabels/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/github/license/founding5067/TimeLabels)](LICENSE)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ffounding5067%2FTimeLabels%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/founding5067/TimeLabels)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ffounding5067%2FTimeLabels%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/founding5067/TimeLabels)


Reusable date/time **formatting** helpers for Swift. Turns raw `Date`s and
time intervals into the short, human-readable strings you want to show in a
UI — "In 2h", "5mins ago", "3:30 PM", "Tomorrow" — without duplicating
`DateFormatter` setup across your screens.

## Features

- `timeRemaining(_:)` / `timeRemaining(until:)` — time **until** an event ("In 30mins" / "In 2h"), from seconds or a `Date`
- `timeAgo(_:)` — time **since** an event ("Just now" / "5mins ago" / a date)
- `relative(_:)` — picks "In 5mins" or "5mins ago" automatically
- `duration(_:)` — a plain length of time ("1h 30m", or timer-style "1:30:00"), from seconds or a Swift `Duration`, optionally trimmed with `maxParts:` ("27h 46m")
- `time(_:)` — short clock time ("3:30 PM", or "15:30" with `use24Hour: true`)
- `timeRange(_:_:)` — a span of clock times ("3:30 – 4:15 PM" / "11:00 AM – 1:30 PM")
- `dateLabel(_:)` — contextual date label ("" for today, "Tomorrow", else "Jun 20, 2026"; with `relativeDays: true` also "Yesterday" and weekday names; with `omitCurrentYear: true` "Jun 20" for this year; `namesToday:`, `includesWeekday:` and `abbreviatedWeekday:` for "Today", "Sat, Jun 20" and "Sat")
- `dateTime(_:)` — date and time together ("Tomorrow at 3:30 PM"), with a custom `separator:` ("Tomorrow · 3:30 PM", "Sat 3:30 PM")
- Seconds, days and weeks via `smallestUnit:` / `largestUnit:` ("30s ago", "3d ago", "2w ago")
- Round to the nearest unit with `rounding: .nearest` (90 minutes reads "2h ago" instead of "1h ago")
- `Date` extensions (`date.timeAgo()`, `date.relative()`, ...) and a self-updating SwiftUI `TimeLabelText`
- Thread-safe: no shared mutable state (each call builds its own formatter)
- Deterministic output: a fixed `en_US_POSIX` locale and pattern so results don't drift with the device locale or OS version
- Testable: every date-based helper (`timeAgo`, `relative`, `timeRemaining(until:)`, `dateLabel`, `dateTime`) takes a `now:` parameter

## Requirements

- Swift 6.0+
- iOS 16+, macOS 13+, watchOS 9+, tvOS 16+, visionOS 1+ (CI builds every Apple platform and tests on macOS, on both the oldest and newest supported Xcode, and on Linux)

## Installation

Add the package as a dependency in your `Package.swift`, then resolve it.

### Swift Package Manager (Xcode)

1. **File > Add Package Dependencies...**
2. Enter the repository URL: `https://github.com/founding5067/TimeLabels`
3. Choose **Dependency Rule: Up to Next Major Version** starting at `1.3.0`

### Swift Package Manager (command line)

Add the package to the `dependencies` array in your `Package.swift`, and the
product to your target's dependencies:

```swift
.package(url: "https://github.com/founding5067/TimeLabels", from: "1.3.0")
```

```swift
.target(name: "MyApp", dependencies: [
    .product(name: "TimeLabels", package: "TimeLabels")
])
```

### Removing the Package

Remove the `.package(...)` entry and the product dependency from your
`Package.swift` (or remove the package under your project's **Package
Dependencies** tab in Xcode), then run `swift package resolve`.

## Usage

Import the module and call the helpers. The date-based functions take an
optional `calendar:` parameter so you can control the *timezone*. The calendar
itself is always Gregorian (see **Behavior Notes**).

```swift
import Foundation
import TimeLabels

// "In 30mins" by default; `space: true` gives "In 30 mins"
let minutesFromNow = TimeLabel.timeRemaining(1_800) // 1800 seconds

// "5mins ago" / "3h ago"; a future date renders as a date ("Jun 20, 2026")
let fiveMinAgo = TimeLabel.timeAgo(Date().addingTimeInterval(-300))

// Short clock time: "3:30 PM"
let clock = TimeLabel.time(Date())

// Contextual date label: "" (today) / "Tomorrow" / "Jun 20, 2026"
let label = TimeLabel.dateLabel(Date().addingTimeInterval(3 * 86_400))
```

### Passing an explicit calendar

```swift
import Foundation
import TimeLabels

var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(identifier: "UTC")!

let date = Date(timeIntervalSince1970: 1_609_515_000) // 2021-01-01 15:30 UTC

// Formats 15:30 UTC as "3:30 PM"
let clock = TimeLabel.time(date, calendar: calendar)

// Date labels honor the calendar for today/tomorrow detection
let label = TimeLabel.dateLabel(date, calendar: calendar)
```

### Testing your own code

The date-based helpers accept a `now:` parameter so you can pin the clock:

```swift
let now = Date(timeIntervalSince1970: 1_609_515_000)
TimeLabel.timeAgo(now.addingTimeInterval(-300), now: now) // "5mins ago"
```

## API Reference

| Function | Signature | Returns |
| --- | --- | --- |
| `timeRemaining` | `static func timeRemaining(_ seconds: TimeInterval, expand: Bool = false, space: Bool = false, spellNumber: Bool = false, smallestUnit: Unit = .minute, largestUnit: Unit = .hour, rounding: Rounding = .down) -> String` | `"In 30mins"` / `"In 2h"` (or `"In 30minutes"` / `"In 2hours"` with `expand: true`; or `"In 30 mins"` / `"In 2 h"` with `space: true`; or `"In 30 minutes"` / `"In 2 hours"` with `expand: true, space: true`) |
| `timeRemaining(until:)` | `static func timeRemaining(until date: Date, now: Date = Date(), expand: Bool = false, space: Bool = false, spellNumber: Bool = false, smallestUnit: Unit = .minute, largestUnit: Unit = .hour, rounding: Rounding = .down) -> String` | The same as `timeRemaining`, measured from `now` to `date`; `"In 0mins"` once `date` has passed |
| `timeAgo` | `static func timeAgo(_ date: Date, now: Date = Date(), calendar: Calendar = .current, expand: Bool = false, space: Bool = false, spellNumber: Bool = false, smallestUnit: Unit = .minute, largestUnit: Unit = .hour, rounding: Rounding = .down) -> String` | `"Just now"` / `"5mins ago"` / `"3h ago"` / a medium-style date for future dates (or `"5minutes ago"` / `"3hours ago"` with `expand: true`; or `"5 mins ago"` / `"3 h ago"` with `space: true`; or `"5 minutes ago"` / `"3 hours ago"` with `expand: true, space: true`) |
| `relative` | `static func relative(_ date: Date, now: Date = Date(), expand: Bool = false, space: Bool = false, spellNumber: Bool = false, smallestUnit: Unit = .minute, largestUnit: Unit = .hour, rounding: Rounding = .down) -> String` | `"In 5mins"` (future) / `"5mins ago"` (past) / `"Now"` / `"Just now"` |
| `duration` | `static func duration(_ seconds: TimeInterval, style: DurationStyle = .compact, expand: Bool = false, space: Bool = false, spellNumber: Bool = false, largestUnit: Unit = .hour, maxParts: Int? = nil) -> String` | `"1h 30m"` (`.compact`) / `"1:30:00"` (`.countdown`) |
| `duration` (Swift `Duration`) | `static func duration(_ duration: Duration, style: DurationStyle = .compact, expand: Bool = false, space: Bool = false, spellNumber: Bool = false, largestUnit: Unit = .hour, maxParts: Int? = nil) -> String` | The same as above, e.g. `.seconds(5400)` gives `"1h 30m"` |
| `time` | `static func time(_ date: Date, calendar: Calendar = .current, use24Hour: Bool = false) -> String` | Short clock time, e.g. `"3:30 PM"` (or `"15:30"` with `use24Hour: true`) |
| `timeRange` | `static func timeRange(_ start: Date, _ end: Date, calendar: Calendar = .current, use24Hour: Bool = false) -> String` | `"3:30 – 4:15 PM"` (same day and AM/PM) / `"11:00 AM – 1:30 PM"` / `"15:30 – 16:15"` |
| `dateLabel` | `static func dateLabel(_ date: Date, now: Date = Date(), calendar: Calendar = .current, relativeDays: Bool = false, omitCurrentYear: Bool = false, namesToday: Bool = false, includesWeekday: Bool = false, abbreviatedWeekday: Bool = false) -> String` | `""` (today) / `"Tomorrow"` / `"Jun 20, 2026"` (with `relativeDays: true`, also `"Yesterday"` and weekday names like `"Monday"` within 6 days; with `omitCurrentYear: true`, `"Jun 20"` for dates in the current year; with `namesToday: true`, `"Today"`; with `includesWeekday: true`, `"Saturday, Jun 20"`; with `abbreviatedWeekday: true`, `"Sat"` / `"Sat, Jun 20"`) |
| `dateTime` | `static func dateTime(_ date: Date, now: Date = Date(), calendar: Calendar = .current, use24Hour: Bool = false, relativeDays: Bool = false, omitCurrentYear: Bool = false, namesToday: Bool = false, includesWeekday: Bool = false, abbreviatedWeekday: Bool = false, separator: String = " at ") -> String` | `"3:30 PM"` (today) / `"Tomorrow at 3:30 PM"` / `"Jun 20, 2026 at 3:30 PM"` (with `separator: " · "`, `"Tomorrow · 3:30 PM"`) |

The relative helpers take `smallestUnit:` and `largestUnit:` (see **Units**)
and `rounding:` (see **Rounding**).

## Short, spaced, or expanded words

Both `timeRemaining` and `timeAgo` accept two optional flags. They are
independent — `expand` chooses the **word**, `space` chooses the **gap** — so
you can mix them:

- **`expand: true`** spells the unit out as a full word but adds **no** space:
  `"In 2hours"`, `"5minutes ago"`.
- **`space: true`** keeps the compact unit but adds a space before it:
  `"In 2 h"`, `"5 mins ago"`. The default baseline is no space (`"In 2h"`,
  `"5mins ago"`) so labels stay tight.
- Pass **both** for the full, natural phrase: `"In 2 hours"`,
  `"5 minutes ago"`.

```swift
TimeLabel.timeRemaining(2 * 3600)               // "In 2h"
TimeLabel.timeRemaining(2 * 3600, space: true)  // "In 2 h"
TimeLabel.timeRemaining(2 * 3600, expand: true) // "In 2hours"
TimeLabel.timeRemaining(2 * 3600, expand: true, space: true) // "In 2 hours"

TimeLabel.timeAgo(someDate)                     // "5mins ago"
TimeLabel.timeAgo(someDate, space: true)        // "5 mins ago"
TimeLabel.timeAgo(someDate, expand: true)       // "5minutes ago"
TimeLabel.timeAgo(someDate, expand: true, space: true) // "5 minutes ago"
```

`spellNumber: true` spells the count while keeping the unit compact
(`"In twenty-fivemins"`); like `expand`, it never adds a space, so combine it
with `space: true` for `"In twenty-five mins"`.

## Units: seconds, days and weeks

`timeRemaining`, `timeAgo` and `relative` accept `smallestUnit:` and
`largestUnit:` (`TimeLabel.Unit`: `.second`, `.minute`, `.hour`, `.day`,
`.week`). The label uses the largest unit in that range that fits at least
once. The defaults (`.minute` ... `.hour`) match the original output, so
existing code is unaffected.

```swift
TimeLabel.timeAgo(threeDaysAgo)                       // "72h ago" (default)
TimeLabel.timeAgo(threeDaysAgo, largestUnit: .day)    // "3d ago"
TimeLabel.timeAgo(threeDaysAgo, expand: true, space: true, largestUnit: .day) // "3 days ago"
TimeLabel.timeAgo(thirtySecondsAgo, smallestUnit: .second) // "30s ago"
TimeLabel.timeRemaining(45, smallestUnit: .second)    // "In 45s"
```

## Rounding

By default a partial unit is dropped, so 89 *and* 90 minutes both read "1h".
Pass `rounding: .nearest` to round instead (halves round up). A result that
reaches the next unit moves up to it, so 59.5 minutes reads "1h", not
"60mins". "Just now" and "Now" still cover anything under one `smallestUnit`.

```swift
TimeLabel.timeAgo(ninetyMinutesAgo)                       // "1h ago"
TimeLabel.timeAgo(ninetyMinutesAgo, rounding: .nearest)   // "2h ago"
TimeLabel.timeRemaining(3570, rounding: .nearest)         // "In 1h"
```

## Relative labels

`relative` chooses the direction for you, so a countdown that passes zero
doesn't get stuck on "In 0mins":

```swift
TimeLabel.relative(eventDate)  // "In 5mins" before the event, "5mins ago" after
TimeLabel.relative(eventDate, smallestUnit: .second) // "In 30s" / "Now" / "Just now"
```

If you only ever want the countdown, `timeRemaining(until:)` takes the date
directly:

```swift
TimeLabel.timeRemaining(until: eventDate)  // "In 30mins"; "In 0mins" once it passes
```

## Durations

`duration` formats a plain length of time with no "In" or "ago":

```swift
TimeLabel.duration(5400)                                  // "1h 30m"
TimeLabel.duration(5400, expand: true, space: true)       // "1 hour 30 minutes"
TimeLabel.duration(5400, style: .countdown)               // "1:30:00"
TimeLabel.duration(245, style: .countdown)                // "4:05"
```

Long durations stay in hours by default. Raise `largestUnit` (up to `.week`) to
roll them up, and use `spellNumber` to spell the counts:

```swift
TimeLabel.duration(100_000)                               // "27h 46m 40s"
TimeLabel.duration(100_000, largestUnit: .day)            // "1d 3h 46m 40s"
TimeLabel.duration(100_000, expand: true, space: true, largestUnit: .day)
                                                          // "1 day 3 hours 46 minutes 40 seconds"
TimeLabel.duration(5400, space: true, spellNumber: true)  // "one h thirty m"
```

`maxParts` keeps only the biggest units, counted down from the first non-zero
one (smaller units are dropped, not rounded). A Swift `Duration` works too:

```swift
TimeLabel.duration(100_000, maxParts: 2)                  // "27h 46m"
TimeLabel.duration(3601, maxParts: 2)                     // "1h" (the 0 minutes use up a part)
TimeLabel.duration(.seconds(5400))                        // "1h 30m"
TimeLabel.duration(clock.now - start, style: .countdown)  // "4:05"
```

`.countdown` ignores `expand`, `space`, `spellNumber`, `largestUnit` and
`maxParts`.

## Yesterday and weekdays

```swift
TimeLabel.dateLabel(yesterday, relativeDays: true)        // "Yesterday"
TimeLabel.dateLabel(threeDaysAgo, relativeDays: true)     // "Wednesday"
TimeLabel.dateLabel(twoWeeksAgo, relativeDays: true)      // "Jun 6, 2026"
TimeLabel.time(Date(), use24Hour: true)                   // "15:30"
TimeLabel.dateLabel(juneTwentieth, omitCurrentYear: true) // "Jun 20" this year, "Jun 20, 2025" otherwise
```

## Today, short weekdays, and weekday with date

```swift
TimeLabel.dateLabel(Date(), namesToday: true)                                // "Today" instead of ""
TimeLabel.dateLabel(threeDaysAgo, relativeDays: true, abbreviatedWeekday: true) // "Wed"
TimeLabel.dateLabel(juneTwentieth, omitCurrentYear: true, includesWeekday: true) // "Saturday, Jun 20"
TimeLabel.dateLabel(juneTwentieth, omitCurrentYear: true, includesWeekday: true,
                    abbreviatedWeekday: true)                                // "Sat, Jun 20"
```

`includesWeekday` only adds the weekday to dated labels; "Today",
"Tomorrow", "Yesterday" and the `relativeDays` weekday names stay as they are.

## Dates with times, and time ranges

```swift
TimeLabel.dateTime(laterToday)                            // "3:30 PM"
TimeLabel.dateTime(tomorrowAfternoon)                     // "Tomorrow at 3:30 PM"
TimeLabel.dateTime(lastWednesday, relativeDays: true)     // "Wednesday at 3:30 PM"
TimeLabel.dateTime(someDate, omitCurrentYear: true)       // "Jun 20 at 3:30 PM"

// Your own separator, for tight or dotted lines:
TimeLabel.dateTime(tomorrowAfternoon, separator: " · ")   // "Tomorrow · 3:30 PM"
TimeLabel.dateTime(laterToday, namesToday: true, separator: " ")  // "Today 3:30 PM"
TimeLabel.dateTime(nextSaturday, relativeDays: true, abbreviatedWeekday: true,
                   separator: " ")                        // "Sat 3:30 PM"
TimeLabel.dateTime(juneTwentieth, omitCurrentYear: true, includesWeekday: true,
                   abbreviatedWeekday: true, separator: " · ") // "Sat, Jun 20 · 3:30 PM"

TimeLabel.timeRange(start, end)                           // "3:30 – 4:15 PM"
TimeLabel.timeRange(morning, afternoon)                   // "11:00 AM – 1:30 PM"
TimeLabel.timeRange(start, end, use24Hour: true)          // "15:30 – 16:15"
```

`timeRange` drops the first AM/PM only when both times are on the same day
and share it. The separator is an en dash (`–`) with a space on each side.

## Date extensions

Every function has a `Date` shortcut that forwards to `TimeLabel`:

```swift
post.date.timeAgo()                // TimeLabel.timeAgo(post.date)
event.date.relative()              // TimeLabel.relative(event.date)
event.date.timeRemaining()         // TimeLabel.timeRemaining(until: event.date)
event.date.timeLabel()             // TimeLabel.time(event.date)
event.start.timeRangeLabel(to: event.end) // TimeLabel.timeRange(event.start, event.end)
event.date.dateLabel()             // TimeLabel.dateLabel(event.date)
event.date.dateTimeLabel()         // TimeLabel.dateTime(event.date)
```

## SwiftUI: self-updating labels

`TimeLabelText` (available wherever SwiftUI is) re-renders on its own, so
"Just now" becomes "1min ago" without any timer code:

```swift
TimeLabelText(relativeTo: event.date)                       // refreshes every minute
TimeLabelText(relativeTo: event.date, smallestUnit: .second) // refreshes every second
TimeLabelText(refresh: 30) { now in                         // any label you like
    TimeLabel.timeAgo(post.date, now: now, largestUnit: .day)
}
```

## Behavior Notes

- **Invalid durations.** `timeRemaining` and `duration` treat negative and NaN
  input as 0 and clamp very large or infinite input rather than crashing.
- **Locale.** Formatting uses a fixed `en_US_POSIX` locale and explicit
  patterns, so output is identical across devices, languages and OS versions
  (e.g. always `"3:30 PM"` with a plain space, never `"3:30 p.m."`).
- **Timezone.** Pass a `calendar:` with the timezone you want. When omitted,
  the current timezone is used.
- **Thread safety.** Each call builds its own formatter and there is no shared
  mutable state, so concurrent use is safe.
- **Calendar.** All output uses the **Gregorian calendar**. Pass a `calendar:`
  only to set the *timezone* — the calendar identifier is always Gregorian and
  can't be changed. If you need Hijri, Hebrew, Persian, or other calendars, use
  a different library or convert the `Date` yourself before calling these helpers.

## Testing

Unit tests cover every function, using fixed dates and calendars. Run them with:

```sh
swift test
```

> Tests use the `swift-testing` framework. If a command-line-only toolchain
> reports `plugin for module TestingMacros not found`, run the tests from
> Xcode (or a full Xcode toolchain) instead.

## License

Released under the MIT License.
