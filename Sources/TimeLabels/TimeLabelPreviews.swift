//
//  TimeLabelPreviews.swift
//

#if canImport(SwiftUI) && DEBUG
import SwiftUI

// Every SwiftUI preview in one self-contained file (Xcode's canvas doesn't
// reliably see symbols from other files). Eight tabs:
//   "Relative: flags"        every expand / space / spellNumber combination x every unit
//   "Relative: unit ranges"  every smallestUnit...largestUnit pair for one fixed gap
//   "Relative: rounding"     `.down` next to `.nearest` around each rounding edge
//   "Calendar"               dateLabel, dateTime (incl. compact and dotted styles) and timeRange around a pinned day
//   "TimeLabelText: live"    labels that actually tick (the real TimeLabelText behavior)
//   "Duration: flags"        the same flag combinations, for `duration`
//   "Duration: largestUnit"  the caps on the biggest unit and on the number of parts
//   "Duration: countdown"    the timer style, which ignores every other option
// The relative and calendar tabs pin the clock so every string, including
// "Now" and "Just now", stays on screen instead of changing on the next
// refresh. The duration tabs are static because `duration` doesn't depend
// on the current time.

// MARK: - Shared preview data

// A titled number of seconds: a relative offset, or a duration to format.
private struct PreviewSample: Identifiable {
    let title: String
    let seconds: TimeInterval
    var id: String { title }
}

// All 2^3 combinations of the three word/spacing flags.
private struct PreviewFlags: Identifiable {
    let expand: Bool
    let space: Bool
    let spellNumber: Bool

    var title: String {
        let names = [expand ? "expand" : nil, space ? "space" : nil, spellNumber ? "spellNumber" : nil]
        let on = names.compactMap { $0 }
        return on.isEmpty ? "defaults" : on.joined(separator: " + ")
    }
    var id: String { title }
}

private let previewFlags: [PreviewFlags] = (0..<8).map { bits in
    PreviewFlags(expand: bits & 1 != 0, space: bits & 2 != 0, spellNumber: bits & 4 != 0)
}

// One Section per flag combination, one row per sample. Both "flags" previews
// use this, so the loop is written once.
@MainActor
private func flagSections<Row: View>(_ samples: [PreviewSample], @ViewBuilder row: @escaping (PreviewFlags, PreviewSample) -> Row) -> some View {
    ForEach(previewFlags) { flags in
        Section(flags.title) {
            ForEach(samples) { sample in
                LabeledContent(sample.title) {
                    row(flags, sample)
                }
            }
        }
    }
}

// MARK: - Relative preview data

private let previewNow = Date(timeIntervalSince1970: 1_609_515_000)

// One offset per output shape: every unit in both directions, plus the
// near-zero cases that read "Just now" (past) and "Now" (future).
private let relativeSamples: [PreviewSample] = [
    PreviewSample(title: "-2 weeks", seconds: -2 * 604_800),
    PreviewSample(title: "-3 days", seconds: -3 * 86_400),
    PreviewSample(title: "-2 hours", seconds: -2 * 3600),
    PreviewSample(title: "-5 minutes", seconds: -5 * 60),
    PreviewSample(title: "-30 seconds", seconds: -30),
    PreviewSample(title: "-0.5 seconds", seconds: -0.5),
    PreviewSample(title: "+0.5 seconds", seconds: 0.5),
    PreviewSample(title: "+30 seconds", seconds: 30),
    PreviewSample(title: "+5 minutes", seconds: 5 * 60),
    PreviewSample(title: "+2 hours", seconds: 2 * 3600),
    PreviewSample(title: "+3 days", seconds: 3 * 86_400),
    PreviewSample(title: "+2 weeks", seconds: 2 * 604_800),
]

// Every valid smallestUnit...largestUnit pair (15 of them).
private struct PreviewRange: Identifiable {
    let smallest: TimeLabel.Unit
    let largest: TimeLabel.Unit
    var title: String { "\(smallest) ... \(largest)" }
    var id: String { title }
}

private let previewRanges: [PreviewRange] = TimeLabel.Unit.allCases.flatMap { smallest in
    TimeLabel.Unit.allCases.filter { $0 >= smallest }.map { PreviewRange(smallest: smallest, largest: $0) }
}

// 9 days, 3 hours, 5 minutes, 20 seconds: a gap that reads differently under
// every unit range.
private let previewGap: TimeInterval = 788_720 // 9*86_400 + 3*3600 + 5*60 + 20

// A label for `previewNow + offset`, read at the pinned `previewNow`.
@MainActor
private func pinnedLabel(offset: TimeInterval, expand: Bool = false, space: Bool = false, spellNumber: Bool = false, smallest: TimeLabel.Unit = .minute, largest: TimeLabel.Unit = .hour) -> some View {
    TimeLabelText { _ in
        TimeLabel.relative(previewNow.addingTimeInterval(offset), now: previewNow, expand: expand, space: space, spellNumber: spellNumber, smallestUnit: smallest, largestUnit: largest)
    }
}

