//
//  TipProduct.swift
//  Stay Tuned
//
//  Created for StoreKit 2 In-App Purchases
//

import Foundation

/// Defines the consumable tip products available for purchase
enum TipProduct: String, CaseIterable {
    case small = "com.staytuned.tip.coffee"
    case medium = "com.staytuned.tip.strings"
    case large = "com.staytuned.tip.guitar_strap"
    
    /// User-friendly display name for the tip
    var displayName: String {
        switch self {
        case .small: return "Coffee"
        case .medium: return "New Strings"
        case .large: return "Guitar Strap"
        }
    }
    
    /// Emoji icon for the tip tier
    var emoji: String {
        switch self {
        case .small: return "☕️"
        case .medium: return "🎸"
        case .large: return "🎵"
        }
    }
    
    /// All product identifiers as an array of strings
    static var allIdentifiers: [String] {
        allCases.map { $0.rawValue }
    }
}

