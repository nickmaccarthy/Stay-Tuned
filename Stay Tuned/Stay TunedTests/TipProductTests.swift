//
//  TipProductTests.swift
//  Stay TunedTests
//
//  Tests for TipProduct enum
//

import Testing
@testable import Stay_Tuned

struct TipProductTests {

    // MARK: - All Cases Tests

    @Test("All tip product cases exist")
    func allCasesExist() {
        let allCases = TipProduct.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.small))
        #expect(allCases.contains(.medium))
        #expect(allCases.contains(.large))
    }

    // MARK: - Product ID Tests

    @Test("Product IDs follow naming convention")
    func productIdsFollowNamingConvention() {
        for product in TipProduct.allCases {
            #expect(product.rawValue.hasPrefix("com.staytuned.tip."))
        }
    }

    @Test("All product IDs are unique")
    func productIdsAreUnique() {
        let identifiers = TipProduct.allIdentifiers
        let uniqueIdentifiers = Set(identifiers)
        #expect(identifiers.count == uniqueIdentifiers.count)
    }

    @Test("Small tip product ID is correct")
    func smallProductId() {
        #expect(TipProduct.small.rawValue == "com.staytuned.tip.coffee")
    }

    @Test("Medium tip product ID is correct")
    func mediumProductId() {
        #expect(TipProduct.medium.rawValue == "com.staytuned.tip.strings")
    }

    @Test("Large tip product ID is correct")
    func largeProductId() {
        #expect(TipProduct.large.rawValue == "com.staytuned.tip.guitar_strap")
    }

    // MARK: - Display Name Tests

    @Test("Display names are not empty")
    func displayNamesNotEmpty() {
        for product in TipProduct.allCases {
            #expect(!product.displayName.isEmpty)
        }
    }

    @Test("Small tip display name is Coffee")
    func smallDisplayName() {
        #expect(TipProduct.small.displayName == "Coffee")
    }

    @Test("Medium tip display name is New Strings")
    func mediumDisplayName() {
        #expect(TipProduct.medium.displayName == "New Strings")
    }

    @Test("Large tip display name is Guitar Strap")
    func largeDisplayName() {
        #expect(TipProduct.large.displayName == "Guitar Strap")
    }

    // MARK: - Emoji Tests

    @Test("All tips have emojis")
    func allTipsHaveEmojis() {
        for product in TipProduct.allCases {
            #expect(!product.emoji.isEmpty)
        }
    }

    @Test("Small tip emoji is coffee")
    func smallEmoji() {
        #expect(TipProduct.small.emoji == "☕️")
    }

    @Test("Medium tip emoji is guitar")
    func mediumEmoji() {
        #expect(TipProduct.medium.emoji == "🎸")
    }

    @Test("Large tip emoji is music note")
    func largeEmoji() {
        #expect(TipProduct.large.emoji == "🎵")
    }

    // MARK: - All Identifiers Tests

    @Test("allIdentifiers returns array of raw values")
    func allIdentifiersReturnsRawValues() {
        let identifiers = TipProduct.allIdentifiers

        for product in TipProduct.allCases {
            #expect(identifiers.contains(product.rawValue))
        }
    }

    @Test("allIdentifiers has same count as allCases")
    func allIdentifiersSameCountAsAllCases() {
        #expect(TipProduct.allIdentifiers.count == TipProduct.allCases.count)
    }
}
