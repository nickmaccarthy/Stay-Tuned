//
//  LayoutConstants.swift
//  Stay Tuned
//
//  Layout constants for adaptive iPad/iPhone layouts
//

import SwiftUI

/// Layout constants for responsive design across device sizes
struct LayoutConstants {
    // MARK: - Maximum Dimensions
    
    /// Maximum width for main content area (prevents over-stretching on iPad)
    static let maxContentWidth: CGFloat = 500
    
    /// Maximum height for the headstock view on iPad
    static let maxHeadstockHeight: CGFloat = 450
    
    /// Maximum height for chromatic display on iPad
    static let maxChromaticDisplayHeight: CGFloat = 350
    
    // MARK: - Padding
    
    /// Horizontal padding for iPad (regular size class)
    static let iPadHorizontalPadding: CGFloat = 60
    
    /// Standard horizontal padding for iPhone (compact size class)
    static let iPhoneHorizontalPadding: CGFloat = 16
    
    // MARK: - Component Sizes
    
    /// Tuner button size for iPhone
    static let tunerButtonSizeCompact: CGFloat = 46
    
    /// Tuner button size for iPad (slightly larger touch targets)
    static let tunerButtonSizeRegular: CGFloat = 54
    
    // MARK: - Helper Methods
    
    /// Returns appropriate horizontal padding based on size class
    static func horizontalPadding(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .regular ? iPadHorizontalPadding : iPhoneHorizontalPadding
    }
    
    /// Returns appropriate tuner button size based on size class
    static func tunerButtonSize(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .regular ? tunerButtonSizeRegular : tunerButtonSizeCompact
    }
    
    /// Returns whether we're in a regular (iPad) size class
    static func isRegularWidth(_ sizeClass: UserInterfaceSizeClass?) -> Bool {
        sizeClass == .regular
    }
}

