//
//  TuningTests.swift
//  Stay TunedTests
//
//  Tests for Tuning and GuitarString models
//

import Foundation
import Testing
@testable import Stay_Tuned

struct GuitarStringTests {
    
    @Test("GuitarString fullName combines name and octave")
    func testFullName() {
        let string = GuitarString(id: 0, name: "E", frequency: 82.41, octave: 2)
        #expect(string.fullName == "E2")
    }
    
    @Test("GuitarString stringNumber converts from index correctly")
    func testStringNumber() {
        // Index 0 = low E = string 6
        let lowE = GuitarString(id: 0, name: "E", frequency: 82.41, octave: 2)
        #expect(lowE.stringNumber == 6)
        
        // Index 5 = high E = string 1
        let highE = GuitarString(id: 5, name: "E", frequency: 329.63, octave: 4)
        #expect(highE.stringNumber == 1)
        
        // Index 2 = D = string 4
        let dString = GuitarString(id: 2, name: "D", frequency: 146.83, octave: 3)
        #expect(dString.stringNumber == 4)
    }
    
    @Test("GuitarString is Hashable")
    func testHashable() {
        let string1 = GuitarString(id: 0, name: "E", frequency: 82.41, octave: 2)
        let string2 = GuitarString(id: 0, name: "E", frequency: 82.41, octave: 2)
        
        #expect(string1 == string2)
        #expect(string1.hashValue == string2.hashValue)
    }
}

struct TuningTests {
    
    // MARK: - Standard Tuning Tests
    
    @Test("Standard tuning has 6 strings")
    func testStandardTuningStringCount() {
        let standard = Tuning.standard
        #expect(standard.strings.count == 6)
    }
    
    @Test("Standard tuning has correct string frequencies")
    func testStandardTuningFrequencies() {
        let standard = Tuning.standard
        let expectedFrequencies = [82.41, 110.00, 146.83, 196.00, 246.94, 329.63]
        
        for (index, expected) in expectedFrequencies.enumerated() {
            #expect(abs(standard.strings[index].frequency - expected) < 0.1,
                   "String \(index) frequency should be ~\(expected)Hz")
        }
    }
    
    @Test("Standard tuning has correct string names")
    func testStandardTuningNames() {
        let standard = Tuning.standard
        let expectedNames = ["E", "A", "D", "G", "B", "E"]
        
        for (index, expected) in expectedNames.enumerated() {
            #expect(standard.strings[index].name == expected,
                   "String \(index) should be \(expected)")
        }
    }
    
    // MARK: - Closest String Detection Tests
    
    @Test("closestString finds exact match")
    func testClosestStringExactMatch() {
        let standard = Tuning.standard
        
        // Exact A string frequency
        let closest = standard.closestString(to: 110.0)
        #expect(closest?.name == "A")
        #expect(closest?.octave == 2)
    }
    
    @Test("closestString finds nearest when slightly sharp")
    func testClosestStringSlightlySharp() {
        let standard = Tuning.standard
        
        // A2 slightly sharp (115Hz instead of 110Hz)
        let closest = standard.closestString(to: 115.0)
        #expect(closest?.name == "A")
    }
    
    @Test("closestString finds nearest when slightly flat")
    func testClosestStringSlightlyFlat() {
        let standard = Tuning.standard
        
        // A2 slightly flat (105Hz instead of 110Hz)
        let closest = standard.closestString(to: 105.0)
        #expect(closest?.name == "A")
    }
    
    @Test("closestString handles frequency between strings")
    func testClosestStringBetweenStrings() {
        let standard = Tuning.standard
        
        // Frequency between A2 (110Hz) and D3 (146.83Hz)
        // 125Hz is closer to A2
        let closerToA = standard.closestString(to: 125.0)
        #expect(closerToA?.name == "A")
        
        // 135Hz is closer to D3
        let closerToD = standard.closestString(to: 135.0)
        #expect(closerToD?.name == "D")
    }
    
    @Test("closestString finds low E for very low frequency")
    func testClosestStringVeryLow() {
        let standard = Tuning.standard
        
        // Very low frequency should match low E
        let closest = standard.closestString(to: 75.0)
        #expect(closest?.name == "E")
        #expect(closest?.octave == 2)
    }
    
    @Test("closestString finds high E for very high frequency")
    func testClosestStringVeryHigh() {
        let standard = Tuning.standard
        
        // Very high frequency should match high E
        let closest = standard.closestString(to: 350.0)
        #expect(closest?.name == "E")
        #expect(closest?.octave == 4)
    }
    
    @Test("closestString returns nil for empty tuning")
    func testClosestStringEmptyTuning() {
        let empty = Tuning(id: "empty", name: "Empty", instrument: "Test", strings: [])
        let closest = empty.closestString(to: 110.0)
        #expect(closest == nil)
    }
    
    // MARK: - Drop D Tuning Tests
    
    @Test("Drop D tuning has low D instead of low E")
    func testDropDTuning() {
        let dropD = Tuning.guitarDropD
        
        // First string should be D2 (~73.42 Hz) instead of E2 (~82.41 Hz)
        #expect(dropD.strings[0].name == "D")
        #expect(dropD.strings[0].octave == 2)
        #expect(dropD.strings[0].frequency < 75.0)
    }
    
    // MARK: - Tuning Identity Tests
    
    @Test("Tuning is Hashable and can be used in Sets")
    func testTuningHashable() {
        var tuningSet: Set<Tuning> = []
        tuningSet.insert(Tuning.standard)
        tuningSet.insert(Tuning.guitarDropD)
        
        #expect(tuningSet.count == 2)
        #expect(tuningSet.contains(Tuning.standard))
    }
    
    @Test("All tunings have unique IDs")
    func testAllTuningsUniqueIds() {
        let allTunings = Tuning.allTunings
        let ids = Set(allTunings.map { $0.id })
        
        #expect(ids.count == allTunings.count, "All tuning IDs should be unique")
    }
}

// MARK: - Cents Deviation Calculation Tests

struct CentsDeviationTests {
    
    @Test("Same frequency has 0 cents deviation")
    func testZeroCentsDeviation() {
        // Using the formula: 1200 * log2(detected / target)
        let detected = 440.0
        let target = 440.0
        let cents = 1200 * log2(detected / target)
        
        #expect(abs(cents) < 0.001)
    }
    
    @Test("One semitone up is 100 cents")
    func testOneSemitoneUp() {
        // A#4 = 440 * 2^(1/12) ≈ 466.16 Hz
        let detected = 466.16
        let target = 440.0
        let cents = 1200 * log2(detected / target)
        
        #expect(abs(cents - 100) < 1)
    }
    
    @Test("One semitone down is -100 cents")
    func testOneSemitoneDown() {
        // G#4 = 440 * 2^(-1/12) ≈ 415.30 Hz
        let detected = 415.30
        let target = 440.0
        let cents = 1200 * log2(detected / target)
        
        #expect(abs(cents + 100) < 1)
    }
    
    @Test("One octave up is 1200 cents")
    func testOneOctaveUp() {
        let detected = 880.0  // A5
        let target = 440.0    // A4
        let cents = 1200 * log2(detected / target)
        
        #expect(abs(cents - 1200) < 0.001)
    }
}

