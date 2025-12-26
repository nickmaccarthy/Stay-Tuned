//
//  GuitarString.swift
//  Stay Tuned
//
//  Created by Nick MacCarthy on 12/21/25.
//

import Foundation

/// Represents a single guitar string with its target frequency
struct GuitarString: Identifiable, Hashable {
    let id: Int
    let name: String
    let frequency: Double
    let octave: Int
    
    /// The full note name including octave (e.g., "E2", "A2")
    var fullName: String {
        "\(name)\(octave)"
    }
    
    /// String number for display (1 = high E, 6 = low E in standard notation)
    var stringNumber: Int {
        // Convert from array index to string number
        // In standard tuning: index 0 = low E (string 6), index 5 = high E (string 1)
        6 - id
    }
}


