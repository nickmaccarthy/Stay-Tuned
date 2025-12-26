//
//  TuningPresets.swift
//  Stay Tuned
//
//  All supported instrument tunings organized by instrument type.
//  Add new tunings by creating a new static Tuning and adding it to the instrument.
//

import Foundation

// MARK: - ===========================================
// MARK: - GUITAR TUNINGS
// MARK: - ===========================================

extension Instrument {
    
    static let guitar = Instrument(
        id: "guitar",
        name: "Guitar",
        icon: "guitars",
        stringCount: 6,
        tunings: Tuning.guitarTunings
    )
}

extension Tuning {
    
    // MARK: Guitar - Standard Tunings
    
    /// Standard guitar tuning (E A D G B E)
    static let guitarStandard = Tuning(
        id: "guitar_standard",
        name: "Standard",
        instrument: "Guitar",
        strings: [
            GuitarString(id: 0, name: "E", frequency: 82.41, octave: 2),   // Low E (E2)
            GuitarString(id: 1, name: "A", frequency: 110.00, octave: 2),  // A (A2)
            GuitarString(id: 2, name: "D", frequency: 146.83, octave: 3),  // D (D3)
            GuitarString(id: 3, name: "G", frequency: 196.00, octave: 3),  // G (G3)
            GuitarString(id: 4, name: "B", frequency: 246.94, octave: 3),  // B (B3)
            GuitarString(id: 5, name: "E", frequency: 329.63, octave: 4)   // High E (E4)
        ]
    )
    
    /// Half step down tuning (Eb Ab Db Gb Bb Eb)
    static let guitarHalfStepDown = Tuning(
        id: "guitar_halfStepDown",
        name: "Half Step Down",
        instrument: "Guitar",
        strings: [
            GuitarString(id: 0, name: "E♭", frequency: 77.78, octave: 2),  // Eb2
            GuitarString(id: 1, name: "A♭", frequency: 103.83, octave: 2), // Ab2
            GuitarString(id: 2, name: "D♭", frequency: 138.59, octave: 3), // Db3
            GuitarString(id: 3, name: "G♭", frequency: 185.00, octave: 3), // Gb3
            GuitarString(id: 4, name: "B♭", frequency: 233.08, octave: 3), // Bb3
            GuitarString(id: 5, name: "E♭", frequency: 311.13, octave: 4)  // Eb4
        ]
    )
    
    /// Whole step down tuning (D G C F A D)
    static let guitarWholeStepDown = Tuning(
        id: "guitar_wholeStepDown",
        name: "Whole Step Down",
        instrument: "Guitar",
        strings: [
            GuitarString(id: 0, name: "D", frequency: 73.42, octave: 2),   // D2
            GuitarString(id: 1, name: "G", frequency: 98.00, octave: 2),   // G2
            GuitarString(id: 2, name: "C", frequency: 130.81, octave: 3),  // C3
            GuitarString(id: 3, name: "F", frequency: 174.61, octave: 3),  // F3
            GuitarString(id: 4, name: "A", frequency: 220.00, octave: 3),  // A3
            GuitarString(id: 5, name: "D", frequency: 293.66, octave: 4)   // D4
        ]
    )
    
    // MARK: Guitar - Drop Tunings
    
    /// Drop D tuning (D A D G B E)
    static let guitarDropD = Tuning(
        id: "guitar_dropD",
        name: "Drop D",
        instrument: "Guitar",
        strings: [
            GuitarString(id: 0, name: "D", frequency: 73.42, octave: 2),   // D2
            GuitarString(id: 1, name: "A", frequency: 110.00, octave: 2),  // A2
            GuitarString(id: 2, name: "D", frequency: 146.83, octave: 3),  // D3
            GuitarString(id: 3, name: "G", frequency: 196.00, octave: 3),  // G3
            GuitarString(id: 4, name: "B", frequency: 246.94, octave: 3),  // B3
            GuitarString(id: 5, name: "E", frequency: 329.63, octave: 4)   // E4
        ]
    )
    
    // MARK: Guitar - Open Tunings
    
