//
//  StoreManager.swift
//  Stay Tuned
//
//  Created for StoreKit 2 In-App Purchases
//

import Foundation
import StoreKit
import UIKit
import Combine

/// Represents the current state of a purchase operation
enum PurchaseState: Equatable {
    case idle
    case purchasing
    case success
    case failed(String)
    case cancelled
}

/// Manages StoreKit 2 product fetching and purchasing
@MainActor
final class StoreManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Available products fetched from the App Store
    @Published private(set) var products: [Product] = []
    
    /// Current state of purchase operations
    @Published var purchaseState: PurchaseState = .idle
    
    /// Whether products are currently being loaded
    @Published private(set) var isLoading = false
    
    /// Error message if product loading fails
    @Published private(set) var loadError: String?
    
    // MARK: - Private Properties
    
    private var updateListenerTask: Task<Void, Error>?
    
    // MARK: - Initialization
    
    init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        // Load products on init
        Task {
            await loadProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    /// Fetches products from the App Store
    func loadProducts() async {
        isLoading = true
        loadError = nil
        
        do {
            let storeProducts = try await Product.products(for: TipProduct.allIdentifiers)
            
            // Sort products by price (smallest first)
            products = storeProducts.sorted { $0.price < $1.price }
            
        } catch {
            loadError = "Unable to load products. Please try again later."
            print("Failed to load products: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Purchasing
    
    /// Initiates a purchase for the given product
    /// - Parameter product: The StoreKit Product to purchase
    func purchase(_ product: Product) async {
        purchaseState = .purchasing
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Verify the transaction
                switch verification {
                case .verified(let transaction):
                    // Transaction is valid
                    await transaction.finish()
                    purchaseState = .success
                    triggerSuccessHaptic()
                    
                case .unverified(_, let error):
                    // Transaction failed verification
                    purchaseState = .failed("Purchase could not be verified: \(error.localizedDescription)")
                }
                
            case .userCancelled:
                purchaseState = .cancelled
                
            case .pending:
                // Transaction is pending (e.g., parental approval required)
                purchaseState = .idle
                
            @unknown default:
                purchaseState = .failed("An unknown error occurred.")
            }
            
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }
    
    /// Resets the purchase state to idle
    func resetPurchaseState() {
        purchaseState = .idle
    }
    
    // MARK: - Transaction Listening
    
    /// Listens for transaction updates (handles interrupted purchases, etc.)
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                switch result {
                case .verified(let transaction):
                    // Finish any pending transactions
                    await transaction.finish()
                case .unverified:
                    // Ignore unverified transactions
                    break
                }
            }
        }
    }
    
    // MARK: - Haptic Feedback
    
    /// Triggers a success haptic feedback
    private func triggerSuccessHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // MARK: - Helper Methods
    
    /// Returns the TipProduct enum case for a given StoreKit Product
    func tipProduct(for product: Product) -> TipProduct? {
        TipProduct(rawValue: product.id)
    }
}

