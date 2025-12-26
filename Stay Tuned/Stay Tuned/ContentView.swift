//
//  ContentView.swift
//  Stay Tuned
//
//  Created by Nick MacCarthy on 12/21/25.
//

import SwiftUI

struct ContentView: View {
    @State
    private var showSplash = true

    var body: some View {
        ZStack {
            // Main tuner view (loads in background while splash is visible)
            TunerView()

            // Splash screen overlay
            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            // Wait 1.5 seconds, then fade out splash
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.6)) {
                    showSplash = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
