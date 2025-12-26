//
//  TimeSignatureTests.swift
//  Stay TunedTests
//
//  Tests for TimeSignature model
//

import Testing
@testable import Stay_Tuned

struct TimeSignatureTests {
    
    // MARK: - All Cases Tests
    
    @Test("All time signature cases exist")
    func allCasesExist() {
        let allCases = TimeSignature.allCases
        #expect(allCases.count == 4)
        #expect(allCases.contains(.fourFour))
        #expect(allCases.contains(.threeFour))
        #expect(allCases.contains(.sixEight))
        #expect(allCases.contains(.twoFour))
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
    
    @Test("6/8 time signature has 6 beats per measure")
    func sixEightBeatsPerMeasure() {
        #expect(TimeSignature.sixEight.beatsPerMeasure == 6)
    }
    
    @Test("2/4 time signature has 2 beats per measure")
    func twoFourBeatsPerMeasure() {
        #expect(TimeSignature.twoFour.beatsPerMeasure == 2)
    }
    
    // MARK: - Raw Value Tests
    
    @Test("Raw values are correct for persistence")
    func rawValuesCorrect() {
        #expect(TimeSignature.fourFour.rawValue == "4/4")
        #expect(TimeSignature.threeFour.rawValue == "3/4")
        #expect(TimeSignature.sixEight.rawValue == "6/8")
        #expect(TimeSignature.twoFour.rawValue == "2/4")
    }
    
    @Test("Can create from raw value")
    func createFromRawValue() {
        #expect(TimeSignature(rawValue: "4/4") == .fourFour)
        #expect(TimeSignature(rawValue: "3/4") == .threeFour)
        #expect(TimeSignature(rawValue: "6/8") == .sixEight)
        #expect(TimeSignature(rawValue: "2/4") == .twoFour)
    }
    
    @Test("Invalid raw value returns nil")
    func invalidRawValueReturnsNil() {
        #expect(TimeSignature(rawValue: "5/4") == nil)
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
}


