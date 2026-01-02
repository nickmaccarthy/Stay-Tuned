//
//  TimeSignatureTests.swift
//  Stay TunedTests
//
//  Tests for TimeSignature and BeatGrouping models
//

import Testing
@testable import Stay_Tuned

struct TimeSignatureTests {

    // MARK: - All Cases Tests

    @Test("All time signature cases exist")
    func allCasesExist() {
        let allCases = TimeSignature.allCases
        #expect(allCases.count == 10)
        #expect(allCases.contains(.fourFour))
        #expect(allCases.contains(.threeFour))
        #expect(allCases.contains(.twoFour))
        #expect(allCases.contains(.sixEight))
        #expect(allCases.contains(.fiveFour))
        #expect(allCases.contains(.sevenFour))
        #expect(allCases.contains(.fiveEight))
        #expect(allCases.contains(.sevenEight))
        #expect(allCases.contains(.nineEight))
        #expect(allCases.contains(.twelveEight))
    }

    // MARK: - Beats Per Measure Tests

    @Test("4/4 time signature has 4 beats per measure")
    func fourFourBeatsPerMeasure() {
        #expect(TimeSignature.fourFour.beatsPerMeasure == 4)
    }

    @Test("3/4 time signature has 3 beats per measure")
    func threeFourBeatsPerMeasure() {
        #expect(TimeSignature.threeFour.beatsPerMeasure == 3)
    }

    @Test("2/4 time signature has 2 beats per measure")
    func twoFourBeatsPerMeasure() {
        #expect(TimeSignature.twoFour.beatsPerMeasure == 2)
    }

    @Test("6/8 time signature has 6 beats per measure")
    func sixEightBeatsPerMeasure() {
        #expect(TimeSignature.sixEight.beatsPerMeasure == 6)
    }

    @Test("5/4 time signature has 5 beats per measure")
    func fiveFourBeatsPerMeasure() {
        #expect(TimeSignature.fiveFour.beatsPerMeasure == 5)
    }

    @Test("7/4 time signature has 7 beats per measure")
    func sevenFourBeatsPerMeasure() {
        #expect(TimeSignature.sevenFour.beatsPerMeasure == 7)
    }

    @Test("5/8 time signature has 5 beats per measure")
    func fiveEightBeatsPerMeasure() {
        #expect(TimeSignature.fiveEight.beatsPerMeasure == 5)
    }

    @Test("7/8 time signature has 7 beats per measure")
    func sevenEightBeatsPerMeasure() {
        #expect(TimeSignature.sevenEight.beatsPerMeasure == 7)
    }

    @Test("9/8 time signature has 9 beats per measure")
    func nineEightBeatsPerMeasure() {
        #expect(TimeSignature.nineEight.beatsPerMeasure == 9)
    }

    @Test("12/8 time signature has 12 beats per measure")
    func twelveEightBeatsPerMeasure() {
        #expect(TimeSignature.twelveEight.beatsPerMeasure == 12)
    }

    // MARK: - Raw Value Tests

    @Test("Raw values are correct for persistence")
    func rawValuesCorrect() {
        #expect(TimeSignature.fourFour.rawValue == "4/4")
        #expect(TimeSignature.threeFour.rawValue == "3/4")
        #expect(TimeSignature.twoFour.rawValue == "2/4")
        #expect(TimeSignature.sixEight.rawValue == "6/8")
        #expect(TimeSignature.fiveFour.rawValue == "5/4")
        #expect(TimeSignature.sevenFour.rawValue == "7/4")
        #expect(TimeSignature.fiveEight.rawValue == "5/8")
        #expect(TimeSignature.sevenEight.rawValue == "7/8")
        #expect(TimeSignature.nineEight.rawValue == "9/8")
        #expect(TimeSignature.twelveEight.rawValue == "12/8")
    }

    @Test("Can create from raw value")
    func createFromRawValue() {
        #expect(TimeSignature(rawValue: "4/4") == .fourFour)
        #expect(TimeSignature(rawValue: "3/4") == .threeFour)
        #expect(TimeSignature(rawValue: "2/4") == .twoFour)
        #expect(TimeSignature(rawValue: "6/8") == .sixEight)
        #expect(TimeSignature(rawValue: "5/4") == .fiveFour)
        #expect(TimeSignature(rawValue: "7/4") == .sevenFour)
        #expect(TimeSignature(rawValue: "5/8") == .fiveEight)
        #expect(TimeSignature(rawValue: "7/8") == .sevenEight)
        #expect(TimeSignature(rawValue: "9/8") == .nineEight)
        #expect(TimeSignature(rawValue: "12/8") == .twelveEight)
    }

    @Test("Invalid raw value returns nil")
    func invalidRawValueReturnsNil() {
        #expect(TimeSignature(rawValue: "11/4") == nil)
        #expect(TimeSignature(rawValue: "invalid") == nil)
        #expect(TimeSignature(rawValue: "") == nil)
    }

    // MARK: - Display Name Tests

    @Test("Display names match raw values")
    func displayNamesMatchRawValues() {
        for timeSignature in TimeSignature.allCases {
            #expect(timeSignature.displayName == timeSignature.rawValue)
        }
    }

    // MARK: - Identifiable Conformance Tests

    @Test("ID matches raw value for Identifiable conformance")
    func idMatchesRawValue() {
        for timeSignature in TimeSignature.allCases {
            #expect(timeSignature.id == timeSignature.rawValue)
        }
    }

    // MARK: - Available Groupings Tests

    @Test("Simple time signatures have single grouping")
    func simpleTimeSignaturesHaveSingleGrouping() {
        #expect(TimeSignature.fourFour.availableGroupings.count == 1)
        #expect(TimeSignature.threeFour.availableGroupings.count == 1)
        #expect(TimeSignature.twoFour.availableGroupings.count == 1)
    }

