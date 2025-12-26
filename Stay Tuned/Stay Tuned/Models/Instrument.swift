//
//  Instrument.swift
//  Stay Tuned
//
//  Represents a musical instrument with its available tunings.
//

import Foundation

/// Represents a type of stringed instrument
struct Instrument: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String  // SF Symbol name
    let stringCount: Int
    let tunings: [Tuning]
    
    /// Default tuning for this instrument
    var defaultTuning: Tuning {
        tunings.first ?? Tuning(id: "unknown", name: "Unknown", instrument: name, strings: [])
    }
}

// MARK: - All Supported Instruments

extension Instrument {
    
    /// All available instruments
    static let allInstruments: [Instrument] = [
        .guitar,
        .bass,
        .ukulele,
        .banjo
    ]
    
    /// Find instrument by ID
    static func find(by id: String) -> Instrument? {
        allInstruments.first { $0.id == id }
    }
}


