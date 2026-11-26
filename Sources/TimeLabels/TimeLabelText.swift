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
///
/// // Your own label in the language set with `timeLabelLanguage(_:)`:
/// TimeLabelText { now, language in
///     TimeLabel.timeAgo(post.date, now: now, language: language)
/// }
/// ```
public struct TimeLabelText: View {
    @Environment(\.timeLabelLanguage) private var language
    private let refresh: TimeInterval
    private let text: @Sendable (Date, TimeLabel.Language) -> String

    // MARK: - Initializers

    /// - Parameters:
    ///   - refresh: Seconds between updates (minimum 1).
    ///   - text: Builds the label for the current date.
    public init(refresh: TimeInterval = 60, _ text: @escaping @Sendable (Date) -> String) {
        self.init(refresh: refresh) { now, _ in text(now) }
    }

    /// - Parameters:
    ///   - refresh: Seconds between updates (minimum 1).
    ///   - text: Builds the label for the current date and the environment's
    ///     `timeLabelLanguage`.
    public init(refresh: TimeInterval = 60, _ text: @escaping @Sendable (Date, TimeLabel.Language) -> String) {
        self.refresh = max(refresh, 1)
        self.text = text
    }

    /// A live `TimeLabel.relative` label in the environment's
    /// `timeLabelLanguage`. It refreshes every second when `smallestUnit` is
    /// `.second` and every minute otherwise.
    public init(relativeTo date: Date, expandUnits: Bool = false, addSpace: Bool = false, spellNumbers: Bool = false, smallestUnit: TimeLabel.Unit = .minute, largestUnit: TimeLabel.Unit = .hour, rounding: TimeLabel.Rounding = .down) {
        self.init(refresh: smallestUnit == .second ? 1 : 60) { now, language in
            TimeLabel.relative(date, now: now, expandUnits: expandUnits, addSpace: addSpace, spellNumbers: spellNumbers, smallestUnit: smallestUnit, largestUnit: largestUnit, rounding: rounding, language: language)
        }
    }

    // MARK: - Body

    public var body: some View {
        TimelineView(.periodic(from: .now, by: refresh)) { context in
            Text(text(context.date, language))
        }
    }
}

// MARK: - Environment

extension EnvironmentValues {
    /// The language `TimeLabelText` writes in. Defaults to `.english`.
    @Entry public var timeLabelLanguage: TimeLabel.Language = .english
}

extension View {
    /// Sets the language for every `TimeLabelText` inside this view.
    public func timeLabelLanguage(_ language: TimeLabel.Language) -> some View {
        environment(\.timeLabelLanguage, language)
    }
}
#endif