    @Test("Compound time signatures have single grouping")
    func compoundTimeSignaturesHaveSingleGrouping() {
        #expect(TimeSignature.sixEight.availableGroupings.count == 1)
        #expect(TimeSignature.nineEight.availableGroupings.count == 1)
        #expect(TimeSignature.twelveEight.availableGroupings.count == 1)
    }

    @Test("Odd meters have multiple grouping options")
    func oddMetersHaveMultipleGroupings() {
        #expect(TimeSignature.fiveFour.availableGroupings.count == 2)
        #expect(TimeSignature.fiveEight.availableGroupings.count == 2)
        #expect(TimeSignature.sevenFour.availableGroupings.count == 3)
        #expect(TimeSignature.sevenEight.availableGroupings.count == 3)
    }

    @Test("hasMultipleGroupings returns correct value")
    func hasMultipleGroupingsCorrect() {
        // Simple meters - no multiple groupings
        #expect(TimeSignature.fourFour.hasMultipleGroupings == false)
        #expect(TimeSignature.threeFour.hasMultipleGroupings == false)
        #expect(TimeSignature.twoFour.hasMultipleGroupings == false)
        #expect(TimeSignature.sixEight.hasMultipleGroupings == false)
        #expect(TimeSignature.nineEight.hasMultipleGroupings == false)
        #expect(TimeSignature.twelveEight.hasMultipleGroupings == false)

        // Odd meters - have multiple groupings
        #expect(TimeSignature.fiveFour.hasMultipleGroupings == true)
        #expect(TimeSignature.fiveEight.hasMultipleGroupings == true)
        #expect(TimeSignature.sevenFour.hasMultipleGroupings == true)
        #expect(TimeSignature.sevenEight.hasMultipleGroupings == true)
    }

    @Test("Default grouping is first available grouping")
    func defaultGroupingIsFirst() {
        for timeSignature in TimeSignature.allCases {
            #expect(timeSignature.defaultGrouping == timeSignature.availableGroupings[0])
        }
    }
}

// MARK: - BeatGrouping Tests

struct BeatGroupingTests {

    // MARK: - Display Name Tests

    @Test("Display name shows groups joined by plus")
    func displayNameFormat() {
        let grouping1 = BeatGrouping(groups: [3, 2])
        #expect(grouping1.displayName == "3+2")

        let grouping2 = BeatGrouping(groups: [2, 2, 3])
        #expect(grouping2.displayName == "2+2+3")

        let grouping3 = BeatGrouping(groups: [4])
        #expect(grouping3.displayName == "4")
    }

    // MARK: - Accent Position Tests

    @Test("Accent positions for 3+2 grouping")
    func accentPositions3Plus2() {
        let grouping = BeatGrouping(groups: [3, 2])
        #expect(grouping.accentPositions == [1, 4])
    }

    @Test("Accent positions for 2+3 grouping")
    func accentPositions2Plus3() {
        let grouping = BeatGrouping(groups: [2, 3])
        #expect(grouping.accentPositions == [1, 3])
    }

    @Test("Accent positions for 4+3 grouping")
    func accentPositions4Plus3() {
        let grouping = BeatGrouping(groups: [4, 3])
        #expect(grouping.accentPositions == [1, 5])
    }

    @Test("Accent positions for 2+2+3 grouping")
    func accentPositions2Plus2Plus3() {
        let grouping = BeatGrouping(groups: [2, 2, 3])
        #expect(grouping.accentPositions == [1, 3, 5])
    }

    @Test("Accent positions for 3+3+3 grouping")
    func accentPositions3Plus3Plus3() {
        let grouping = BeatGrouping(groups: [3, 3, 3])
        #expect(grouping.accentPositions == [1, 4, 7])
    }

    @Test("Accent positions for 3+3+3+3 grouping")
    func accentPositions3Plus3Plus3Plus3() {
        let grouping = BeatGrouping(groups: [3, 3, 3, 3])
        #expect(grouping.accentPositions == [1, 4, 7, 10])
    }

    @Test("Single group accent position")
    func singleGroupAccentPosition() {
        let grouping = BeatGrouping(groups: [4])
        #expect(grouping.accentPositions == [1])
    }

    // MARK: - Total Beats Tests

    @Test("Total beats calculated correctly")
    func totalBeatsCalculation() {
        #expect(BeatGrouping(groups: [3, 2]).totalBeats == 5)
        #expect(BeatGrouping(groups: [2, 2, 3]).totalBeats == 7)
        #expect(BeatGrouping(groups: [3, 3, 3]).totalBeats == 9)
        #expect(BeatGrouping(groups: [3, 3, 3, 3]).totalBeats == 12)
        #expect(BeatGrouping(groups: [4]).totalBeats == 4)
    }

    // MARK: - Identifiable Conformance Tests

    @Test("ID matches display name")
    func idMatchesDisplayName() {
        let grouping = BeatGrouping(groups: [3, 2])
        #expect(grouping.id == grouping.displayName)
    }

    // MARK: - Hashable Conformance Tests

    @Test("Equal groupings are equal")
    func equalGroupingsAreEqual() {
        let grouping1 = BeatGrouping(groups: [3, 2])
        let grouping2 = BeatGrouping(groups: [3, 2])
        #expect(grouping1 == grouping2)
    }

    @Test("Different groupings are not equal")
    func differentGroupingsAreNotEqual() {
        let grouping1 = BeatGrouping(groups: [3, 2])
        let grouping2 = BeatGrouping(groups: [2, 3])
        #expect(grouping1 != grouping2)
    }
}
