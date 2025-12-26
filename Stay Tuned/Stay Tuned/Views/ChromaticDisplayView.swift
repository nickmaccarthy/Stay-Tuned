//
//  ChromaticDisplayView.swift
//  Stay Tuned
//
//  Created by Nick MacCarthy on 12/25/25.
//

import SwiftUI

/// Large centered display for chromatic tuner mode showing detected note
struct ChromaticDisplayView: View {
    let detectedNote: ChromaticNote?
    let isInTune: Bool
    let sustainedInTune: Bool
    var sizeClass: UserInterfaceSizeClass? // For adaptive sizing

    /// Animation state for note appearance
    @State
    private var noteScale: CGFloat = 1.0

    /// Whether we're on iPad (regular size class)
    private var isRegularWidth: Bool {
        sizeClass == .regular
    }

    // MARK: - Adaptive Font Sizes

    // Keep sizes reasonable on iPad - don't scale up too much

    private var noteFontSize: CGFloat {
        isRegularWidth ? 100 : 120 // Slightly smaller on iPad since it's already constrained
    }

    private var octaveFontSize: CGFloat {
        isRegularWidth ? 40 : 48
    }

    private var frequencyFontSize: CGFloat {
        isRegularWidth ? 22 : 24
    }

    private var targetFontSize: CGFloat {
        isRegularWidth ? 14 : 14
    }

    private var placeholderFontSize: CGFloat {
        isRegularWidth ? 80 : 100
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Main note display
            if let note = detectedNote {
                noteDisplay(note: note)
                    .transition(.scale.combined(with: .opacity))
            } else {
                placeholderDisplay
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: detectedNote?.fullName) { oldValue, newValue in
            // Animate when note changes
            if oldValue != newValue, newValue != nil {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    noteScale = 1.1
                }
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6).delay(0.1)) {
                    noteScale = 1.0
                }
            }
        }
    }

    private func noteDisplay(note: ChromaticNote) -> some View {
        VStack(spacing: 16) {
            // Note name with octave
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(note.name)
                    .font(.system(size: noteFontSize, weight: .bold, design: .rounded))
                    .foregroundColor(noteColor)

                Text("\(note.octave)")
                    .font(.system(size: octaveFontSize, weight: .semibold, design: .rounded))
                    .foregroundColor(noteColor.opacity(0.7))
                    .offset(y: 10)
            }
            .scaleEffect(noteScale)
            .shadow(color: noteColor.opacity(0.4), radius: sustainedInTune ? 20 : 10)

            // Frequency display
            VStack(spacing: 4) {
                Text(String(format: "%.1f Hz", note.frequency))
                    .font(.system(size: frequencyFontSize, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "b8a8d8"))

                // Target frequency
                HStack(spacing: 6) {
                    Text("Target:")
                        .font(.system(size: targetFontSize, weight: .regular))
                        .foregroundColor(Color(hex: "9a8aba"))

                    Text(String(format: "%.1f Hz", note.targetFrequency))
                        .font(.system(size: targetFontSize, weight: .medium, design: .monospaced))
                        .foregroundColor(.green.opacity(0.8))
                }
            }
        }
    }

    private var placeholderDisplay: some View {
        VStack(spacing: 16) {
            Text("--")
                .font(.system(size: placeholderFontSize, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "5a4a7a"))

            Text("Play any note")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(hex: "9a8aba"))
        }
    }

    private var noteColor: Color {
        if sustainedInTune {
            .green
        } else if isInTune {
            Color(hex: "4ECDC4")
        } else {
            .white
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "1a0a2e")
            .ignoresSafeArea()

        VStack(spacing: 40) {
            ChromaticDisplayView(
                detectedNote: ChromaticNote(
                    name: "C#",
                    octave: 4,
                    frequency: 277.18,
                    centsDeviation: -3
                ),
                isInTune: true,
                sustainedInTune: false
            )
            .frame(height: 300)

            ChromaticDisplayView(
                detectedNote: nil,
                isInTune: false,
                sustainedInTune: false
            )
            .frame(height: 200)
        }
    }
}
