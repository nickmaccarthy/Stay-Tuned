//
//  TunerView.swift
//  Stay Tuned
//
//  Created by Nick MacCarthy on 12/21/25.
//

import SwiftUI

/// Main tuner view assembling all components
struct TunerView: View {
    @StateObject
    private var viewModel = TunerViewModel()
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
    @Environment(\.verticalSizeClass)
    private var verticalSizeClass

    /// Whether we're on iPad (regular width)
    private var isRegularWidth: Bool {
        horizontalSizeClass == .regular
    }

    /// Whether we're in landscape on iPad
    private var isIPadLandscape: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .compact
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                backgroundGradient

                // Spectrum analyzer at the bottom
                VStack {
                    Spacer()
                    SpectrumAnalyzerView(
                        samples: viewModel.audioSamples,
                        sampleRate: viewModel.audioSampleRate,
                        isListening: viewModel.isListening,
                        detectedFrequency: viewModel.isDetectingPitch ? viewModel.detectedFrequency : nil
                    )
                    .frame(height: geometry.size.height * 0.35)
                    .mask(
                        LinearGradient(
                            colors: [.clear, .white, .white],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .ignoresSafeArea()

                // Main content - use landscape or portrait layout
                if isIPadLandscape {
                    // iPad landscape: side-by-side layout
                    iPadLandscapeContent(geometry: geometry)
                } else {
                    // Portrait layout (iPhone or iPad)
                    portraitContent(geometry: geometry)
                        .frame(maxWidth: isRegularWidth ? LayoutConstants.maxContentWidth : nil)
                }

                // All strings tuned quick flash celebration
                if viewModel.showAllTunedFlash {
                    allTunedFlashOverlay
                }

                // Permission overlay if needed
                if !viewModel.hasPermission {
                    permissionOverlay
                }

            }
        }
        .onAppear {
            viewModel.startListening()
        }
        .onDisappear {
            viewModel.stopTone()
            viewModel.stopListening()
        }
    }

    private var backgroundGradient: some View {
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
    }

    // MARK: - Portrait Layout (iPhone + iPad Portrait)

