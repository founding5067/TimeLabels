import Foundation
import Testing
@testable import TimeLabels

// MARK: - Sample language

private let german = TimeLabel.Language(
    locale: Locale(identifier: "de_DE"),
    future: { "in \($0)" },
    past: { "vor \($0)" },
    justNow: "Gerade eben",
    now: "Jetzt",
    today: "Heute",
    tomorrow: "Morgen",
    yesterday: "Gestern",
    separator: " um ",
    unit: { unit, count, form in
        let one = count == 1
        switch (unit, form) {
        case (.minute, .expanded), (.minute, .durationExpanded): return one ? "Minute" : "Minuten"
        case (.minute, .durationCompact): return "m"
        case (.minute, _): return "Min."
        case (.hour, .expanded), (.hour, .durationExpanded): return one ? "Stunde" : "Stunden"
        case (.hour, _): return "Std."
        case (.day, .expanded): return one ? "Tag" : "Tagen"
        case (.day, .durationExpanded): return one ? "Tag" : "Tage"
        default: return "?"
        }
    }
)

// MARK: - English default

@Test func explicitEnglishMatchesTheDefault() {
    let utc = utcCalendar()
    for offset in [-2 * week, -3 * day, -day, -5400, -300, -1, 0, 1, 300, 5400, day, 3 * day, 400 * day] {
        let date = ahead(offset)
        for flag in [false, true] {
            #expect(TimeLabel.timeRemaining(offset, expandUnits: flag, spellNumbers: flag, language: .english)
                == TimeLabel.timeRemaining(offset, expandUnits: flag, spellNumbers: flag))
            #expect(TimeLabel.timeAgo(date, now: fixedDate, calendar: utc, addSpace: flag, language: .english)
                == TimeLabel.timeAgo(date, now: fixedDate, calendar: utc, addSpace: flag))
            #expect(TimeLabel.relative(date, now: fixedDate, expandUnits: flag, language: .english)
                == TimeLabel.relative(date, now: fixedDate, expandUnits: flag))
            #expect(TimeLabel.time(date, calendar: utc, use24Hour: flag, language: .english)
                == TimeLabel.time(date, calendar: utc, use24Hour: flag))
            #expect(TimeLabel.timeRange(fixedDate, date, calendar: utc, use24Hour: flag, language: .english)
                == TimeLabel.timeRange(fixedDate, date, calendar: utc, use24Hour: flag))
            #expect(TimeLabel.dateTime(date, now: fixedDate, calendar: utc, useRelativeDays: flag, includeWeekday: flag, language: .english)
                == TimeLabel.dateTime(date, now: fixedDate, calendar: utc, useRelativeDays: flag, includeWeekday: flag))
            #expect(TimeLabel.duration(abs(offset), expandUnits: flag, addSpace: flag, language: .english)
                == TimeLabel.duration(abs(offset), expandUnits: flag, addSpace: flag))
        }
    }
}

@Test func editedEnglishCopyKeepsFixedPatterns() {
    var language = TimeLabel.Language.english
    language.justNow = "Moments ago"
    #expect(TimeLabel.timeAgo(fixedDate, now: fixedDate, language: language) == "Moments ago")
    #expect(TimeLabel.time(fixedDate, calendar: utcCalendar(), language: language) == "3:30 PM")
}

// MARK: - Relative

@Test func customLanguageWrapsRelativeLabels() {
    #expect(TimeLabel.timeRemaining(300, language: german) == "in 5Min.")
    #expect(TimeLabel.timeRemaining(until: ahead(300), now: fixedDate, addSpace: true, language: german) == "in 5 Min.")
    #expect(TimeLabel.timeAgo(ago(7200), now: fixedDate, addSpace: true, language: german) == "vor 2 Std.")
    #expect(TimeLabel.relative(ahead(7200), now: fixedDate, addSpace: true, language: german) == "in 2 Std.")
    #expect(TimeLabel.relative(ago(300), now: fixedDate, addSpace: true, language: german) == "vor 5 Min.")
    #expect(TimeLabel.timeAgo(fixedDate, now: fixedDate, language: german) == "Gerade eben")
    #expect(TimeLabel.relative(fixedDate, now: fixedDate, language: german) == "Gerade eben")
    #expect(TimeLabel.relative(ahead(1), now: fixedDate, language: german) == "Jetzt")
}

@Test func customLanguageReceivesCountsForPlurals() {
    #expect(TimeLabel.timeRemaining(60, expandUnits: true, addSpace: true, language: german) == "in 1 Minute")
    #expect(TimeLabel.timeRemaining(120, expandUnits: true, addSpace: true, language: german) == "in 2 Minuten")
}

