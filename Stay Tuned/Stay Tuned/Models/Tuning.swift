//
//  Tuning.swift
//  Stay Tuned
//
//  Created by Nick MacCarthy on 12/21/25.
//

import Foundation

/// Represents a tuning configuration for a stringed instrument
struct Tuning: Identifiable, Hashable {
    let id: String
    let name: String
    let instrument: String // e.g., "Guitar", "Bass", "Ukulele"
    let strings: [GuitarString]

    /// Find the closest string to a given frequency
    func closestString(to frequency: Double) -> GuitarString? {
        guard !strings.isEmpty else { return nil }

        return strings.min(by: { string1, string2 in
            abs(centsDeviation(from: frequency, to: string1.frequency)) <
                abs(centsDeviation(from: frequency, to: string2.frequency))
        })
    }

    /// Calculate cents deviation between two frequencies
    private func centsDeviation(from detected: Double, to target: Double) -> Double {
        guard detected > 0, target > 0 else { return 0 }
        return 1200 * log2(detected / target)
    }
}
