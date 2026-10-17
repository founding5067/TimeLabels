//
//  TimeLabelText.swift
//

#if canImport(SwiftUI)
import SwiftUI

/// A `Text` that keeps itself up to date, so "Just now" becomes "1min ago"
/// without any timer code in your app.
///
/// ```swift
/// // Relative label that flips between "In 5mins" and "5mins ago":
/// TimeLabelText(relativeTo: event.date)
///
/// // Any label you like, re-evaluated on every refresh:
/// TimeLabelText { now in TimeLabel.timeAgo(post.date, now: now) }
/// ```
public struct TimeLabelText: View {
    private let refresh: TimeInterval
    private let text: @Sendable (Date) -> String

    // MARK: - Initializers

    /// - Parameters:
    ///   - refresh: Seconds between updates (minimum 1).
    ///   - text: Builds the label for the current date.
    public init(refresh: TimeInterval = 60, _ text: @escaping @Sendable (Date) -> String) {
        self.refresh = max(refresh, 1)
        self.text = text
    }

    /// A live `TimeLabel.relative` label. It refreshes every second when
    /// `smallestUnit` is `.second` and every minute otherwise.
    public init(relativeTo date: Date, expand: Bool = false, space: Bool = false, spellNumber: Bool = false, smallestUnit: TimeLabel.Unit = .minute, largestUnit: TimeLabel.Unit = .hour) {
        self.init(refresh: smallestUnit == .second ? 1 : 60) { now in
            TimeLabel.relative(date, now: now, expand: expand, space: space, spellNumber: spellNumber, smallestUnit: smallestUnit, largestUnit: largestUnit)
        }
    }

    // MARK: - Body

    public var body: some View {
        TimelineView(.periodic(from: .now, by: refresh)) { context in
            Text(text(context.date))
        }
    }
}

#if DEBUG
// MARK: - Previews
// Three tabs, each covering one dimension of the output exhaustively:
//   "Flags"         every expand / space / spellNumber combination x every unit
//   "Unit ranges"   every smallestUnit...largestUnit pair for one fixed gap
//   "Live"          labels that actually tick (the real TimeLabelText behavior)
// "Flags" and "Unit ranges" pin the clock so every string, including "Now" and
// "Just now", stays on screen instead of changing on the next refresh.

// MARK: - Preview data

private let previewNow = Date(timeIntervalSince1970: 1_609_515_000)

private struct PreviewOffset: Identifiable {
    let title: String
    let seconds: TimeInterval
    var id: String { title }
}

// One offset per output shape: every unit in both directions, plus the
// near-zero cases that read "Just now" (past) and "Now" (future).
private let previewOffsets: [PreviewOffset] = [
    PreviewOffset(title: "-2 weeks", seconds: -2 * 604_800),
    PreviewOffset(title: "-3 days", seconds: -3 * 86_400),
    PreviewOffset(title: "-2 hours", seconds: -2 * 3600),
    PreviewOffset(title: "-5 minutes", seconds: -5 * 60),
    PreviewOffset(title: "-30 seconds", seconds: -30),
    PreviewOffset(title: "-0.5 seconds", seconds: -0.5),
    PreviewOffset(title: "+0.5 seconds", seconds: 0.5),
    PreviewOffset(title: "+30 seconds", seconds: 30),
    PreviewOffset(title: "+5 minutes", seconds: 5 * 60),
    PreviewOffset(title: "+2 hours", seconds: 2 * 3600),
    PreviewOffset(title: "+3 days", seconds: 3 * 86_400),
    PreviewOffset(title: "+2 weeks", seconds: 2 * 604_800),
]

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
private let previewGap: TimeInterval = 9 * 86_400 + 3 * 3600 + 5 * 60 + 20

// A label for `previewNow + offset`, read at the pinned `previewNow`.
@MainActor
private func pinnedLabel(offset: TimeInterval, expand: Bool = false, space: Bool = false, spellNumber: Bool = false, smallest: TimeLabel.Unit = .minute, largest: TimeLabel.Unit = .hour) -> some View {
    TimeLabelText { _ in
        TimeLabel.relative(previewNow.addingTimeInterval(offset), now: previewNow, expand: expand, space: space, spellNumber: spellNumber, smallestUnit: smallest, largestUnit: largest)
    }
}

// MARK: - Flags preview

#Preview("Flags") {
    List {
        ForEach(previewFlags) { flags in
            Section(flags.title) {
                ForEach(previewOffsets) { offset in
                    LabeledContent(offset.title) {
                        pinnedLabel(offset: offset.seconds, expand: flags.expand, space: flags.space, spellNumber: flags.spellNumber, smallest: .second, largest: .week)
                    }
                }
            }
        }
    }
}

// MARK: - Unit ranges preview

#Preview("Unit ranges") {
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

// MARK: - Live preview

#Preview("Live") {
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
#endif
#endif
