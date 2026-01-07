//
//  TimeSignature.swift
//  Stay Tuned
//
//  Created for Phase 6: Metronome
//

import Foundation

/// Represents a beat grouping pattern for a time signature
struct BeatGrouping: Hashable, Identifiable, Sendable {
    /// The groups that make up the beat pattern (e.g., [3, 2] for 3+2)
    let groups: [Int]

    /// Display name showing the grouping pattern (e.g., "3+2")
    var displayName: String {
        groups.map(String.init).joined(separator: "+")
    }

    var id: String { displayName }

    /// Which beats should be accented (1-indexed)
    /// For [3, 2], this would be [1, 4] (beat 1 and beat 4)
    var accentPositions: [Int] {
        var positions: [Int] = []
        var currentPosition = 1
        for group in groups {
            positions.append(currentPosition)
            currentPosition += group
        }
        return positions
    }

    /// Total number of beats in this grouping
    var totalBeats: Int {
        groups.reduce(0, +)
    }
}

/// Represents common time signatures for the metronome
enum TimeSignature: String, CaseIterable, Identifiable {
    case fourFour = "4/4"
    case threeFour = "3/4"
    case twoFour = "2/4"
    case sixEight = "6/8"
    case fiveFour = "5/4"
    case sevenFour = "7/4"
    case fiveEight = "5/8"
    case sevenEight = "7/8"
    case nineEight = "9/8"
    case twelveEight = "12/8"

    var id: String { rawValue }

    /// Number of beats per measure
    var beatsPerMeasure: Int {
        switch self {
        case .fourFour: 4
        case .threeFour: 3
        case .twoFour: 2
        case .sixEight: 6
        case .fiveFour: 5
        case .sevenFour: 7
        case .fiveEight: 5
        case .sevenEight: 7
        case .nineEight: 9
        case .twelveEight: 12
        }
    }

    /// Display name for UI
    var displayName: String {
        rawValue
    }

    /// Available beat groupings for this time signature
    var availableGroupings: [BeatGrouping] {
        switch self {
        case .fourFour:
            [BeatGrouping(groups: [4])]
        case .threeFour:
            [BeatGrouping(groups: [3])]
        case .twoFour:
            [BeatGrouping(groups: [2])]
        case .sixEight:
            [BeatGrouping(groups: [3, 3])]
        case .fiveFour, .fiveEight:
            [
                BeatGrouping(groups: [3, 2]),
                BeatGrouping(groups: [2, 3]),
            ]
        case .sevenFour, .sevenEight:
            [
                BeatGrouping(groups: [4, 3]),
                BeatGrouping(groups: [3, 4]),
                BeatGrouping(groups: [2, 2, 3]),
            ]
        case .nineEight:
            [BeatGrouping(groups: [3, 3, 3])]
        case .twelveEight:
            [BeatGrouping(groups: [3, 3, 3, 3])]
        }
    }

    /// The default grouping for this time signature
    var defaultGrouping: BeatGrouping {
        availableGroupings[0]
    }

    /// Whether this time signature has multiple grouping options
    var hasMultipleGroupings: Bool {
        availableGroupings.count > 1
    }
}
