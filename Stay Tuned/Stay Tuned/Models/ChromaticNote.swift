//
//  ChromaticNote.swift
//  Stay Tuned
//
//  Created by Nick MacCarthy on 12/25/25.
//

import Foundation

/// Represents a detected chromatic note with its properties
struct ChromaticNote: Equatable {
    let name: String
    let octave: Int
    let frequency: Double
    let centsDeviation: Int
    
    /// Full note name with octave (e.g., "C#4", "A4")
    var fullName: String {
        "\(name)\(octave)"
    }
    
    /// Target frequency for this note (the exact in-tune frequency)
    var targetFrequency: Double {
        // Calculate the exact frequency for this note
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        guard let noteIndex = noteNames.firstIndex(of: name) else { return frequency }
        
        // Semitones from A4: A is index 9, so offset from A in the octave
        // A4 = 440Hz, each semitone is 2^(1/12) ratio
        let semitonesFromA4 = (octave - 4) * 12 + (noteIndex - 9)
        return 440.0 * pow(2.0, Double(semitonesFromA4) / 12.0)
    }
    
    // MARK: - Note Names
    
    private static let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    
    // MARK: - Factory Method
    
    /// Create a ChromaticNote from a detected frequency
    /// - Parameters:
    ///   - frequency: The detected frequency in Hz
    ///   - referencePitch: The reference pitch for A4 (default 440Hz)
    /// - Returns: A ChromaticNote representing the closest note to the frequency
    static func from(frequency: Double, referencePitch: Double = 440.0) -> ChromaticNote {
        guard frequency > 0 else {
            return ChromaticNote(name: "A", octave: 4, frequency: frequency, centsDeviation: 0)
        }
        
        // Calculate semitones from A4
        // Formula: semitones = 12 × log2(frequency / 440.0)
        let semitonesFromA4 = 12.0 * log2(frequency / referencePitch)
        
        // Round to nearest semitone
        let roundedSemitones = round(semitonesFromA4)
        
        // Calculate cents deviation (how far from the nearest note)
        // Formula: cents = (semitones - roundedSemitones) × 100
        let cents = Int(round((semitonesFromA4 - roundedSemitones) * 100))
        
        // Calculate note index (0-11, where 0 = C)
        // A4 is at index 9 in our note names array
        // We need to offset by 9 to align with our array starting at C
        var noteIndex = Int(roundedSemitones) % 12 + 9
        if noteIndex < 0 {
            noteIndex += 12
        }
        noteIndex = noteIndex % 12
        
        // Calculate octave
        // A4 is semitone 0, C4 is semitone -9, C5 is semitone 3
        // Octave = 4 + floor((semitones + 9) / 12)
        let octave = 4 + Int(floor((roundedSemitones + 9) / 12))
        
        let noteName = noteNames[noteIndex]
        
        return ChromaticNote(
            name: noteName,
            octave: octave,
            frequency: frequency,
            centsDeviation: cents
        )
    }
}

