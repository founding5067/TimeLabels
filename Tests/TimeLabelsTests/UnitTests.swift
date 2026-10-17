import Testing
import Foundation
@testable import TimeLabels

// Tests for `TimeLabel.Unit` in TimeLabel.swift.

// MARK: - Ordering

@Test func unit_caseOrderIsSmallestToLargest() {
    #expect(TimeLabel.Unit.allCases == [.second, .minute, .hour, .day, .week])
}

@Test func unit_isComparable() {
    #expect(TimeLabel.Unit.second < .minute)
    #expect(TimeLabel.Unit.minute < .hour)
    #expect(TimeLabel.Unit.hour < .day)
    #expect(TimeLabel.Unit.day < .week)
    #expect(!(TimeLabel.Unit.week < .day))
    #expect(!(TimeLabel.Unit.hour < .hour))
    #expect(TimeLabel.Unit.allCases.sorted() == TimeLabel.Unit.allCases)
}

// MARK: - Lengths

@Test func unit_secondsValues() {
    #expect(TimeLabel.Unit.second.seconds == 1)
    #expect(TimeLabel.Unit.minute.seconds == 60)
    #expect(TimeLabel.Unit.hour.seconds == 3600)
    #expect(TimeLabel.Unit.day.seconds == 86_400)
    #expect(TimeLabel.Unit.week.seconds == 604_800)
    #expect(TimeLabel.Unit.week.seconds == 7 * TimeLabel.Unit.day.seconds)
}
