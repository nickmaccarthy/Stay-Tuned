//
//  LayoutConstantsTests.swift
//  Stay TunedTests
//
//  Tests for layout constants and adaptive sizing
//

import SwiftUI
import Testing
@testable import Stay_Tuned

// MARK: - Layout Constants Tests

struct LayoutConstantsTests {
    
    @Test("Max content width is reasonable for iPad")
    func testMaxContentWidth() {
        #expect(LayoutConstants.maxContentWidth == 500)
        #expect(LayoutConstants.maxContentWidth > 300, "Content width should be > 300")
        #expect(LayoutConstants.maxContentWidth < 700, "Content width should be < 700")
    }
    
    @Test("Max headstock height prevents oversized display")
    func testMaxHeadstockHeight() {
        #expect(LayoutConstants.maxHeadstockHeight == 450)
        #expect(LayoutConstants.maxHeadstockHeight > 300, "Headstock should be visible")
        #expect(LayoutConstants.maxHeadstockHeight < 600, "Headstock shouldn't be too large")
    }
    
    @Test("Max chromatic display height is set")
    func testMaxChromaticDisplayHeight() {
        #expect(LayoutConstants.maxChromaticDisplayHeight == 350)
    }
    
    @Test("iPad padding is larger than iPhone padding")
    func testPaddingValues() {
        #expect(LayoutConstants.iPadHorizontalPadding == 60)
        #expect(LayoutConstants.iPhoneHorizontalPadding == 16)
        #expect(LayoutConstants.iPadHorizontalPadding > LayoutConstants.iPhoneHorizontalPadding,
               "iPad should have more padding than iPhone")
    }
    
    @Test("Tuner button sizes are appropriate for each device")
    func testTunerButtonSizes() {
        #expect(LayoutConstants.tunerButtonSizeCompact == 46)
        #expect(LayoutConstants.tunerButtonSizeRegular == 54)
        #expect(LayoutConstants.tunerButtonSizeRegular > LayoutConstants.tunerButtonSizeCompact,
               "iPad buttons should be larger")
    }
    
    @Test("Horizontal padding helper returns correct values")
    func testHorizontalPaddingHelper() {
        // Regular size class (iPad)
        let iPadPadding = LayoutConstants.horizontalPadding(for: .regular)
        #expect(iPadPadding == LayoutConstants.iPadHorizontalPadding)
        
        // Compact size class (iPhone)
        let iPhonePadding = LayoutConstants.horizontalPadding(for: .compact)
        #expect(iPhonePadding == LayoutConstants.iPhoneHorizontalPadding)
        
        // Nil size class defaults to iPhone
        let nilPadding = LayoutConstants.horizontalPadding(for: nil)
        #expect(nilPadding == LayoutConstants.iPhoneHorizontalPadding)
    }
    
    @Test("Tuner button size helper returns correct values")
    func testTunerButtonSizeHelper() {
        // Regular size class (iPad)
        let iPadSize = LayoutConstants.tunerButtonSize(for: .regular)
        #expect(iPadSize == LayoutConstants.tunerButtonSizeRegular)
        
        // Compact size class (iPhone)
        let iPhoneSize = LayoutConstants.tunerButtonSize(for: .compact)
        #expect(iPhoneSize == LayoutConstants.tunerButtonSizeCompact)
        
        // Nil size class defaults to iPhone
        let nilSize = LayoutConstants.tunerButtonSize(for: nil)
        #expect(nilSize == LayoutConstants.tunerButtonSizeCompact)
    }
}


