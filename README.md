# TimeLabels

Reusable date/time **formatting** helpers for Swift. Turns raw `Date`s and
time intervals into the short, human-readable strings you want to show in a
UI — "In 2h", "5mins ago", "3:30 PM", "Tomorrow" — without duplicating
`DateFormatter` setup across your screens.

## Features

- `timeRemaining(_:)` — time **until** an event ("In 30mins" / "In 2h")
- `timeAgo(_:)` — time **since** an event ("Just now" / "5mins ago" / a date)
- `time(_:)` — short clock time ("3:30 PM")
- `dateLabel(_:)` — contextual date label ("" for today, "Tomorrow", else "Jun 20, 2026")
- Thread-safe: no shared mutable state (each call builds its own formatter)
- Deterministic output: a fixed `en_US_POSIX` locale and pattern so results don't drift with the device locale or OS version
- Testable: `timeAgo` and `dateLabel` take a `now:` parameter

## Requirements

- Swift 6.0+
- iOS 16+, macOS 13+, watchOS 9+, tvOS 16+, visionOS 1+ (CI also builds on Linux)

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
| `time` | `static func time(_ date: Date, calendar: Calendar = .current) -> String` | Short clock time, e.g. `"3:30 PM"` |
| `dateLabel` | `static func dateLabel(_ date: Date, now: Date = Date(), calendar: Calendar = .current) -> String` | `""` (today) / `"Tomorrow"` / `"Jun 20, 2026"` |

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

Unit tests cover all four functions, using fixed dates and calendars. Run them with:

```sh
swift test
```

> Tests use the `swift-testing` framework. With a command-line-only toolchain
> you may see `plugin for module TestingMacros not found`; run the tests from
> Xcode (or a full Xcode toolchain) instead.

## License

Released under the MIT License.
