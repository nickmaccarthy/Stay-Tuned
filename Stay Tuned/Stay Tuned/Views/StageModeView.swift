//
//  StageModeView.swift
//  Stay Tuned
//
//  Created for Stage Mode feature.
//

import SwiftUI

struct StageModeView: View {
    @ObservedObject
    var viewModel: TunerViewModel
    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // High contrast background
                Color.black.ignoresSafeArea()

                // Calculate size based on available space
                let isLandscape = geometry.size.width > geometry.size.height
                let minDimension = min(geometry.size.width, geometry.size.height)
                // Use slightly smaller circle in landscape to leave room for overlays
                let circleSize = isLandscape ? minDimension * 0.7 : 300
                let fontSizeScale = isLandscape ? circleSize / 300 : 1.0

                // MAIN TUNER DISPLAY (Centered)
                ZStack {
                    // Background Circle
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                        .frame(width: circleSize, height: circleSize)

                    if viewModel.isInTune {
                        Circle()
                            .stroke(Color.green, lineWidth: 20 * fontSizeScale)
                            .frame(width: circleSize, height: circleSize)
                            .shadow(color: .green, radius: 30 * fontSizeScale)
                    }

                    VStack(spacing: 16 * fontSizeScale) {
                        if let note = viewModel.detectedNote {
                            // split name (e.g. "C#") into "C" and "#"
                            let noteName = String(note.name.prefix(1))
                            let accidental = note.name.count > 1 ? String(note.name.suffix(1)) : ""

                            HStack(alignment: .lastTextBaseline, spacing: 0) {
                                Text(noteName)
                                    .font(.system(size: 140 * fontSizeScale, weight: .black, design: .monospaced))
                                    .foregroundStyle(viewModel.isInTune ? .green : .white)

                                Text(accidental)
                                    .font(.system(size: 80 * fontSizeScale, weight: .bold))
                                    .foregroundStyle(viewModel.isInTune ? .green : .white)
                            }
                        } else if let string = viewModel.selectedString {
                            // Show target note if nothing detected
                            Text(string.name)
                                .font(.system(size: 100 * fontSizeScale, weight: .medium))
                                .foregroundStyle(.gray)
                            Text("TARGET")
                                .font(.system(size: 20 * fontSizeScale, weight: .bold))
                                .foregroundStyle(.gray)
                        } else {
                            Image(systemName: "music.note")
                                .font(.system(size: 100 * fontSizeScale))
                                .foregroundStyle(.gray)
                        }

                        // Cents deviation
                        if viewModel.isDetectingPitch {
                            Text("\(viewModel.centsDeviation > 0 ? "+" : "")\(viewModel.centsDeviation)")
                                .font(.system(size: 50 * fontSizeScale, weight: .bold))
                                .foregroundStyle(colorForCents(viewModel.centsDeviation))
                                .monospacedDigit()
                        }
                    }
                }

                // HEADER OVERLAY (Top Left / Top Center)
                VStack {
                    HStack {
                        if !isLandscape {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.gray)
                            }
                        } else {
                            // Empty placeholder to maintain spacing alignment if needed,
                            // though Spacer() handles it largely.
                            // But better to simply hide it to prevent interaction.
                        }
                        Spacer()
                        if !isLandscape {
                            Text("STAGE MODE")
                                .font(.headline)
                                .foregroundStyle(.gray)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(RoundedRectangle(cornerRadius: 8).stroke(.gray, lineWidth: 1))
                        }
                        Spacer()
                        if !isLandscape {
                            // Balance the X button layout in portrait
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.clear)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.horizontal)
                    Spacer()
                }

                // FOOTER OVERLAY (Bottom Center)
                VStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Text(viewModel.selectedTuning.name.uppercased())
                            .font(.system(size: isLandscape ? 16 : 22, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 24)
                            .padding(.vertical, isLandscape ? 8 : 12)
                            .background(Color.green)
                            .clipShape(Capsule())

                        if let selectedString = viewModel.selectedString {
                            Text("String: \(selectedString.name)")
                                .font(isLandscape ? .caption : .title3)
                                .foregroundStyle(.gray)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private func colorForCents(_ cents: Int) -> Color {
        if abs(cents) <= 7 { return .green }
        if abs(cents) <= 20 { return .yellow }
        return .red
    }
}
