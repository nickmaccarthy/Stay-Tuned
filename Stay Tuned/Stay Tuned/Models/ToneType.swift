//
//  ToneType.swift
//  Stay Tuned
//
//  Defines the available reference tone synthesis types
//

import Foundation

/// The type of waveform used for reference tone playback
enum ToneType: String, CaseIterable, Identifiable {
    case sine
    case string

    var id: String { rawValue }

    /// Display name for the tone type
    var displayName: String {
        switch self {
        case .sine:
            "Sine Wave"
        case .string:
            "Plucked String"
        }
    }

    /// Short description of the tone type
    var description: String {
        switch self {
        case .sine:
            "Pure, clean tone"
        case .string:
            "Realistic guitar sound"
        }
    }

    /// SF Symbol icon for the tone type
    var iconName: String {
        switch self {
        case .sine:
            "waveform"
        case .string:
            "guitars"
        }
    }
}
