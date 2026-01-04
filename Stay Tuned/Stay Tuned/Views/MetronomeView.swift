//
//  MetronomeView.swift
//  Stay Tuned
//
//  Created for Phase 6: Metronome
//

import SwiftUI

/// Main metronome view presented as a sheet
struct MetronomeView: View {
    @StateObject
    private var viewModel = MetronomeViewModel()
    @Environment(\.dismiss)
    private var dismiss

    @State
    private var tempoInputText = ""
    @State
    private var originalTempo: Double = 120
    @FocusState
    private var isTempoFieldFocused: Bool

    // For continuous +/- repeat
    @State
    private var repeatTimer: Timer?

    // Fixed width for grouping picker to prevent layout shift
    private let groupingPickerWidth: CGFloat = 70

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient matching app theme
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

                VStack(spacing: 0) {
                    // Animated metronome icon
                    animatedIconSection
                        .padding(.top, 20)

                    Spacer()
                        .frame(height: 30)

                    // Tempo display or Listen mode display
                    if viewModel.isListening {
                        listenModeSection
                    } else {
                        tempoDisplaySection
                    }

                    Spacer()
                        .frame(height: 24)

                    // Tempo slider (hidden during listen mode)
                    if !viewModel.isListening {
                        tempoSliderSection
                    }

                    Spacer()
                        .frame(height: 32)

                    // Beat indicators (hidden during listen mode)
                    if !viewModel.isListening {
                        beatIndicatorSection

                        Spacer()
                            .frame(height: 32)

                        // Time signature, grouping, and tempo input controls
                        controlsSection

                        Spacer()
                            .frame(height: 20)
                    } else {
                        Spacer()
                    }

                    // Play/Stop button or Listen controls
                    if viewModel.isListening {
                        listenControlsSection
                    } else {
                        playButtonSection
                    }

                    Spacer()
                        .frame(height: 24)
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Metronome")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "4ECDC4"))
                }
            }
            .toolbarBackground(Color(hex: "1a0a2e"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onDisappear {
            // Stop when sheet is dismissed
            viewModel.stop()
            viewModel.stopListening()
        }
    }

    // MARK: - Animated Icon Section

    private var animatedIconSection: some View {
        ZStack {
            if viewModel.isListening {
                // Pulsing microphone icon when listening - synced to detected beats
                ListeningIndicator(status: viewModel.listenStatus, onsetStrength: viewModel.onsetStrength)
            } else {
                AnimatedMetronomeIcon(
                    isAnimating: viewModel.isPlaying,
                    currentBeat: viewModel.currentBeat,
                    tempo: viewModel.tempo,
                    size: 80,
                    color: viewModel.isPlaying ? Color(hex: "4ECDC4") : Color(hex: "9a8aba")
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isListening)
    }

    // MARK: - Listen Mode Section

    private var listenModeSection: some View {
        VStack(spacing: 20) {
            // Status text
            Text(listenStatusText)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "9a8aba"))

            // Detected BPM display
            if let bpm = viewModel.detectedBPM {
                VStack(spacing: 8) {
                    Text("\(Int(bpm))")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.snappy(duration: 0.2), value: bpm)

                    Text("BPM")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "7c6c9a"))

                    // Confidence indicator
                    ConfidenceBar(confidence: viewModel.listenConfidence)
                        .frame(width: 120)
                }
            } else {
                // Progress indicator while waiting for enough beats
                VStack(spacing: 16) {
                    ProgressView(value: viewModel.listenProgress)
                        .tint(Color(hex: "4ECDC4"))
                        .frame(width: 150)

                    Text("Detecting beats...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "7c6c9a"))
                }
                .padding(.vertical, 30)
            }

            // Alternative tempo option
            if let altBPM = viewModel.alternativeBPM, viewModel.listenStatus == .detected {
                Button {
                    viewModel.applyAlternativeBPM()
                } label: {
                    Text("Or use \(Int(altBPM)) BPM")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "4ECDC4").opacity(0.8))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var listenStatusText: String {
        switch viewModel.listenStatus {
        case .idle:
            "Ready to listen"
        case .listening:
            "Listening for rhythm..."
        case .analyzing:
            "Listening for rhythm..."
        case .detected:
            if viewModel.listenConfidence > 0.6 {
                "Tempo locked!"
            } else {
                "Refining..."
            }
        case .tooQuiet:
            "Too quiet - play louder"
        }
    }

    // MARK: - Listen Controls Section

    private var listenControlsSection: some View {
        VStack(spacing: 16) {
            // Apply button (only when detected)
            if viewModel.listenStatus == .detected, viewModel.detectedBPM != nil {
                Button {
                    viewModel.applyDetectedBPM()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .semibold))

                        Text("USE THIS TEMPO")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: "4ECDC4"))
                    )
                }
                .buttonStyle(.plain)
            }

            // Cancel button
            Button {
                viewModel.stopListening()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))

                    Text("Cancel")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(Color(hex: "9a8aba"))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.08))
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Tempo Display Section

    private var tempoDisplaySection: some View {
        VStack(spacing: 16) {
            // Large tempo number - tappable for direct input
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("♩")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(Color(hex: "9a8aba"))

                Text("=")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(Color(hex: "7c6c9a"))

                // Inline editable tempo field
                ZStack {
                    // TextField for input (visible when editing)
                    TextField("", text: $tempoInputText)
                        .keyboardType(.numberPad)
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .focused($isTempoFieldFocused)
                        .frame(width: 140)
                        .opacity(isTempoFieldFocused ? 1 : 0)
                        .onChange(of: isTempoFieldFocused) { _, focused in
                            if focused {
                                // Store original and start with empty field
                                originalTempo = viewModel.tempo
                                tempoInputText = ""
                            }
                            // Note: Don't auto-apply on focus loss - user must tap Set or Cancel
                        }
                        .onSubmit {
                            applyTempoInput()
                        }
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Button("Cancel") {
                                    // Revert to original tempo
                                    viewModel.tempo = originalTempo
                                    isTempoFieldFocused = false
                                }
                                .foregroundColor(Color(hex: "9a8aba"))

                                Spacer()

                                Button("Set") {
                                    applyTempoInput()
                                }
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "4ECDC4"))
                            }
                        }

                    // Display text (shown when not editing)
                    if !isTempoFieldFocused {
                        Text("\(Int(viewModel.tempo))")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(.snappy(duration: 0.2), value: viewModel.tempo)
                            .onTapGesture {
                                isTempoFieldFocused = true
                            }
                    }
                }
            }

            // +/- Buttons with continuous repeat on long press
            HStack(spacing: 24) {
                // Minus button
                Image(systemName: "minus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: "4ECDC4"))
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.08))
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                startRepeating(increment: false)
                            }
                            .onEnded { _ in
                                stopRepeating()
                            }
                    )

                // Plus button
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: "4ECDC4"))
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.08))
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                startRepeating(increment: true)
                            }
                            .onEnded { _ in
                                stopRepeating()
                            }
                    )
            }
        }
    }

    // MARK: - Repeat Timer Methods

    private func startRepeating(increment: Bool) {
        // Only start if not already running
        guard repeatTimer == nil else { return }

        // Immediate first action (single step of 1)
        if increment {
            viewModel.incrementTempo()
        } else {
            viewModel.decrementTempo()
        }

        // After 1.5 second delay, start repeating every 150ms with +/- 5
        repeatTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [self] _ in
            // Start the fast repeat timer
            repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [self] _ in
                Task { @MainActor in
                    if increment {
                        viewModel.tempo = min(240, viewModel.tempo + 5)
                    } else {
                        viewModel.tempo = max(40, viewModel.tempo - 5)
                    }
                }
            }
        }
    }

    private func stopRepeating() {
        repeatTimer?.invalidate()
        repeatTimer = nil
    }

    private func applyTempoInput() {
        if let newTempo = Double(tempoInputText), newTempo >= 40, newTempo <= 240 {
            viewModel.tempo = newTempo
        }
        // If input is empty or invalid, keep original tempo
        isTempoFieldFocused = false
    }

    // MARK: - Tempo Slider Section

    private var tempoSliderSection: some View {
        VStack(spacing: 8) {
            Slider(value: $viewModel.tempo, in: 40 ... 240, step: 1)
                .tint(Color(hex: "4ECDC4"))

            HStack {
                Text("40")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "7c6c9a"))

                Spacer()

                Text("240")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "7c6c9a"))
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Beat Indicator Section

    private var beatIndicatorSection: some View {
        HStack(spacing: 0) {
            let groups = viewModel.selectedGrouping.groups
            let accentPositions = viewModel.selectedGrouping.accentPositions

            ForEach(Array(groups.enumerated()), id: \.offset) { groupIndex, groupSize in
                // Add separator between groups (not before first group)
                if groupIndex > 0 {
                    GroupSeparator()
                }

                // Dots for this group
                HStack(spacing: 12) {
                    ForEach(0 ..< groupSize, id: \.self) { beatInGroup in
                        let absoluteBeat = calculateAbsoluteBeat(groupIndex: groupIndex, beatInGroup: beatInGroup)
                        BeatDot(
                            isActive: viewModel.isPlaying && viewModel.currentBeat == absoluteBeat,
                            isAccent: accentPositions.contains(absoluteBeat),
                            isPlaying: viewModel.isPlaying
                        )
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.1), value: viewModel.currentBeat)
        .animation(.easeInOut(duration: 0.2), value: viewModel.selectedGrouping)
    }

    /// Calculate the absolute beat number (1-indexed) for a beat within a group
    private func calculateAbsoluteBeat(groupIndex: Int, beatInGroup: Int) -> Int {
        let groups = viewModel.selectedGrouping.groups
        var beat = 1
        for i in 0 ..< groupIndex {
            beat += groups[i]
        }
        return beat + beatInGroup
    }

    // MARK: - Play Button Section

    private var playButtonSection: some View {
        VStack(spacing: 12) {
            // Main play/stop button
            Button {
                viewModel.togglePlayback()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: viewModel.isPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 22, weight: .semibold))

                    Text(viewModel.isPlaying ? "STOP" : "START")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            viewModel.isPlaying
                                ? Color(hex: "e74c3c")
                                : Color(hex: "4ECDC4")
                        )
                )
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isPlaying)

            // Tap and Listen buttons row
            HStack(spacing: 12) {
                // Tap tempo button
                Button {
                    viewModel.tap()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 16, weight: .medium))

                        Text("Tap")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: "4ECDC4"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "4ECDC4").opacity(0.15))
                    )
                }
                .buttonStyle(.plain)

                // Listen button
                Button {
                    viewModel.startListening()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "waveform")
                            .font(.system(size: 16, weight: .medium))

                        Text("Listen")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: "FF6B9D"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "FF6B9D").opacity(0.15))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        HStack(spacing: 12) {
            // Time signature picker
            Menu {
                ForEach(TimeSignature.allCases) { signature in
                    Button {
                        viewModel.timeSignature = signature
                    } label: {
                        HStack {
                            Text(signature.displayName)
                            if viewModel.timeSignature == signature {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(viewModel.timeSignature.displayName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(hex: "9a8aba"))
                }
                .frame(height: 44) // Minimum touch target
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.08))
                )
            }

            // Fixed-width container for grouping picker to prevent layout shift
            ZStack {
                if viewModel.timeSignature.hasMultipleGroupings {
                    Menu {
                        ForEach(viewModel.timeSignature.availableGroupings) { grouping in
                            Button {
                                viewModel.selectedGrouping = grouping
                            } label: {
                                HStack {
                                    Text(grouping.displayName)
                                    if viewModel.selectedGrouping == grouping {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(viewModel.selectedGrouping.displayName)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Color(hex: "4ECDC4"))

                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color(hex: "4ECDC4").opacity(0.7))
                        }
                        .frame(width: groupingPickerWidth, height: 44) // Fixed size, minimum touch target
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "4ECDC4").opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: "4ECDC4").opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                } else {
                    // Invisible placeholder to maintain layout
                    Color.clear
                        .frame(width: groupingPickerWidth, height: 44)
                }
            }
            .frame(width: groupingPickerWidth)

            Spacer()
        }
    }
}

