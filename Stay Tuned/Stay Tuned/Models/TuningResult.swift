//
//  TuningResult.swift
//  Stay Tuned
//
//  Created by Nick MacCarthy on 12/21/25.
//

import Foundation

/// Represents the result of pitch detection
struct TuningResult {
    let detectedFrequency: Double
    let closestString: GuitarString?
    let centsDeviation: Int
    
    /// Whether the tuning is considered "in tune" (within +/- 5 cents)
    var isInTune: Bool {
        abs(centsDeviation) <= 5
    }
    
    /// Whether the note is sharp (too high)
    var isSharp: Bool {
        centsDeviation > 0
    }
    
    /// Whether the note is flat (too low)
    var isFlat: Bool {
        centsDeviation < 0
    }
    
    /// Empty result when no pitch is detected
    static let empty = TuningResult(
        detectedFrequency: 0,
        closestString: nil,
        centsDeviation: 0
    )
    
    /// Calculate cents deviation between detected frequency and target
    static func calculateCents(detected: Double, target: Double) -> Int {
        guard detected > 0 && target > 0 else { return 0 }
        let cents = 1200 * log2(detected / target)
        return Int(cents.rounded())
    }
}