    /// Open G tuning (D G D G B D)
    static let guitarOpenG = Tuning(
        id: "guitar_openG",
        name: "Open G",
        instrument: "Guitar",
        strings: [
            GuitarString(id: 0, name: "D", frequency: 73.42, octave: 2),   // D2
            GuitarString(id: 1, name: "G", frequency: 98.00, octave: 2),   // G2
            GuitarString(id: 2, name: "D", frequency: 146.83, octave: 3),  // D3
            GuitarString(id: 3, name: "G", frequency: 196.00, octave: 3),  // G3
            GuitarString(id: 4, name: "B", frequency: 246.94, octave: 3),  // B3
            GuitarString(id: 5, name: "D", frequency: 293.66, octave: 4)   // D4
        ]
    )
    
    /// Open D tuning (D A D F# A D)
    static let guitarOpenD = Tuning(
        id: "guitar_openD",
        name: "Open D",
        instrument: "Guitar",
        strings: [
            GuitarString(id: 0, name: "D", frequency: 73.42, octave: 2),   // D2
            GuitarString(id: 1, name: "A", frequency: 110.00, octave: 2),  // A2
            GuitarString(id: 2, name: "D", frequency: 146.83, octave: 3),  // D3
            GuitarString(id: 3, name: "F#", frequency: 185.00, octave: 3), // F#3
            GuitarString(id: 4, name: "A", frequency: 220.00, octave: 3),  // A3
            GuitarString(id: 5, name: "D", frequency: 293.66, octave: 4)   // D4
        ]
    )
    
    /// Open C tuning (C G C G C E)
    static let guitarOpenC = Tuning(
        id: "guitar_openC",
        name: "Open C",
        instrument: "Guitar",
        strings: [
            GuitarString(id: 0, name: "C", frequency: 65.41, octave: 2),   // C2
            GuitarString(id: 1, name: "G", frequency: 98.00, octave: 2),   // G2
            GuitarString(id: 2, name: "C", frequency: 130.81, octave: 3),  // C3
            GuitarString(id: 3, name: "G", frequency: 196.00, octave: 3),  // G3
            GuitarString(id: 4, name: "C", frequency: 261.63, octave: 4),  // C4
            GuitarString(id: 5, name: "E", frequency: 329.63, octave: 4)   // E4
        ]
    )
    
    /// Open E tuning (E B E G# B E)
    static let guitarOpenE = Tuning(
        id: "guitar_openE",
        name: "Open E",
        instrument: "Guitar",
        strings: [
            GuitarString(id: 0, name: "E", frequency: 82.41, octave: 2),   // E2
            GuitarString(id: 1, name: "B", frequency: 123.47, octave: 2),  // B2
            GuitarString(id: 2, name: "E", frequency: 164.81, octave: 3),  // E3
            GuitarString(id: 3, name: "G#", frequency: 207.65, octave: 3), // G#3
            GuitarString(id: 4, name: "B", frequency: 246.94, octave: 3),  // B3
            GuitarString(id: 5, name: "E", frequency: 329.63, octave: 4)   // E4
        ]
    )
    
    /// Open A tuning (E A E A C# E)
    static let guitarOpenA = Tuning(
        id: "guitar_openA",
        name: "Open A",
        instrument: "Guitar",
        strings: [
            GuitarString(id: 0, name: "E", frequency: 82.41, octave: 2),   // E2
            GuitarString(id: 1, name: "A", frequency: 110.00, octave: 2),  // A2
            GuitarString(id: 2, name: "E", frequency: 164.81, octave: 3),  // E3
            GuitarString(id: 3, name: "A", frequency: 220.00, octave: 3),  // A3
            GuitarString(id: 4, name: "C#", frequency: 277.18, octave: 4), // C#4
            GuitarString(id: 5, name: "E", frequency: 329.63, octave: 4)   // E4
        ]
    )
    