// MARK: - Listening Indicator Component

struct ListeningIndicator: View {
    let status: MetronomeViewModel.ListenStatus
    let onsetStrength: Float // 0-1, triggers pulse on beat detection

    @State
    private var pulseScale: CGFloat = 1.0

    // Multiple rings for ripple effect
    @State
    private var ring1Scale: CGFloat = 1.0
    @State
    private var ring1Opacity: Double = 0.0
    @State
    private var ring2Scale: CGFloat = 1.0
    @State
    private var ring2Opacity: Double = 0.0
    @State
    private var ring3Scale: CGFloat = 1.0
    @State
    private var ring3Opacity: Double = 0.0

    // Track which ring to animate next
    @State
    private var nextRing = 0

    var body: some View {
        ZStack {
            // Ring 3 (outermost ripple)
            Circle()
                .stroke(Color(hex: "FF6B9D"), lineWidth: 2)
                .frame(width: 80, height: 80)
                .scaleEffect(ring3Scale)
                .opacity(ring3Opacity)

            // Ring 2 (middle ripple)
            Circle()
                .stroke(Color(hex: "FF6B9D"), lineWidth: 2.5)
                .frame(width: 80, height: 80)
                .scaleEffect(ring2Scale)
                .opacity(ring2Opacity)

            // Ring 1 (inner ripple)
            Circle()
                .stroke(Color(hex: "FF6B9D"), lineWidth: 3)
                .frame(width: 80, height: 80)
                .scaleEffect(ring1Scale)
                .opacity(ring1Opacity)

            // Microphone icon with beat-synced pulse
            Image(systemName: microphoneIcon)
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 80, height: 80)
                .background(
                    Circle()
                        .fill(Color(hex: "FF6B9D").opacity(0.2))
                )
                .scaleEffect(pulseScale)
        }
        .onChange(of: onsetStrength) { _, strength in
            // Pulse on each detected onset
            if strength > 0.05 {
                triggerBeatPulse(strength: strength)
            }
        }
    }

    private func triggerBeatPulse(strength: Float) {
        let intensity = CGFloat(min(1.0, strength * 1.2))

        // Mic icon pulse
        withAnimation(.easeOut(duration: 0.08)) {
            pulseScale = 1.0 + (0.15 * intensity)
        }
        withAnimation(.easeIn(duration: 0.12).delay(0.08)) {
            pulseScale = 1.0
        }

        // Animate the next ring in sequence (creates staggered ripple effect)
        let ringToAnimate = nextRing % 3
        nextRing += 1

        switch ringToAnimate {
        case 0:
            animateRing1(intensity: intensity)
        case 1:
            animateRing2(intensity: intensity)
        default:
            animateRing3(intensity: intensity)
        }
    }

    private func animateRing1(intensity: CGFloat) {
        // Reset
        ring1Scale = 1.0
        ring1Opacity = 0.7

        // Expand outward and fade
        withAnimation(.easeOut(duration: 0.5)) {
            ring1Scale = 1.8 + (0.4 * intensity)
            ring1Opacity = 0.0
        }
    }

    private func animateRing2(intensity: CGFloat) {
        ring2Scale = 1.0
        ring2Opacity = 0.7

        withAnimation(.easeOut(duration: 0.5)) {
            ring2Scale = 1.8 + (0.4 * intensity)
            ring2Opacity = 0.0
        }
    }

    private func animateRing3(intensity: CGFloat) {
        ring3Scale = 1.0
        ring3Opacity = 0.7

        withAnimation(.easeOut(duration: 0.5)) {
            ring3Scale = 1.8 + (0.4 * intensity)
            ring3Opacity = 0.0
        }
    }

    private var microphoneIcon: String {
        switch status {
        case .tooQuiet:
            "mic.slash"
        case .detected:
            "checkmark.circle"
        default:
            "mic.fill"
        }
    }

    private var iconColor: Color {
        switch status {
        case .tooQuiet:
            Color(hex: "9a8aba")
        case .detected:
            Color(hex: "4ECDC4")
        default:
            Color(hex: "FF6B9D")
        }
    }
}

