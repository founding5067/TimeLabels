//
//  TimeLabel+Language.swift
//

import Foundation

extension TimeLabel {
    // MARK: - Unit form

    /// Which spelling of a unit word is being asked for. See `Language.unit`.
    ///
    /// Like `Rounding`, this is a struct rather than an enum so new forms can
    /// be added later without breaking `switch` statements in your code.
    public struct UnitForm: Sendable, Hashable {
        internal enum Mode: Sendable, Hashable { case compact, expanded, durationCompact, durationExpanded }
        internal let mode: Mode

        /// The short form in `timeRemaining`, `timeAgo` and `relative`
        /// (English "h", "mins").
        public static let compact = UnitForm(mode: .compact)
        /// The full word with `expandUnits: true` in `timeRemaining`, `timeAgo`
        /// and `relative` (English "hours").
        public static let expanded = UnitForm(mode: .expanded)
        /// The short form in `duration` (English minutes are "m" there).
        public static let durationCompact = UnitForm(mode: .durationCompact)
        /// The full word with `expandUnits: true` in `duration`. It's separate
        /// because some languages change the word inside a phrase (German
        /// "vor 3 Tagen", but "3 Tage").
        public static let durationExpanded = UnitForm(mode: .durationExpanded)
    }

    // MARK: - Language

    /// The words and locale the helpers write labels with. Pass one as
    /// `language:`; the default is `.english`.
    ///
    /// TimeLabels ships no translations: build a `Language` from your own app's
    /// localized strings. To change only a few words, copy `.english` and
    /// assign to its properties.
    public struct Language: Sendable {
        /// Used for month and weekday names, date and time layouts, and
        /// `spellNumbers`. With `en_US_POSIX` (as in `.english`) dates and times
        /// use the package's fixed English patterns; any other locale uses that
        /// locale's own layouts.
        public var locale: Locale
        /// Wraps a future amount: English turns "5mins" into "In 5mins".
        public var future: @Sendable (String) -> String
        /// Wraps a past amount: English turns "5mins" into "5mins ago".
        public var past: @Sendable (String) -> String
        /// A past (or present) moment closer than one `smallestUnit`.
        public var justNow: String
        /// A future moment closer than one `smallestUnit`.
        public var now: String
        /// `date`'s and `dateTime`'s name for today (with `nameToday`).
        public var today: String
        /// `date`'s and `dateTime`'s name for tomorrow.
        public var tomorrow: String
        /// `date`'s and `dateTime`'s name for yesterday (with `useRelativeDays`).
        public var yesterday: String
        /// What `dateTime` puts between the date and the time when no
        /// `separator:` is passed, including any spaces (English " at ").
        public var separator: String
        /// The word for a unit, given the count it follows so you can choose a
        /// plural form. Return only the word: the number and the optional space
        /// (`addSpace`) are added for you.
        public var unit: @Sendable (Unit, Int, UnitForm) -> String

        public init(
            locale: Locale,
            future: @escaping @Sendable (String) -> String,
            past: @escaping @Sendable (String) -> String,
            justNow: String,
            now: String,
            today: String,
            tomorrow: String,
            yesterday: String,
            separator: String,
            unit: @escaping @Sendable (Unit, Int, UnitForm) -> String
        ) {
            self.locale = locale
            self.future = future
            self.past = past
            self.justNow = justNow
            self.now = now
            self.today = today
            self.tomorrow = tomorrow
            self.yesterday = yesterday
            self.separator = separator
            self.unit = unit
        }

        /// The default: English words and fixed `en_US_POSIX` patterns, so the
        /// output is the same on every device.
        public static let english = Language(
            locale: Locale(identifier: posixIdentifier),
            future: { "In \($0)" },
            past: { "\($0) ago" },
            justNow: "Just now",
            now: "Now",
            today: "Today",
            tomorrow: "Tomorrow",
            yesterday: "Yesterday",
            separator: " at ",
            unit: { unit, count, form in
                if form == .durationCompact, unit == .minute { return "m" }
                let expanded = form == .expanded || form == .durationExpanded
                return pluralUnit(count: count, expandUnits: expanded, unit: unit)
            }
        )

        private static let posixIdentifier = "en_US_POSIX"

        internal var usesFixedPatterns: Bool { locale.identifier == Self.posixIdentifier }
    }
}