    /// Open B tuning (B F# B F# B D#)
    static let guitarOpenB = Tuning(
        id: "guitar_openB",
        name: "Open B",
        instrument: "Guitar",
        strings: [
            GuitarString(id: 0, name: "B", frequency: 61.74, octave: 1),   // B1
            GuitarString(id: 1, name: "F#", frequency: 92.50, octave: 2),  // F#2
            GuitarString(id: 2, name: "B", frequency: 123.47, octave: 2),  // B2
            GuitarString(id: 3, name: "F#", frequency: 185.00, octave: 3), // F#3
            GuitarString(id: 4, name: "B", frequency: 246.94, octave: 3),  // B3
            GuitarString(id: 5, name: "D#", frequency: 311.13, octave: 4)  // D#4
        ]
    )
    
    // MARK: Guitar - Other Tunings
    
    /// DADGAD tuning (D A D G A D)
    static let guitarDADGAD = Tuning(
        id: "guitar_dadgad",
        name: "DADGAD",
        instrument: "Guitar",
        strings: [
            GuitarString(id: 0, name: "D", frequency: 73.42, octave: 2),   // D2
            GuitarString(id: 1, name: "A", frequency: 110.00, octave: 2),  // A2
            GuitarString(id: 2, name: "D", frequency: 146.83, octave: 3),  // D3
            GuitarString(id: 3, name: "G", frequency: 196.00, octave: 3),  // G3
            GuitarString(id: 4, name: "A", frequency: 220.00, octave: 3),  // A3
            GuitarString(id: 5, name: "D", frequency: 293.66, octave: 4)   // D4
        ]
    )
    
    /// All guitar tunings
    static let guitarTunings: [Tuning] = [
        .guitarStandard,
        .guitarHalfStepDown,
        .guitarWholeStepDown,
        .guitarDropD,
        .guitarOpenG,
        .guitarOpenD,
        .guitarOpenC,
        .guitarOpenE,
        .guitarOpenA,
        .guitarOpenB,
        .guitarDADGAD
    ]
    
    // Legacy aliases for backward compatibility
    static let standard = guitarStandard
    static let halfStepDown = guitarHalfStepDown
    
    /// All tunings across all instruments (for backward compatibility)
    static let allTunings: [Tuning] = guitarTunings
}

// MARK: - ===========================================
// MARK: - BASS TUNINGS
// MARK: - ===========================================

extension Instrument {
    
    static let bass = Instrument(
        id: "bass",
        name: "Bass",
        icon: "guitars.fill",
        stringCount: 4,
        tunings: Tuning.bassTunings
    )
}

extension Tuning {
    
    /// Standard 4-string bass tuning (E A D G)
    static let bassStandard = Tuning(
        id: "bass_standard",
        name: "Standard",
        instrument: "Bass",
        strings: [
            GuitarString(id: 0, name: "E", frequency: 41.20, octave: 1),   // E1
            GuitarString(id: 1, name: "A", frequency: 55.00, octave: 1),   // A1
            GuitarString(id: 2, name: "D", frequency: 73.42, octave: 2),   // D2
            GuitarString(id: 3, name: "G", frequency: 98.00, octave: 2)    // G2
        ]
    )
    
    /// Drop D bass tuning (D A D G)
    static let bassDropD = Tuning(
        id: "bass_dropD",
        name: "Drop D",
        instrument: "Bass",
        strings: [
            GuitarString(id: 0, name: "D", frequency: 36.71, octave: 1),   // D1
            GuitarString(id: 1, name: "A", frequency: 55.00, octave: 1),   // A1
            GuitarString(id: 2, name: "D", frequency: 73.42, octave: 2),   // D2
            GuitarString(id: 3, name: "G", frequency: 98.00, octave: 2)    // G2
        ]
    )
    
    /// All bass tunings
    static let bassTunings: [Tuning] = [
        .bassStandard,
        .bassDropD
    ]
}

// MARK: - ===========================================
// MARK: - UKULELE TUNINGS
// MARK: - ===========================================

extension Instrument {
    
    static let ukulele = Instrument(
        id: "ukulele",
        name: "Ukulele",
        icon: "music.note",
        stringCount: 4,
        tunings: Tuning.ukuleleTunings
    )
}

extension Tuning {
    
