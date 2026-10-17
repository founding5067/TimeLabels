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
#endif
