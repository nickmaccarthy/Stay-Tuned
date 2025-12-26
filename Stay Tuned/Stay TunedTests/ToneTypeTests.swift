//
//  ToneTypeTests.swift
//  Stay TunedTests
//
//  Tests for ToneType enum
//

import Foundation
import Testing
@testable import Stay_Tuned

// MARK: - ToneType Tests

struct ToneTypeTests {

    @Test("ToneType has two cases: sine and string")
    func testToneTypeCases() {
        let allCases = ToneType.allCases
        #expect(allCases.count == 2)
        #expect(allCases.contains(.sine))
        #expect(allCases.contains(.string))
    }

    @Test("ToneType raw values are correct")
    func testRawValues() {
        #expect(ToneType.sine.rawValue == "sine")
        #expect(ToneType.string.rawValue == "string")
    }

    @Test("ToneType can be created from raw value")
    func testFromRawValue() {
        let sine = ToneType(rawValue: "sine")
        let string = ToneType(rawValue: "string")
        let invalid = ToneType(rawValue: "invalid")

        #expect(sine == .sine)
        #expect(string == .string)
        #expect(invalid == nil)
    }

    @Test("ToneType display names are user-friendly")
    func testDisplayNames() {
        #expect(ToneType.sine.displayName == "Sine Wave")
        #expect(ToneType.string.displayName == "Plucked String")
    }

    @Test("ToneType descriptions are informative")
    func testDescriptions() {
        #expect(ToneType.sine.description == "Pure, clean tone")
        #expect(ToneType.string.description == "Realistic guitar sound")
    }

    @Test("ToneType has valid SF Symbol icons")
    func testIconNames() {
        #expect(ToneType.sine.iconName == "waveform")
        #expect(ToneType.string.iconName == "guitars")
    }

    @Test("ToneType id matches raw value")
    func testId() {
        #expect(ToneType.sine.id == ToneType.sine.rawValue)
        #expect(ToneType.string.id == ToneType.string.rawValue)
    }
}