    /// Standard ukulele tuning - Soprano/Concert/Tenor (G C E A) - reentrant
    static let ukuleleStandard = Tuning(
        id: "ukulele_standard",
        name: "Standard (gCEA)",
        instrument: "Ukulele",
        strings: [
            GuitarString(id: 0, name: "G", frequency: 392.00, octave: 4),  // G4 (high G, reentrant)
            GuitarString(id: 1, name: "C", frequency: 261.63, octave: 4),  // C4
            GuitarString(id: 2, name: "E", frequency: 329.63, octave: 4),  // E4
            GuitarString(id: 3, name: "A", frequency: 440.00, octave: 4)   // A4
        ]
    )
    
    /// Low G ukulele tuning (G C E A) - linear
    static let ukuleleLowG = Tuning(
        id: "ukulele_lowG",
        name: "Low G (GCEA)",
        instrument: "Ukulele",
        strings: [
            GuitarString(id: 0, name: "G", frequency: 196.00, octave: 3),  // G3 (low G, linear)
            GuitarString(id: 1, name: "C", frequency: 261.63, octave: 4),  // C4
            GuitarString(id: 2, name: "E", frequency: 329.63, octave: 4),  // E4
            GuitarString(id: 3, name: "A", frequency: 440.00, octave: 4)   // A4
        ]
    )
    
    /// Baritone ukulele tuning (D G B E) - same as top 4 guitar strings
    static let ukuleleBaritone = Tuning(
        id: "ukulele_baritone",
        name: "Baritone (DGBE)",
        instrument: "Ukulele",
        strings: [
            GuitarString(id: 0, name: "D", frequency: 146.83, octave: 3),  // D3
            GuitarString(id: 1, name: "G", frequency: 196.00, octave: 3),  // G3
            GuitarString(id: 2, name: "B", frequency: 246.94, octave: 3),  // B3
            GuitarString(id: 3, name: "E", frequency: 329.63, octave: 4)   // E4
        ]
    )
    
    /// All ukulele tunings
    static let ukuleleTunings: [Tuning] = [
        .ukuleleStandard,
        .ukuleleLowG,
        .ukuleleBaritone
    ]
}

// MARK: - ===========================================
// MARK: - BANJO TUNINGS
// MARK: - ===========================================

extension Instrument {
    
    static let banjo = Instrument(
        id: "banjo",
        name: "Banjo",
        icon: "music.mic",
        stringCount: 5,
        tunings: Tuning.banjoTunings
    )
}

extension Tuning {
    
    /// Standard 5-string banjo tuning - Open G (g D G B D)
    static let banjoOpenG = Tuning(
        id: "banjo_openG",
        name: "Open G",
        instrument: "Banjo",
        strings: [
            GuitarString(id: 0, name: "G", frequency: 392.00, octave: 4),  // g4 (5th string, short)
            GuitarString(id: 1, name: "D", frequency: 146.83, octave: 3),  // D3
            GuitarString(id: 2, name: "G", frequency: 196.00, octave: 3),  // G3
            GuitarString(id: 3, name: "B", frequency: 246.94, octave: 3),  // B3
            GuitarString(id: 4, name: "D", frequency: 293.66, octave: 4)   // D4
        ]
    )
    
    /// Double C banjo tuning (g C G C D)
    static let banjoDoubleC = Tuning(
        id: "banjo_doubleC",
        name: "Double C",
        instrument: "Banjo",
        strings: [
            GuitarString(id: 0, name: "G", frequency: 392.00, octave: 4),  // g4
            GuitarString(id: 1, name: "C", frequency: 130.81, octave: 3),  // C3
            GuitarString(id: 2, name: "G", frequency: 196.00, octave: 3),  // G3
            GuitarString(id: 3, name: "C", frequency: 261.63, octave: 4),  // C4
            GuitarString(id: 4, name: "D", frequency: 293.66, octave: 4)   // D4
        ]
    )
    
    /// All banjo tunings
    static let banjoTunings: [Tuning] = [
        .banjoOpenG,
        .banjoDoubleC
    ]
}
