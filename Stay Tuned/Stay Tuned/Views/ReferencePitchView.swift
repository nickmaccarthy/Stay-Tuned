//
//  ReferencePitchView.swift
//  Stay Tuned
//
//  Created by Nick MacCarthy on 12/25/25.
//

import SwiftUI

/// View for adjusting the reference pitch setting
struct ReferencePitchView: View {
    @Binding var referencePitch: Int
    
    private let minPitch = 432
    private let maxPitch = 444
    
    var body: some View {
        ZStack {
            // Background gradient matching app theme
            LinearGradient(
                colors: [
                    Color(hex: "1a0a2e"),
                    Color(hex: "2d1b4e"),
                    Color(hex: "1a0a2e")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Current pitch display
                    VStack(spacing: 4) {
                        Text("A = \(referencePitch) Hz")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        if referencePitch != 440 {
                            Text(pitchDescription)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "9a8aba"))
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 8)
                    
                    // Slider section
                    VStack(spacing: 12) {
                        Slider(
                            value: Binding(
                                get: { Double(referencePitch) },
                                set: { referencePitch = Int($0.rounded()) }
                            ),
                            in: Double(minPitch)...Double(maxPitch),
                            step: 1
                        )
                        .tint(Color(hex: "4ECDC4"))
                        
                        // Slider labels
                        HStack {
                            Text("\(minPitch) Hz")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(Color(hex: "7c6c9a"))
                            
                            Spacer()
                            
                            Text("\(maxPitch) Hz")
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(Color(hex: "7c6c9a"))
                        }
                    }
                    .padding(.horizontal, 4)
                    
                    // Preset buttons
                    HStack(spacing: 12) {
                        presetButton(pitch: 432, label: "432")
                        presetButton(pitch: 440, label: "440")
                        presetButton(pitch: 442, label: "442")
                    }
                    
                    // Explanation blurb
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What is reference pitch?")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "9a8aba"))
                        
                        Text("The reference pitch sets the frequency of the A4 note. All other notes are calculated relative to this frequency.\n\nStandard tuning uses A=440Hz. Orchestras often tune slightly higher (441-443Hz) for a brighter sound, while some musicians prefer A=432Hz for a warmer, more relaxed tone.")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "7c6c9a"))
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
                    .padding(.top, 8)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationTitle("Reference Pitch")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(hex: "1a0a2e"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    private func presetButton(pitch: Int, label: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                referencePitch = pitch
            }
        } label: {
            Text(label)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(referencePitch == pitch ? Color(hex: "1a0a2e") : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(referencePitch == pitch ? Color(hex: "4ECDC4") : Color.white.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
    
    private var pitchDescription: String {
        if referencePitch < 440 {
            return "Lower than standard"
        } else if referencePitch > 440 {
            return "Orchestral tuning"
        }
        return ""
    }
}

#Preview {
    NavigationStack {
        ReferencePitchView(referencePitch: .constant(440))
    }
}


