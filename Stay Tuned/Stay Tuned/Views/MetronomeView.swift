//
//  MetronomeView.swift
//  Stay Tuned
//
//  Created for Phase 6: Metronome
//

import SwiftUI

/// Main metronome view presented as a sheet
struct MetronomeView: View {
    @StateObject private var viewModel = MetronomeViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempoInputText = ""
    @State private var originalTempo: Double = 120
    @FocusState private var isTempoFieldFocused: Bool
    
    // For continuous +/- repeat
    @State private var repeatTimer: Timer?
    
    var body: some View {
        NavigationStack {
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
                
                VStack(spacing: 0) {
                    // Animated metronome icon
                    animatedIconSection
                        .padding(.top, 20)
                    
                    Spacer()
                        .frame(height: 30)
                    
                    // Tempo display
                    tempoDisplaySection
                    
                    Spacer()
                        .frame(height: 24)
                    
                    // Tempo slider
                    tempoSliderSection
                    
                    Spacer()
                        .frame(height: 32)
                    
                    // Beat indicators
                    beatIndicatorSection
                    
                    Spacer()
                        .frame(height: 32)
                    
                    // Play/Stop button
                    playButtonSection
                    
                    Spacer()
                        .frame(height: 24)
                    
                    // Time signature and tap tempo
                    controlsSection
                    
                    Spacer()
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
        }
    }
    
    // MARK: - Animated Icon Section
    
    private var animatedIconSection: some View {
        AnimatedMetronomeIcon(
            isAnimating: viewModel.isPlaying,
            currentBeat: viewModel.currentBeat,
            tempo: viewModel.tempo,
            size: 80,
            color: viewModel.isPlaying ? Color(hex: "4ECDC4") : Color(hex: "9a8aba")
        )
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
            repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
                if increment {
                    viewModel.tempo = min(240, viewModel.tempo + 5)
                } else {
                    viewModel.tempo = max(40, viewModel.tempo - 5)
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
            Slider(value: $viewModel.tempo, in: 40...240, step: 1)
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
        HStack(spacing: 16) {
            ForEach(1...viewModel.timeSignature.beatsPerMeasure, id: \.self) { beat in
                BeatDot(
                    isActive: viewModel.isPlaying && viewModel.currentBeat == beat,
                    isAccent: beat == 1,
                    isPlaying: viewModel.isPlaying
                )
            }
        }
        .animation(.easeInOut(duration: 0.1), value: viewModel.currentBeat)
    }
    
    // MARK: - Play Button Section
    
    private var playButtonSection: some View {
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
    }
    
    // MARK: - Controls Section
    
    private var controlsSection: some View {
        HStack(spacing: 16) {
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
                HStack(spacing: 8) {
                    Text(viewModel.timeSignature.displayName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "9a8aba"))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.08))
                )
            }
            
            Spacer()
            
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
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "4ECDC4").opacity(0.15))
                )
            }
            .buttonStyle(.plain)
        }
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
            return isAccent ? Color(hex: "4ECDC4") : Color.white
        } else {
            return Color.white.opacity(0.1)
        }
    }
    
    private var strokeColor: Color {
        if isActive {
            return .clear
        } else if isAccent {
            return Color(hex: "4ECDC4").opacity(0.5)
        } else {
            return Color.white.opacity(0.3)
        }
    }
}

#Preview {
    MetronomeView()
}

