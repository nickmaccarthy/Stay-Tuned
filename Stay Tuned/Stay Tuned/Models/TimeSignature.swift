//
//  TimeSignature.swift
//  Stay Tuned
//
//  Created for Phase 6: Metronome
//

import Foundation

/// Represents common time signatures for the metronome
enum TimeSignature: String, CaseIterable, Identifiable {
    case fourFour = "4/4"
    case threeFour = "3/4"
    case sixEight = "6/8"
    case twoFour = "2/4"
    
    var id: String { rawValue }
    
    /// Number of beats per measure
    var beatsPerMeasure: Int {
        switch self {
        case .fourFour: return 4
        case .threeFour: return 3
        case .sixEight: return 6
        case .twoFour: return 2
        }
    }
    
    /// Display name for UI
    var displayName: String {
        rawValue
    }
}