    @ViewBuilder
    private func portraitContent(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Header with tuning picker
            headerSection
                .padding(.top, 8)

            Spacer()
                .frame(height: isRegularWidth ? 40 : 30)

            // Tuning meter with reference tone overlay
            TuningMeterView(
                centsDeviation: viewModel.centsDeviation,
                isInTune: viewModel.isInTune,
                selectedString: viewModel.isChromatic ? nil : viewModel.selectedString,
                showConfirmation: viewModel.showTuneConfirmation,
                sustainedInTune: viewModel.sustainedInTune,
                detectedFrequency: viewModel.detectedFrequency,
                targetFrequency: viewModel.isChromatic
                    ? (viewModel.detectedNote?.targetFrequency ?? 0)
                    : viewModel.adjustedFrequency(for: viewModel.selectedString?.frequency ?? 0),
                currentDecibels: viewModel.currentDecibels,
                chromaticNote: viewModel.detectedNote
            )
            .padding(.horizontal, 20)
            .overlay(alignment: .bottom) {
                // Reference tone indicator - overlaid to avoid layout shifts
                if viewModel.isPlayingTone {
                    HStack(spacing: 6) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "4ECDC4"))
                        Text("Reference Tone")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: "9a8aba"))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color(hex: "1a0a2e").opacity(0.9))
                            .overlay(
                                Capsule()
                                    .stroke(Color(hex: "4ECDC4").opacity(0.3), lineWidth: 1)
                            )
                    )
                    .offset(y: 30)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isPlayingTone)
                }
            }

            Spacer()
                .frame(height: isRegularWidth ? 50 : 40)

            // Show either headstock (instrument mode) or chromatic display
            if viewModel.isChromatic {
                ChromaticDisplayView(
                    detectedNote: viewModel.detectedNote,
                    isInTune: viewModel.isInTune,
                    sustainedInTune: viewModel.sustainedInTune,
                    sizeClass: horizontalSizeClass
                )
                .frame(maxHeight: min(
                    geometry.size.height * 0.40,
                    isRegularWidth ? LayoutConstants.maxChromaticDisplayHeight : .infinity
                ))
                .padding(.horizontal, 32)
            } else {
                // Headstock - show green for confirmed strings (sustained in-tune for 2s)
                // Single tap selects string, double tap plays/stops reference tone
                HeadstockView(
                    tuning: viewModel.selectedTuning,
                    selectedString: viewModel.selectedString,
                    isInTune: viewModel.sustainedInTune,
                    tunedStrings: viewModel.confirmedStrings,
                    onStringSelected: { string in
                        viewModel.selectString(string)
                    },
                    playingToneStringId: viewModel.playingToneStringId,
                    onDoubleTap: { string in
                        viewModel.toggleToneForString(string)
                    },
                    sizeClass: horizontalSizeClass
                )
                .frame(maxHeight: min(
                    geometry.size.height * 0.60,
                    isRegularWidth ? LayoutConstants.maxHeadstockHeight : .infinity
                ))
                .padding(.horizontal, 32)
            }

            Spacer()

            // Tip Jar
            tipJarSection
                .padding(.bottom, 8)
        }
        .padding(.horizontal, LayoutConstants.horizontalPadding(for: horizontalSizeClass))
    }

    // MARK: - iPad Landscape Layout

    @ViewBuilder
    private func iPadLandscapeContent(geometry: GeometryProxy) -> some View {
        HStack(spacing: 40) {
            // Left side: Headstock or Chromatic display
            VStack {
                if viewModel.isChromatic {
                    ChromaticDisplayView(
                        detectedNote: viewModel.detectedNote,
                        isInTune: viewModel.isInTune,
                        sustainedInTune: viewModel.sustainedInTune,
                        sizeClass: horizontalSizeClass
                    )
                    .frame(maxHeight: LayoutConstants.maxChromaticDisplayHeight)
                } else {
                    HeadstockView(
                        tuning: viewModel.selectedTuning,
                        selectedString: viewModel.selectedString,
                        isInTune: viewModel.sustainedInTune,
                        tunedStrings: viewModel.confirmedStrings,
                        onStringSelected: { string in
                            viewModel.selectString(string)
                        },
                        playingToneStringId: viewModel.playingToneStringId,
                        onDoubleTap: { string in
                            viewModel.toggleToneForString(string)
                        },
                        sizeClass: horizontalSizeClass
                    )
                    .frame(maxHeight: LayoutConstants.maxHeadstockHeight)
                }
            }
            .frame(maxWidth: geometry.size.width * 0.4)

            // Right side: Header + Meter
            VStack(spacing: 0) {
                headerSection
                    .padding(.top, 8)

                Spacer()
                    .frame(height: 30)

                TuningMeterView(
                    centsDeviation: viewModel.centsDeviation,
                    isInTune: viewModel.isInTune,
                    selectedString: viewModel.isChromatic ? nil : viewModel.selectedString,
                    showConfirmation: viewModel.showTuneConfirmation,
                    sustainedInTune: viewModel.sustainedInTune,
                    detectedFrequency: viewModel.detectedFrequency,
                    targetFrequency: viewModel.isChromatic
                        ? (viewModel.detectedNote?.targetFrequency ?? 0)
                        : viewModel.adjustedFrequency(for: viewModel.selectedString?.frequency ?? 0),
                    currentDecibels: viewModel.currentDecibels,
                    chromaticNote: viewModel.detectedNote
                )
                .padding(.horizontal, 20)
                .overlay(alignment: .bottom) {
                    // Reference tone indicator - overlaid to avoid layout shifts
                    if viewModel.isPlayingTone {
                        HStack(spacing: 6) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "4ECDC4"))
                            Text("Reference Tone")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(hex: "9a8aba"))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color(hex: "1a0a2e").opacity(0.9))
                                .overlay(
                                    Capsule()
                                        .stroke(Color(hex: "4ECDC4").opacity(0.3), lineWidth: 1)
                                )
                        )
                        .offset(y: 30)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .animation(.easeInOut(duration: 0.2), value: viewModel.isPlayingTone)
                    }
                }

                Spacer()

                tipJarSection
                    .padding(.bottom, 8)
            }
            .frame(maxWidth: geometry.size.width * 0.5)
        }
        .padding(.horizontal, LayoutConstants.iPadHorizontalPadding)
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            // Tuning picker with chromatic mode support
            TuningPickerView(
                selectedTuning: Binding(
                    get: { viewModel.selectedTuning },
                    set: { viewModel.setTuning($0) }
                ),
                availableTunings: Tuning.allTunings,
                tunerMode: Binding(
                    get: { viewModel.tunerMode },
                    set: { viewModel.setMode($0) }
                )
            )

            Spacer()

            // Listening indicator
            listeningIndicator
        }
        .padding(.horizontal, 16)
    }

    private var listeningIndicator: some View {
        HStack(spacing: 12) {
            // Reference pitch indicator (when not standard 440Hz)
            if viewModel.referencePitch != 440 {
                Text("A=\(viewModel.referencePitch)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "4ECDC4"))
                    .fixedSize()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color(hex: "4ECDC4").opacity(0.15))
                    )
            }

            // Auto-detect toggle (only in instrument mode)
            if !viewModel.isChromatic {
                VStack(spacing: 2) {
                    Toggle("", isOn: Binding(
                        get: { viewModel.autoDetectString },
                        set: { _ in viewModel.toggleAutoDetect() }
                    ))
                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "4ECDC4")))
                    .labelsHidden()
                    .scaleEffect(0.75)

                    Text("Auto")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(hex: "9a8aba"))
                }
            }

            // MENU BUTTON
            Button {
                showMenu = true
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 22))
                    .foregroundColor(Color(hex: "9a8aba"))
            }
            .sheet(isPresented: $showMenu) {
                ToolsMenuView(
                    viewModel: viewModel,
                    showStageMode: $showGigMode
                )
                .presentationDragIndicator(.visible)
                .presentationDetents([.medium, .large])
            }
        }
        .padding(.horizontal, 16)
        .fullScreenCover(isPresented: $showGigMode) {
            StageModeView(viewModel: viewModel)
        }
        // Rotation Detection
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            let orientation = UIDevice.current.orientation
            if orientation.isLandscape {
                if !showGigMode {
                    showGigMode = true
                }
            } else if orientation.isPortrait {
                // Optional: Auto-dismiss when rotating back
                if showGigMode {
                    showGigMode = false
                }
            }
        }
    }

    @State
    private var showTipJar = false
    @State
    private var showMenu = false
    @State
    private var showGigMode = false

    private var tipJarSection: some View {
        Button {
            showTipJar = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.pink)

                Text("Tip Jar")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "9a8aba"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showTipJar) {
            TipJarView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var allTunedFlashOverlay: some View {
        ZStack {
            // Subtle dark backdrop
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            // Mascot with celebration message
            VStack(spacing: 12) {
                Image("InAppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .shadow(color: .green.opacity(0.6), radius: 20)

                Text("All Tuned!")
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 4)

                Text("You're ready to play!")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "9a8aba"))
            }
            .scaleEffect(viewModel.showAllTunedFlash ? 1.0 : 0.5)
            .opacity(viewModel.showAllTunedFlash ? 1.0 : 0.0)
        }
        .transition(.opacity.combined(with: .scale))
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: viewModel.showAllTunedFlash)
    }

    private var permissionOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "mic.slash.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "9a8aba"))

                VStack(spacing: 8) {
                    Text("Microphone Access Required")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    Text("Stay Tuned needs access to your microphone to detect the pitch of your instrument.")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "9a8aba"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Button {
                    viewModel.requestPermission()
                } label: {
                    Text("Grant Access")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "6a5a8a"), Color(hex: "8a7aaa")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(40)
        }
    }
}

#Preview {
    TunerView()
}