// MARK: - Confidence Bar Component

struct ConfidenceBar: View {
    let confidence: Float

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))

                    // Filled portion
                    RoundedRectangle(cornerRadius: 4)
                        .fill(confidenceColor)
                        .frame(width: geometry.size.width * CGFloat(confidence))
                        .animation(.easeOut(duration: 0.3), value: confidence)
                }
            }
            .frame(height: 6)

            Text(confidenceText)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color(hex: "7c6c9a"))
        }
    }

    private var confidenceColor: Color {
        if confidence > 0.7 {
            Color(hex: "4ECDC4")
        } else if confidence > 0.4 {
            Color(hex: "FFD93D")
        } else {
            Color(hex: "FF6B9D")
        }
    }

    private var confidenceText: String {
        if confidence > 0.7 {
            "High confidence"
        } else if confidence > 0.4 {
            "Medium confidence"
        } else {
            "Low confidence"
        }
    }
}

// MARK: - Group Separator Component

/// Visual separator between beat groups
struct GroupSeparator: View {
    var body: some View {
        Rectangle()
            .fill(Color(hex: "4ECDC4").opacity(0.4))
            .frame(width: 2, height: 24)
            .padding(.horizontal, 10)
    }
}

// MARK: - Beat Dot Component

struct BeatDot: View {
    let isActive: Bool
    let isAccent: Bool
    let isPlaying: Bool

    var body: some View {
        Circle()
            .fill(dotColor)
            .frame(width: dotSize, height: dotSize)
            .overlay(
                Circle()
                    .stroke(strokeColor, lineWidth: 2)
            )
            .scaleEffect(isActive ? 1.3 : 1.0)
            .animation(.spring(response: 0.15, dampingFraction: 0.6), value: isActive)
    }

    private var dotSize: CGFloat {
        isAccent ? 20 : 16
    }

    private var dotColor: Color {
        if isActive {
            isAccent ? Color(hex: "4ECDC4") : Color.white
        } else {
            Color.white.opacity(0.1)
        }
    }

    private var strokeColor: Color {
        if isActive {
            .clear
        } else if isAccent {
            Color(hex: "4ECDC4").opacity(0.5)
        } else {
            Color.white.opacity(0.3)
        }
    }
}

#Preview {
    MetronomeView()
}
