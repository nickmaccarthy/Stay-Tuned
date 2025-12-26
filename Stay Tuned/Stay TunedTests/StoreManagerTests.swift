//
//  StoreManagerTests.swift
//  Stay TunedTests
//
//  Tests for StoreManager state and behavior
//

import Testing
@testable import Stay_Tuned

@MainActor
struct StoreManagerTests {

    // MARK: - Initialization Tests

    @Test("Initial products array is empty")
    func initialProductsEmpty() {
        let manager = StoreManager()
        #expect(manager.products.isEmpty)
    }

    @Test("Initial purchase state is idle")
    func initialPurchaseStateIdle() {
        let manager = StoreManager()
        #expect(manager.purchaseState == .idle)
    }

    @Test("Initial load error is nil")
    func initialLoadErrorNil() {
        let manager = StoreManager()
        #expect(manager.loadError == nil)
    }

    // MARK: - Purchase State Tests

    @Test("Purchase state enum has all expected cases")
    func purchaseStateHasAllCases() {
        // Verify we can create all cases
        let idle: PurchaseState = .idle
        let purchasing: PurchaseState = .purchasing
        let success: PurchaseState = .success
        let failed: PurchaseState = .failed("Error")
        let cancelled: PurchaseState = .cancelled

        // Verify equality
        #expect(idle == .idle)
        #expect(purchasing == .purchasing)
        #expect(success == .success)
        #expect(cancelled == .cancelled)

        // Verify failed with same message is equal
        #expect(failed == .failed("Error"))

        // Verify failed with different messages are not equal
        #expect(failed != .failed("Different"))
    }

    @Test("Reset purchase state sets to idle")
    func resetPurchaseStateSetsIdle() {
        let manager = StoreManager()
        // Note: We can't easily set other states without actual purchases,
        // but we can verify reset works on already-idle state
        manager.resetPurchaseState()
        #expect(manager.purchaseState == .idle)
    }

    // MARK: - Product ID Validation Tests

    @Test("TipProduct allIdentifiers returns correct IDs")
    func tipProductIdentifiersCorrect() {
        let identifiers = TipProduct.allIdentifiers

        #expect(identifiers.count == 3)
        #expect(identifiers.contains("com.staytuned.tip.small"))
        #expect(identifiers.contains("com.staytuned.tip.medium"))
        #expect(identifiers.contains("com.staytuned.tip.large"))
    }

    // MARK: - Tip Product Lookup Tests

    @Test("tipProduct returns nil for unknown product ID")
    func tipProductReturnsNilForUnknown() {
        // Note: We can't easily create a mock Product, but we can verify
        // TipProduct initializer works correctly
        #expect(TipProduct(rawValue: "com.unknown.product") == nil)
        #expect(TipProduct(rawValue: "") == nil)
    }

    @Test("tipProduct raw value matches product ID")
    func tipProductRawValueMatchesId() {
        #expect(TipProduct.small.rawValue == "com.staytuned.tip.small")
        #expect(TipProduct.medium.rawValue == "com.staytuned.tip.medium")
        #expect(TipProduct.large.rawValue == "com.staytuned.tip.large")
    }
}