// Gaps on either side of a rounding edge, read with both rounding modes.
private let roundingSamples: [PreviewSample] = [
    PreviewSample(title: "+2m 29s", seconds: 149),
    PreviewSample(title: "+2m 30s", seconds: 150),
    PreviewSample(title: "+59m 30s", seconds: 3570),
    PreviewSample(title: "+1h 29m", seconds: 89 * 60),
    PreviewSample(title: "+1h 30m", seconds: 90 * 60),
    PreviewSample(title: "-1h 30m", seconds: -90 * 60),
]

// MARK: - Calendar preview data

// The calendar tab reads everything in UTC so the pinned day is the same
// everywhere: `previewNow` is Friday, Jan 1 2021, 3:30 PM UTC.
private let previewCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

private let calendarSamples: [PreviewSample] = [
    PreviewSample(title: "-7 days", seconds: -7 * 86_400),
    PreviewSample(title: "-2 days", seconds: -2 * 86_400),
    PreviewSample(title: "-1 day", seconds: -86_400),
    PreviewSample(title: "Now", seconds: 0),
    PreviewSample(title: "+1 day", seconds: 86_400),
    PreviewSample(title: "+2 days", seconds: 2 * 86_400),
    PreviewSample(title: "+7 days", seconds: 7 * 86_400),
]

// Start and end offsets (from `previewNow`) for each shape of time range.
private let rangeSamples: [(title: String, start: TimeInterval, end: TimeInterval)] = [
    ("Same afternoon", 0, 45 * 60),
    ("Same morning", -6.5 * 3600, -5.5 * 3600),
    ("Across noon", -4 * 3600, -3.25 * 3600),
    ("Across midnight", 8 * 3600, 9 * 3600),
    ("Next day, same PM", 0, 86_400 + 3600),
]

// MARK: - Duration preview data

// One sample per output shape: zero, each unit on its own, and mixed lengths.
private let durationSamples: [PreviewSample] = [
    PreviewSample(title: "0 seconds", seconds: 0),
    PreviewSample(title: "1 second", seconds: 1),
    PreviewSample(title: "45 seconds", seconds: 45),
    PreviewSample(title: "1 minute", seconds: 60),
    PreviewSample(title: "1h 30m", seconds: 5400),
    PreviewSample(title: "2 hours", seconds: 7200),
    PreviewSample(title: "27h 46m 40s", seconds: 100_000),
    PreviewSample(title: "1w 2d 3h 4m 5s", seconds: 788_645),
]

// The longer samples used to show the effect of `largestUnit`.
private let capSamples: [PreviewSample] = [
    PreviewSample(title: "788,645 s (1w 2d 3h 4m 5s)", seconds: 788_645),
    PreviewSample(title: "100,000 s (27h 46m 40s)", seconds: 100_000),
    PreviewSample(title: "5,400 s (1h 30m)", seconds: 5400),
]

private let countdownSeconds: [TimeInterval] = [0, 5, 245, 5400, 36_061]

// MARK: - Relative: flags preview

#Preview("Relative: flags") {
    List {
        flagSections(relativeSamples) { flags, offset in
            pinnedLabel(offset: offset.seconds, expand: flags.expand, space: flags.space, spellNumber: flags.spellNumber, smallest: .second, largest: .week)
        }
    }
}

// MARK: - Relative: unit ranges preview

#Preview("Relative: unit ranges") {
    List {
        Section("Past: 9d 3h 5m 20s ago") {
            ForEach(previewRanges) { range in
                LabeledContent(range.title) {
                    pinnedLabel(offset: -previewGap, smallest: range.smallest, largest: range.largest)
                }
            }
        }
        Section("Future: in 9d 3h 5m 20s") {
            ForEach(previewRanges) { range in
                LabeledContent(range.title) {
                    pinnedLabel(offset: previewGap, smallest: range.smallest, largest: range.largest)
                }
            }
        }
    }
}

// MARK: - TimeLabelText: live preview

#Preview("TimeLabelText: live") {
    let now = Date()
    return List {
        Section("relativeTo (refreshes every minute)") {
            TimeLabelText(relativeTo: now.addingTimeInterval(-300))
            TimeLabelText(relativeTo: now.addingTimeInterval(2 * 3600))
            TimeLabelText(relativeTo: now.addingTimeInterval(-3 * 86_400), expand: true, space: true, largestUnit: .day)
        }
        Section("relativeTo, seconds (refreshes every second)") {
            TimeLabelText(relativeTo: now.addingTimeInterval(-5), smallestUnit: .second)
            TimeLabelText(relativeTo: now.addingTimeInterval(90), expand: true, space: true, smallestUnit: .second)
        }
        Section("Custom closure") {
            TimeLabelText(refresh: 30) { current in
                TimeLabel.timeAgo(now.addingTimeInterval(-4 * 3600), now: current, expand: true, space: true)
            }
            TimeLabelText { current in
                TimeLabel.time(current)
            }
            // Counts down from one hour, ticking every second.
            TimeLabelText(refresh: 1) { current in
                TimeLabel.duration(max(0, now.addingTimeInterval(3600).timeIntervalSince(current)), style: .countdown)
            }
        }
    }
}