@Test func customLanguageFollowsTheSpacingContract() {
    #expect(TimeLabel.timeRemaining(300, expandUnits: true, language: german) == "in 5Minuten")
    #expect(TimeLabel.timeRemaining(300, spellNumbers: true, language: german) == "in fünfMin.")
    #expect(TimeLabel.timeRemaining(300, addSpace: true, spellNumbers: true, language: german) == "in fünf Min.")
}

@Test func futureTimeAgoUsesTheLocalizedDate() {
    #expect(TimeLabel.timeAgo(ahead(day), now: fixedDate, calendar: utcCalendar(), language: german) == "2. Jan. 2021")
}

@Test func customLanguageCanInflectDurationsSeparately() {
    #expect(TimeLabel.timeAgo(ago(3 * day), now: fixedDate, expandUnits: true, addSpace: true, largestUnit: .day, language: german) == "vor 3 Tagen")
    #expect(TimeLabel.duration(3 * day, expandUnits: true, addSpace: true, largestUnit: .day, language: german) == "3 Tage")
}

// MARK: - Calendar

@Test func customLanguageNamesDays() {
    let utc = utcCalendar()
    #expect(TimeLabel.date(fixedDate, now: fixedDate, calendar: utc, nameToday: true, language: german) == "Heute")
    #expect(TimeLabel.date(fixedDate, now: fixedDate, calendar: utc, language: german) == "")
    #expect(TimeLabel.date(ahead(day), now: fixedDate, calendar: utc, language: german) == "Morgen")
    #expect(TimeLabel.date(ahead(day), now: fixedDate, calendar: utc, useRelativeDays: true, language: german) == "Morgen")
    #expect(TimeLabel.date(ago(day), now: fixedDate, calendar: utc, useRelativeDays: true, language: german) == "Gestern")
    #expect(TimeLabel.date(ahead(3 * day), now: fixedDate, calendar: utc, useRelativeDays: true, language: german) == "Montag")
}

@Test func customLanguageUsesLocaleDateOrder() {
    let utc = utcCalendar()
    let june = makeDate(2021, 6, 20, in: utc)
    let text = TimeLabel.date(june, now: fixedDate, calendar: utc, omitCurrentYear: true, includeWeekday: true, language: german)
    #expect(text == "Sonntag, 20. Juni")
}

@Test func customLanguageStaysGregorian() {
    var thai = german
    thai.locale = Locale(identifier: "th_TH")
    let text = TimeLabel.date(ahead(10 * day), now: fixedDate, calendar: utcCalendar(), language: thai)
    #expect(text.contains("2021"))
}

@Test func customLanguageClockAndRange() {
    let utc = utcCalendar()
    #expect(TimeLabel.time(fixedDate, calendar: utc, language: german) == "15:30")
    #expect(TimeLabel.timeRange(fixedDate, ahead(2700), calendar: utc, language: german) == "15:30 – 16:15")

    var american = TimeLabel.Language.english
    american.locale = Locale(identifier: "en_US")
    let range = TimeLabel.timeRange(fixedDate, ahead(2700), calendar: utc, language: american)
    #expect(range.hasPrefix("3:30"))
    #expect(range.components(separatedBy: "PM").count == 3)
}

@Test func dateTimeSeparatorComesFromTheLanguageUnlessPassed() {
    let utc = utcCalendar()
    #expect(TimeLabel.dateTime(ahead(day), now: fixedDate, calendar: utc, language: german) == "Morgen um 15:30")
    #expect(TimeLabel.dateTime(ahead(day), now: fixedDate, calendar: utc, separator: " · ", language: german) == "Morgen · 15:30")
}

// MARK: - Duration and Date extensions

@Test func customLanguageDurations() {
    #expect(TimeLabel.duration(5400, language: german) == "1Std. 30m")
    #expect(TimeLabel.duration(5400, expandUnits: true, addSpace: true, language: german) == "1 Stunde 30 Minuten")
    #expect(TimeLabel.duration(.seconds(5400), addSpace: true, language: german) == "1 Std. 30 m")
    #expect(TimeLabel.duration(5400, style: .countdown, language: german) == "1:30:00")
}

@Test func dateExtensionsForwardTheLanguage() {
    let utc = utcCalendar()
    let tomorrow = ahead(day)
    #expect(ahead(300).timeRemainingLabel(now: fixedDate, language: german) == "in 5Min.")
    #expect(ago(300).timeAgoLabel(now: fixedDate, language: german) == "vor 5Min.")
    #expect(ago(300).relativeLabel(now: fixedDate, language: german) == "vor 5Min.")
    #expect(fixedDate.timeLabel(calendar: utc, language: german) == "15:30")
    #expect(fixedDate.timeRangeLabel(to: ahead(2700), calendar: utc, language: german) == "15:30 – 16:15")
    #expect(tomorrow.dateLabel(now: fixedDate, calendar: utc, language: german) == "Morgen")
    #expect(tomorrow.dateTimeLabel(now: fixedDate, calendar: utc, language: german) == "Morgen um 15:30")
}
