//
//  ChromaticNoteTests.swift
//  Stay TunedTests
//
//  Tests for ChromaticNote model - chromatic note detection from frequency
//

import Testing
@testable import Stay_Tuned

struct ChromaticNoteTests {
    
    // MARK: - Standard A440 Tests
    
    @Test("A4 at exactly 440Hz should be detected correctly")
    func testA4At440Hz() {
        let note = ChromaticNote.from(frequency: 440.0, referencePitch: 440.0)
        
        #expect(note.name == "A")
        #expect(note.octave == 4)
        #expect(note.centsDeviation == 0)
        #expect(note.fullName == "A4")
    }
    
    @Test("A4 target frequency should be 440Hz")
    func testA4TargetFrequency() {
        let note = ChromaticNote.from(frequency: 440.0, referencePitch: 440.0)
        
        #expect(abs(note.targetFrequency - 440.0) < 0.01)
    }
    
    @Test("C4 (Middle C) at 261.63Hz should be detected correctly")
    func testC4MiddleC() {
        let note = ChromaticNote.from(frequency: 261.63, referencePitch: 440.0)
        
        #expect(note.name == "C")
        #expect(note.octave == 4)
        #expect(abs(note.centsDeviation) <= 1) // Allow 1 cent tolerance for rounding
    }
    
    @Test("E2 (low E guitar string) at 82.41Hz should be detected correctly")
    func testE2LowE() {
        let note = ChromaticNote.from(frequency: 82.41, referencePitch: 440.0)
        
        #expect(note.name == "E")
        #expect(note.octave == 2)
        #expect(abs(note.centsDeviation) <= 1)
    }
    
    @Test("E4 (high E guitar string) at 329.63Hz should be detected correctly")
    func testE4HighE() {
        let note = ChromaticNote.from(frequency: 329.63, referencePitch: 440.0)
        
        #expect(note.name == "E")
        #expect(note.octave == 4)
        #expect(abs(note.centsDeviation) <= 1)
    }
    
    // MARK: - Sharp Notes Tests
    
    @Test("C# should be detected correctly")
    func testCSharp() {
        // C#4 = 277.18 Hz
        let note = ChromaticNote.from(frequency: 277.18, referencePitch: 440.0)
        
        #expect(note.name == "C#")
        #expect(note.octave == 4)
    }
    
    @Test("F# should be detected correctly")
    func testFSharp() {
        // F#4 = 369.99 Hz
        let note = ChromaticNote.from(frequency: 369.99, referencePitch: 440.0)
        
        #expect(note.name == "F#")
        #expect(note.octave == 4)
    }
    
    // MARK: - Cents Deviation Tests
    
    @Test("Frequency slightly sharp should have positive cents")
    func testSharpCentsDeviation() {
        // A4 at 445Hz is about +20 cents sharp
        let note = ChromaticNote.from(frequency: 445.0, referencePitch: 440.0)
        
        #expect(note.name == "A")
        #expect(note.octave == 4)
        #expect(note.centsDeviation > 0)
        #expect(note.centsDeviation < 30) // Should be around +20
    }
    
    @Test("Frequency slightly flat should have negative cents")
    func testFlatCentsDeviation() {
        // A4 at 435Hz is about -20 cents flat
        let note = ChromaticNote.from(frequency: 435.0, referencePitch: 440.0)
        
        #expect(note.name == "A")
        #expect(note.octave == 4)
        #expect(note.centsDeviation < 0)
        #expect(note.centsDeviation > -30) // Should be around -20
    }
    
    @Test("Exactly in tune should have 0 cents deviation")
    func testZeroCentsDeviation() {
        let note = ChromaticNote.from(frequency: 440.0, referencePitch: 440.0)
        #expect(note.centsDeviation == 0)
    }
    
    // MARK: - Reference Pitch Tests
    
    @Test("A4 at 432Hz reference pitch should work correctly")
    func testA432ReferencePitch() {
        let note = ChromaticNote.from(frequency: 432.0, referencePitch: 432.0)
        
        #expect(note.name == "A")
        #expect(note.octave == 4)
        #expect(note.centsDeviation == 0)
    }
    
    @Test("A4 at 440Hz with 432Hz reference should be sharp")
    func testA440With432Reference() {
        let note = ChromaticNote.from(frequency: 440.0, referencePitch: 432.0)
        
        // 440Hz with 432Hz reference is about 32 cents sharp
        #expect(note.centsDeviation > 25)
        #expect(note.centsDeviation < 40)
    }
    
    // MARK: - Edge Cases
    
    @Test("Very low frequency (B0) should be detected")
    func testVeryLowFrequency() {
        // B0 = 30.87 Hz
        let note = ChromaticNote.from(frequency: 30.87, referencePitch: 440.0)
        
        #expect(note.name == "B")
        #expect(note.octave == 0)
    }
    
    @Test("Very high frequency (C8) should be detected")
    func testVeryHighFrequency() {
        // C8 = 4186.01 Hz
        let note = ChromaticNote.from(frequency: 4186.01, referencePitch: 440.0)
        
        #expect(note.name == "C")
        #expect(note.octave == 8)
    }
    
    @Test("Zero frequency should return default note")
    func testZeroFrequency() {
        let note = ChromaticNote.from(frequency: 0, referencePitch: 440.0)
        
        // Should return a default without crashing
        #expect(note.name == "A")
        #expect(note.octave == 4)
    }
    
    @Test("Negative frequency should return default note")
    func testNegativeFrequency() {
        let note = ChromaticNote.from(frequency: -100, referencePitch: 440.0)
        
        // Should return a default without crashing
        #expect(note.name == "A")
        #expect(note.octave == 4)
    }
    
    // MARK: - Full Name Tests
    
    @Test("fullName should combine name and octave correctly")
    func testFullName() {
        let note = ChromaticNote(name: "G#", octave: 5, frequency: 830.61, centsDeviation: 0)
        #expect(note.fullName == "G#5")
    }
    
    // MARK: - Target Frequency Tests
    
    @Test("Target frequency should be exact note frequency")
    func testTargetFrequencyCalculation() {
        // Create a note that's 10 cents sharp of A4
        let note = ChromaticNote.from(frequency: 442.5, referencePitch: 440.0)
        
        // Target should be exactly 440Hz, not the detected 442.5Hz
        #expect(abs(note.targetFrequency - 440.0) < 0.1)
    }
    
    // MARK: - Guitar String Frequencies
    
    @Test("All standard guitar string frequencies should be detected correctly")
    func testStandardGuitarStrings() {
        let guitarStrings: [(frequency: Double, expectedNote: String, expectedOctave: Int)] = [
            (82.41, "E", 2),   // Low E
            (110.00, "A", 2),  // A
            (146.83, "D", 3),  // D
            (196.00, "G", 3),  // G
            (246.94, "B", 3),  // B
            (329.63, "E", 4),  // High E
        ]
        
        for string in guitarStrings {
            let note = ChromaticNote.from(frequency: string.frequency, referencePitch: 440.0)
            #expect(note.name == string.expectedNote, "Expected \(string.expectedNote) for \(string.frequency)Hz")
            #expect(note.octave == string.expectedOctave, "Expected octave \(string.expectedOctave) for \(string.frequency)Hz")
        }
    }
}

