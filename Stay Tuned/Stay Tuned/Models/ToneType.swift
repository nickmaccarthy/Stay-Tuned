//
//  ToneType.swift
//  Stay Tuned
//
//  Defines the available reference tone synthesis types
//

import Foundation

/// The type of waveform used for reference tone playback
enum ToneType: String, CaseIterable, Identifiable {
    case sine = "sine"
    case string = "string"
    
    var id: String { rawValue }
    
    /// Display name for the tone type
    var displayName: String {
        switch self {
        case .sine:
            return "Sine Wave"
        case .string:
            return "Plucked String"
        }
    }
    
    /// Short description of the tone type
    var description: String {
        switch self {
        case .sine:
            return "Pure, clean tone"
        case .string:
            return "Realistic guitar sound"
        }
    }
    
    /// SF Symbol icon for the tone type
    var iconName: String {
        switch self {
        case .sine:
            return "waveform"
        case .string:
            return "guitars"
        }
    }
}