// MARK: - Relative: rounding preview

#Preview("Relative: rounding") {
    List {
        ForEach([TimeLabel.Rounding.down, .nearest], id: \.self) { rounding in
            Section(rounding == .down ? "rounding: .down" : "rounding: .nearest") {
                ForEach(roundingSamples) { sample in
                    LabeledContent(sample.title) {
                        TimeLabelText { _ in
                            TimeLabel.relative(previewNow.addingTimeInterval(sample.seconds), now: previewNow, rounding: rounding)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Calendar preview

#Preview("Calendar") {
    List {
        ForEach([false, true], id: \.self) { relativeDays in
            Section(relativeDays ? "dateTime, relativeDays + omitCurrentYear" : "dateTime, defaults") {
                ForEach(calendarSamples) { sample in
                    LabeledContent(sample.title) {
                        Text(TimeLabel.dateTime(previewNow.addingTimeInterval(sample.seconds), now: previewNow, calendar: previewCalendar, relativeDays: relativeDays, omitCurrentYear: relativeDays))
                    }
                }
            }
        }
        Section("dateTime, compact (namesToday + abbreviatedWeekday, \" \")") {
            ForEach(calendarSamples) { sample in
                LabeledContent(sample.title) {
                    Text(TimeLabel.dateTime(previewNow.addingTimeInterval(sample.seconds), now: previewNow, calendar: previewCalendar, relativeDays: true, omitCurrentYear: true, namesToday: true, abbreviatedWeekday: true, separator: " "))
                }
            }
        }
        Section("dateTime, dotted (includesWeekday + abbreviatedWeekday, \" · \")") {
            ForEach(calendarSamples) { sample in
                LabeledContent(sample.title) {
                    Text(TimeLabel.dateTime(previewNow.addingTimeInterval(sample.seconds), now: previewNow, calendar: previewCalendar, omitCurrentYear: true, includesWeekday: true, abbreviatedWeekday: true, separator: " · "))
                }
            }
        }
        ForEach([false, true], id: \.self) { use24Hour in
            Section(use24Hour ? "timeRange, use24Hour" : "timeRange") {
                ForEach(rangeSamples, id: \.title) { sample in
                    LabeledContent(sample.title) {
                        Text(TimeLabel.timeRange(previewNow.addingTimeInterval(sample.start), previewNow.addingTimeInterval(sample.end), calendar: previewCalendar, use24Hour: use24Hour))
                    }
                }
            }
        }
    }
}

// MARK: - Duration: flags preview

#Preview("Duration: flags") {
    List {
        flagSections(durationSamples) { flags, sample in
            Text(TimeLabel.duration(sample.seconds, expand: flags.expand, space: flags.space, spellNumber: flags.spellNumber, largestUnit: .week))
        }
    }
}

// MARK: - Duration: largestUnit preview

#Preview("Duration: largestUnit") {
    List {
        ForEach(capSamples) { sample in
            Section(sample.title) {
                ForEach(TimeLabel.Unit.allCases, id: \.self) { unit in
                    LabeledContent("largestUnit: .\(String(describing: unit))") {
                        Text(TimeLabel.duration(sample.seconds, largestUnit: unit))
                    }
                }
            }
        }
        Section("788,645 s, largestUnit: .week, by maxParts") {
            ForEach(1...5, id: \.self) { parts in
                LabeledContent("maxParts: \(parts)") {
                    Text(TimeLabel.duration(788_645, largestUnit: .week, maxParts: parts))
                }
            }
        }
        Section("788,645 s with expand + space") {
            ForEach(TimeLabel.Unit.allCases, id: \.self) { unit in
                LabeledContent("largestUnit: .\(String(describing: unit))") {
                    Text(TimeLabel.duration(788_645, expand: true, space: true, largestUnit: unit))
                }
            }
        }
    }
}

// MARK: - Duration: countdown preview

#Preview("Duration: countdown") {
    List {
        Section("style: .countdown") {
            ForEach(countdownSeconds, id: \.self) { seconds in
                LabeledContent("\(Int(seconds)) s") {
                    Text(TimeLabel.duration(seconds, style: .countdown))
                }
            }
        }
        Section("Ignores expand, space, spellNumber, largestUnit and maxParts") {
            LabeledContent("5,400 s, every option on") {
                Text(TimeLabel.duration(5400, style: .countdown, expand: true, space: true, spellNumber: true, largestUnit: .week, maxParts: 1))
            }
            LabeledContent("5,400 s, defaults") {
                Text(TimeLabel.duration(5400, style: .countdown))
            }
        }
    }
}
#endif
