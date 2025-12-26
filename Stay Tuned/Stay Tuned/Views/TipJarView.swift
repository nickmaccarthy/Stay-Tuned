//
//  TipJarView.swift
//  Stay Tuned
//
//  Created by Nick MacCarthy on 12/21/25.
//

import StoreKit
import SwiftUI

struct TipJarView: View {
    @Environment(\.dismiss)
    private var dismiss
    @StateObject
    private var storeManager = StoreManager()

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(hex: "1a0a2e"),
                    Color(hex: "2d1b4e"),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header with mascot
                VStack(spacing: 8) {
                    Image("InAppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)

                    Text("Support Stay Tuned")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Text("If you enjoy this app, consider leaving a tip to support development!")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "9a8aba"))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 12)

                // Tip options
                VStack(spacing: 12) {
                    if storeManager.isLoading {
                        loadingView
                    } else if let error = storeManager.loadError {
                        errorView(message: error)
                    } else if storeManager.products.isEmpty {
                        emptyProductsView
                    } else {
                        ForEach(storeManager.products, id: \.id) { product in
                            tipButton(for: product)
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                // Thank you note
                Text("Thank you for your support! 🎸")
                    .font(.footnote)
                    .foregroundColor(Color(hex: "9a8aba").opacity(0.8))
                    .padding(.bottom, 20)
            }

            // Success overlay
            if storeManager.purchaseState == .success {
                successOverlay
            }
        }
        .onChange(of: storeManager.purchaseState) { _, newState in
            if newState == .success {
                // Auto-dismiss success after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    storeManager.resetPurchaseState()
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "9a8aba")))
                .scaleEffect(1.2)

            Text("Loading tips...")
                .font(.subheadline)
                .foregroundColor(Color(hex: "9a8aba"))
        }
        .frame(height: 150)
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(.orange)

            Text(message)
                .font(.subheadline)
                .foregroundColor(Color(hex: "9a8aba"))
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await storeManager.loadProducts()
                }
            } label: {
                Text("Try Again")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "6b5b95"))
                    )
            }
        }
        .frame(height: 150)
    }

    // MARK: - Empty Products View

    private var emptyProductsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bag.fill")
                .font(.system(size: 32))
                .foregroundColor(Color(hex: "9a8aba"))

            Text("No tips available at the moment.")
                .font(.subheadline)
                .foregroundColor(Color(hex: "9a8aba"))
                .multilineTextAlignment(.center)
        }
        .frame(height: 150)
    }

    // MARK: - Tip Button

    private func tipButton(for product: Product) -> some View {
        let tipProduct = storeManager.tipProduct(for: product)
        let isPurchasing = storeManager.purchaseState == .purchasing

        return Button {
            Task {
                await storeManager.purchase(product)
            }
        } label: {
            HStack(spacing: 14) {
                Text(tipProduct?.emoji ?? "💝")
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 2) {
                    Text(tipProduct?.displayName ?? product.displayName)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(product.displayPrice)
                        .font(.caption)
                        .foregroundColor(Color(hex: "9a8aba"))
                }

                Spacer()

                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "9a8aba")))
                } else {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "e74c3c"))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.08))
                    .stroke(Color(hex: "6b5b95").opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing)
        .opacity(isPurchasing ? 0.6 : 1.0)
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)

                Text("Thank You!")
                    .font(.title.bold())
                    .foregroundColor(.white)

                Text("Your support means the world to us!")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "9a8aba"))
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "2d1b4e"))
                    .stroke(Color.green.opacity(0.5), lineWidth: 2)
            )
        }
        .transition(.opacity)
        .animation(.easeInOut, value: storeManager.purchaseState)
    }
}

#Preview {
    TipJarView()
}
