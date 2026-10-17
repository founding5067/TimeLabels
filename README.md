# TimeLabels

Reusable date/time **formatting** helpers for Swift. Turns raw `Date`s and
time intervals into the short, human-readable strings you want to show in a
UI — "In 2h", "5mins ago", "3:30 PM", "Tomorrow" — without duplicating
`DateFormatter` setup across your screens.

## Features

- `timeRemaining(_:)` — time **until** an event ("In 30mins" / "In 2h")
- `timeAgo(_:)` — time **since** an event ("Just now" / "5mins ago" / a date)
- `relative(_:)` — picks "In 5mins" or "5mins ago" automatically
- `duration(_:)` — a plain length of time ("1h 30m", or timer-style "1:30:00")
- `time(_:)` — short clock time ("3:30 PM", or "15:30" with `use24Hour: true`)
- `dateLabel(_:)` — contextual date label ("" for today, "Tomorrow", else "Jun 20, 2026"; with `relativeDays: true` also "Yesterday" and weekday names)
- Seconds, days and weeks via `smallestUnit:` / `largestUnit:` ("30s ago", "3d ago", "2w ago")
- `Date` extensions (`date.timeAgo()`, `date.relative()`, ...) and a self-updating SwiftUI `TimeLabelText`
- Thread-safe: no shared mutable state (each call builds its own formatter)
- Deterministic output: a fixed `en_US_POSIX` locale and pattern so results don't drift with the device locale or OS version
- Testable: `timeAgo` and `dateLabel` take a `now:` parameter

## Requirements

- Swift 6.0+
- iOS 16+, macOS 13+, watchOS 9+, tvOS 16+, visionOS 1+ (CI builds every Apple platform and tests on macOS and Linux)

## Installation

Add the package as a dependency in your `Package.swift`, then resolve it.

### Swift Package Manager (Xcode)

1. **File > Add Package Dependencies...**
2. Enter the repository URL: `https://github.com/founding5067/TimeLabels`
3. Choose **Dependency Rule: Up to Next Major Version** starting at `1.0.0`

### Swift Package Manager (command line)

Add the package to the `dependencies` array in your `Package.swift`, and the
product to your target's dependencies:

```swift
.package(url: "https://github.com/founding5067/TimeLabels", from: "1.0.0")
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

`timeAgo` and `dateLabel` accept a `now:` parameter so you can pin the clock:

```swift
let now = Date(timeIntervalSince1970: 1_609_515_000)
TimeLabel.timeAgo(now.addingTimeInterval(-300), now: now) // "5mins ago"
```

## API Reference

| Function | Signature | Returns |
| --- | --- | --- |
| `timeRemaining` | `static func timeRemaining(_ seconds: TimeInterval, expand: Bool = false, space: Bool = false, spellNumber: Bool = false) -> String` | `"In 30mins"` / `"In 2h"` (or `"In 30minutes"` / `"In 2hours"` with `expand: true`; or `"In 30 mins"` / `"In 2 h"` with `space: true`; or `"In 30 minutes"` / `"In 2 hours"` with `expand: true, space: true`) |
| `timeAgo` | `static func timeAgo(_ date: Date, now: Date = Date(), calendar: Calendar = .current, expand: Bool = false, space: Bool = false, spellNumber: Bool = false) -> String` | `"Just now"` / `"5mins ago"` / `"3h ago"` / a medium-style date for future dates (or `"5minutes ago"` / `"3hours ago"` with `expand: true`; or `"5 mins ago"` / `"3 h ago"` with `space: true`; or `"5 minutes ago"` / `"3 hours ago"` with `expand: true, space: true`) |
| `relative` | `static func relative(_ date: Date, now: Date = Date(), expand: Bool = false, space: Bool = false, spellNumber: Bool = false, smallestUnit: Unit = .minute, largestUnit: Unit = .hour) -> String` | `"In 5mins"` (future) / `"5mins ago"` (past) / `"Now"` / `"Just now"` |
| `duration` | `static func duration(_ seconds: TimeInterval, style: DurationStyle = .compact, expand: Bool = false, space: Bool = false) -> String` | `"1h 30m"` (`.compact`) / `"1:30:00"` (`.countdown`) |
| `time` | `static func time(_ date: Date, calendar: Calendar = .current, use24Hour: Bool = false) -> String` | Short clock time, e.g. `"3:30 PM"` (or `"15:30"` with `use24Hour: true`) |
| `dateLabel` | `static func dateLabel(_ date: Date, now: Date = Date(), calendar: Calendar = .current, relativeDays: Bool = false) -> String` | `""` (today) / `"Tomorrow"` / `"Jun 20, 2026"` (with `relativeDays: true`, also `"Yesterday"` and weekday names like `"Monday"` within 6 days) |

`timeRemaining` and `timeAgo` also take `smallestUnit:` and `largestUnit:`
(see **Units**).

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

## Relative labels

`relative` chooses the direction for you, so a countdown that passes zero
doesn't get stuck on "In 0mins":

```swift
TimeLabel.relative(eventDate)  // "In 5mins" before the event, "5mins ago" after
TimeLabel.relative(eventDate, smallestUnit: .second) // "In 30s" / "Now" / "Just now"
```

## Durations

`duration` formats a plain length of time with no "In" or "ago":

```swift
TimeLabel.duration(5400)                                  // "1h 30m"
TimeLabel.duration(5400, expand: true, space: true)       // "1 hour 30 minutes"
TimeLabel.duration(5400, style: .countdown)               // "1:30:00"
TimeLabel.duration(245, style: .countdown)                // "4:05"
```

## Yesterday and weekdays

```swift
TimeLabel.dateLabel(yesterday, relativeDays: true)        // "Yesterday"
TimeLabel.dateLabel(threeDaysAgo, relativeDays: true)     // "Wednesday"
TimeLabel.dateLabel(twoWeeksAgo, relativeDays: true)      // "Jun 6, 2026"
TimeLabel.time(Date(), use24Hour: true)                   // "15:30"
```

## Date extensions

Every function has a `Date` shortcut that forwards to `TimeLabel`:

```swift
post.date.timeAgo()                // TimeLabel.timeAgo(post.date)
event.date.relative()              // TimeLabel.relative(event.date)
event.date.timeLabel()             // TimeLabel.time(event.date)
event.date.dateLabel()             // TimeLabel.dateLabel(event.date)
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

- **Invalid durations.** `timeRemaining` treats negative and NaN input as 0 and
  clamps very large or infinite input rather than crashing.
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
