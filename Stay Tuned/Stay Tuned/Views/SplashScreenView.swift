//
//  SplashScreenView.swift
//  Stay Tuned
//
//  Created for branded splash screen launch animation
//

import SwiftUI

/// Splash screen displayed on app launch before fading into main tuner view
struct SplashScreenView: View {

    @State
    private var logoScale: CGFloat = 0.8
    @State
    private var logoOpacity: Double = 0

    var body: some View {
        ZStack {
            // Purple gradient background (matches TunerView)
            LinearGradient(
                colors: [
                    Color(hex: "1a0a2e"),
                    Color(hex: "2d1b4e"),
                    Color(hex: "1a0a2e"),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Centered logo with subtle scale animation
            Image("InAppLogo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 200, maxHeight: 200)
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
        }
        .onAppear {
            // Subtle entrance animation for polish
            withAnimation(.easeOut(duration: 0.5)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
