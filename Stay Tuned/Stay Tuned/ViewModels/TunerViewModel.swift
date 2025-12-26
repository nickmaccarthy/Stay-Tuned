//
//  TunerViewModel.swift
//  Stay Tuned
//
//  Created by Nick MacCarthy on 12/21/25.
//

import Combine
import Foundation
import SwiftUI

/// Main view model for the tuner
@MainActor
final class TunerViewModel: ObservableObject {

    // MARK: - Persisted Settings

    @AppStorage("lastSelectedTuningId")
    private var lastSelectedTuningId: String = "guitar_standard"
    @AppStorage("referencePitch")
    var referencePitch: Int = 440
    @AppStorage("tunerMode")
    private var storedTunerMode: String = TunerMode.instrument.rawValue
    @AppStorage("toneType")
    private var storedToneType: String = ToneType.string.rawValue

    /// The current tone type for reference tone playback
    var toneType: ToneType {
        get { ToneType(rawValue: storedToneType) ?? .string }
        set { storedToneType = newValue.rawValue }
    }

    /// Multiplier for adjusting frequencies based on reference pitch (1.0 when A=440Hz)
    var referencePitchMultiplier: Double {
        Double(referencePitch) / 440.0
    }

    /// Adjusts a base frequency (at A=440Hz) to the current reference pitch
    func adjustedFrequency(for baseFrequency: Double) -> Double {
        baseFrequency * referencePitchMultiplier
    }

    // MARK: - Published Properties

    @Published
    var tunerMode: TunerMode = .instrument {
        didSet {
            storedTunerMode = tunerMode.rawValue
        }
    }

    /// Whether the tuner is in chromatic mode
    var isChromatic: Bool {
        tunerMode == .chromatic
    }

    @Published
    var selectedTuning: Tuning = .standard {
        didSet {
            // Persist the tuning selection
            lastSelectedTuningId = selectedTuning.id
        }
    }

    @Published
    var selectedString: GuitarString?
    @Published
    var detectedNote: ChromaticNote?
    @Published
    var detectedFrequency: Double = 0
    @Published
    var centsDeviation: Int = 0
    @Published
    var isInTune: Bool = false
    @Published
    var isListening: Bool = false
    @Published
    var hasPermission: Bool = false
    @Published
    var isDetectingPitch: Bool = false
    @Published
    var autoDetectString: Bool = true // Auto-detect which string user is tuning

    @Published
    var tunedStrings: Set<Int> = [] // For auto-advance feature
    @Published
    var confirmedStrings: Set<Int> = [] // Strings that have been confirmed in-tune (stays green)
    @Published
    var showTuneConfirmation: Bool = false
    @Published
    var allStringsTuned: Bool = false
    @Published
    var showAllTunedFlash: Bool = false // Quick flash when all strings tuned
    @Published
    var sustainedInTune: Bool = false // True when in tune for 2+ seconds
    @Published
    var currentDecibels: Float? // Current dB level when detecting

    // Audio samples for spectrum analyzer
    @Published
    var audioSamples: [Float] = []
    @Published
    var audioSampleRate: Double = 48000

    /// Normalized amplitude (0.0 to 1.0) for audio visualization
    var normalizedAmplitude: Double {
        guard let dB = currentDecibels else { return 0 }
        // Map dB range (-60 to 0) to 0.0 to 1.0
        return Double(max(0, min(1, (dB + 60) / 60)))
    }

    // MARK: - Tone Playback

    @Published
    var isPlayingTone: Bool = false
    @Published
    var playingToneStringId: Int? = nil // Which string's tone is currently playing

    // MARK: - Private Properties

    private let audioEngine = AudioEngine()
    private let pitchDetector = PitchDetector()
    private let toneGenerator = ToneGenerator()
    private var cancellables = Set<AnyCancellable>()

    // Frequency history for smoothing
    private var frequencyHistory: [Double] = []
    private let maxHistorySize = 8 // Max samples to keep for smoothing

    // Display with adaptive smoothing
    private var displayedCents: Int = 0
    private var smoothedCents: Double = 0 // For low-pass filtering

    // Timing
    private var lastPitchTime: Date = .distantPast

    // Tune confirmation
    private var inTuneCount: Int = 0
    private var lastAdvanceTime: Date = .distantPast

    // Sustained in-tune tracking
    private var inTuneStartTime: Date?
    private let sustainedInTuneDuration: TimeInterval = 0.5

    // MARK: - Initialization

    init() {
        // Restore tuner mode from storage
        if let savedMode = TunerMode(rawValue: storedTunerMode) {
            tunerMode = savedMode
        }

        // Restore last selected tuning from storage
        if let savedTuning = Tuning.allTunings.first(where: { $0.id == lastSelectedTuningId }) {
            selectedTuning = savedTuning
        }

        setupBindings()
        startDisplayTimer()
    }

    private func setupBindings() {
        audioEngine.$hasPermission
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.hasPermission = $0 }
            .store(in: &cancellables)

        audioEngine.$isRunning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isListening = $0 }
            .store(in: &cancellables)

        audioEngine.onBufferReceived = { [weak self] samples, sampleRate in
            Task { @MainActor in
                self?.processAudio(samples: samples, sampleRate: sampleRate)
            }
        }
    }

    private func startDisplayTimer() {
        Timer.publish(every: 0.03, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                let timeSincePitch = Date().timeIntervalSince(self.lastPitchTime)
                // Quick timeout (0.3s) - clears fast when note fades
                if timeSincePitch > 0.3, self.isDetectingPitch {
                    self.isDetectingPitch = false
                    self.frequencyHistory.removeAll()
                    self.currentDecibels = nil
                }
            }
            .store(in: &cancellables)
    }

    private func processAudio(samples: [Float], sampleRate: Double) {
        // Update samples for spectrum analyzer (accumulate for better FFT)
        audioSamples.append(contentsOf: samples)
        if audioSamples.count > 4096 {
            audioSamples.removeFirst(audioSamples.count - 4096)
        }
        audioSampleRate = sampleRate

        // Skip pitch detection while playing reference tone
        // (prevents the tone from "tuning itself" via speaker-to-mic feedback)
        if isPlayingTone {
            return
        }

        guard let frequency = pitchDetector.detectPitch(samples: samples, sampleRate: sampleRate) else {
            return
        }

        lastPitchTime = Date()

        // Get current dB level for adaptive smoothing
        let dB = pitchDetector.currentDecibels ?? -40

        // Adaptive history size: more smoothing at lower volumes
        // At -20dB: keep 2 samples (responsive)
        // At -55dB: keep 8 samples (very stable)
        let smoothingFactor = min(1.0, max(0.0, Double(-20 - dB) / 35.0))
        let adaptiveHistorySize = 2 + Int(smoothingFactor * 6)

        // Add to history with adaptive size
        frequencyHistory.append(frequency)
        while frequencyHistory.count > adaptiveHistorySize {
            frequencyHistory.removeFirst()
        }

        // Use median frequency for stability
        let sortedFreqs = frequencyHistory.sorted()
        let medianFreq = sortedFreqs[sortedFreqs.count / 2]

        // Mode-specific processing
        var rawCents = 0
        var targetString: GuitarString? = nil
        var chromaticNote: ChromaticNote? = nil

        if isChromatic {
            // Chromatic mode: detect note from frequency
            let note = ChromaticNote.from(frequency: medianFreq, referencePitch: Double(referencePitch))
            chromaticNote = note
            rawCents = note.centsDeviation
        } else {
            // Instrument mode: find target string
            // Normalize detected frequency to A=440 basis for string matching
            let normalizedFreq = medianFreq / referencePitchMultiplier
            if autoDetectString {
                // Auto-detect: find closest string to detected frequency
                targetString = selectedTuning.closestString(to: normalizedFreq)
            } else if let selected = selectedString {
                // Manual mode: use selected string
                targetString = selected
            } else {
                // Fallback: find closest
                targetString = selectedTuning.closestString(to: normalizedFreq)
            }

            // Calculate cents using adjusted target frequency for reference pitch
            if let target = targetString {
                let adjustedTargetFreq = target.frequency * referencePitchMultiplier
                rawCents = TuningResult.calculateCents(detected: medianFreq, target: adjustedTargetFreq)
            }
        }
        rawCents = max(-50, min(50, rawCents))

        // Apply exponential smoothing to cents - more smoothing at lower volumes
        // At -20dB: alpha = 0.7 (responsive)
        // At -55dB: alpha = 0.15 (very stable)
        let alpha = max(0.15, 0.7 - smoothingFactor * 0.55)
        smoothedCents = alpha * Double(rawCents) + (1 - alpha) * smoothedCents

        displayedCents = rawCents
        let finalCents = Int(round(smoothedCents))

        // Update display - in tune within ±5 cents
        let isCurrentlyInTune = abs(finalCents) <= 7
        let isPerfect = abs(finalCents) <= 1

        // Track sustained in-tune time
        if isCurrentlyInTune {
            if inTuneStartTime == nil {
                inTuneStartTime = Date()
            }
        } else {
            inTuneStartTime = nil
        }

        // Check if we've been in tune for 2+ seconds
        let isSustainedInTune: Bool = if let startTime = inTuneStartTime {
            Date().timeIntervalSince(startTime) >= sustainedInTuneDuration
        } else {
            false
        }

        // Capture dB level before async
        let dBLevel = pitchDetector.currentDecibels

        Task { @MainActor in
            self.detectedFrequency = medianFreq
            self.centsDeviation = finalCents
            self.isInTune = isCurrentlyInTune
            self.isDetectingPitch = true
            self.currentDecibels = dBLevel

            if self.isChromatic {
                // Chromatic mode: update detected note
                self.detectedNote = chromaticNote
                self.sustainedInTune = isSustainedInTune
            } else {
                // Instrument mode: handle string confirmation and tracking
                self.detectedNote = nil

                // Determine current string BEFORE any changes
                let currentStringBeforeChange = self.selectedString

                // Add to confirmed strings FIRST if sustained in-tune (using local variable)
                // This ensures we capture the confirmation before any auto-detect string switch
                if isSustainedInTune, let currentString = currentStringBeforeChange {
                    if !self.confirmedStrings.contains(currentString.id) {
                        self.confirmedStrings.insert(currentString.id)
                        // Haptic feedback when string is confirmed
                        UINotificationFeedbackGenerator().notificationOccurred(.success)

                        // Check if ALL strings are now confirmed
                        if self.confirmedStrings.count >= self.selectedTuning.strings.count {
                            self.triggerAllTunedFlash()
                        }
                    }
                }

                // Now update sustainedInTune for display
                self.sustainedInTune = isSustainedInTune

                // Update selected string based on auto-detect mode
                if self.autoDetectString {
                    // In auto mode, update selected string to match detected
                    if let detected = targetString, self.selectedString?.id != detected.id {
                        self.selectedString = detected
                        // Reset sustained timer when string changes
                        self.inTuneStartTime = nil
                        self.sustainedInTune = false
                    }
                } else if self.selectedString == nil {
                    self.selectedString = self.selectedTuning.strings.first
                }

                // Confirmation tracking (for auto-advance)
                if isPerfect, self.selectedString != nil, !self.showTuneConfirmation {
                    self.inTuneCount += 1
                    if self.inTuneCount >= 20 {
                        self.confirmStringTuned()
                    }
                } else if !isPerfect {
                    self.inTuneCount = max(0, self.inTuneCount - 1)
                }
            }
        }
    }

    private func confirmStringTuned() {
        guard let currentString = selectedString else { return }
        guard Date().timeIntervalSince(lastAdvanceTime) > 1.5 else { return }
        lastAdvanceTime = Date()

        tunedStrings.insert(currentString.id)
        showTuneConfirmation = true

        if tunedStrings.count >= selectedTuning.strings.count {
            allStringsTuned = true
        }

        inTuneCount = 0
        frequencyHistory.removeAll()

        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            await MainActor.run {
                self.showTuneConfirmation = false
                if !self.allStringsTuned {
                    self.advanceToNextString()
                }
            }
        }
    }

    private func advanceToNextString() {
        guard let current = selectedString else {
            selectedString = selectedTuning.strings.first
            return
        }

        for i in (current.id + 1) ..< selectedTuning.strings.count {
            if !tunedStrings.contains(i) {
                selectString(selectedTuning.strings[i])
                return
            }
        }

        for i in 0 ..< current.id {
            if !tunedStrings.contains(i) {
                selectString(selectedTuning.strings[i])
                return
            }
        }

        allStringsTuned = true
    }

    // MARK: - Public Methods

    func startListening() {
        print("TunerViewModel: startListening() called")
        audioEngine.start()
        if selectedString == nil {
            selectedString = selectedTuning.strings.first
        }
    }

    func stopListening() {
        audioEngine.stop()
        stopTone()
        detectedFrequency = 0
        centsDeviation = 0
        isInTune = false
        sustainedInTune = false
        isDetectingPitch = false
        inTuneCount = 0
        inTuneStartTime = nil
        frequencyHistory.removeAll()
        displayedCents = 0
        smoothedCents = 0
        currentDecibels = nil
        audioSamples.removeAll()
    }

    func toggleListening() {
        isListening ? stopListening() : startListening()
    }

    func toggleAutoDetect() {
        autoDetectString.toggle()
    }

    func selectString(_ string: GuitarString) {
        // If clicking on an already-confirmed string, toggle off the confirmation
        if confirmedStrings.contains(string.id) {
            confirmedStrings.remove(string.id)
            tunedStrings.remove(string.id)
            allStringsTuned = false
        }

        // Stop tone when changing strings
        stopTone()

        // Manually selecting a string turns off auto-detect
        autoDetectString = false

        selectedString = string
        detectedFrequency = 0
        centsDeviation = 0
        isInTune = false
        sustainedInTune = false
        inTuneCount = 0
        inTuneStartTime = nil
        showTuneConfirmation = false
        frequencyHistory.removeAll()
        displayedCents = 0
        smoothedCents = 0
    }

    func clearStringSelection() {
        selectedString = nil
    }

    func setTuning(_ tuning: Tuning) {
        selectedTuning = tuning
        selectedString = tuning.strings.first
        detectedFrequency = 0
        centsDeviation = 0
        isInTune = false
        sustainedInTune = false
        inTuneCount = 0
        inTuneStartTime = nil
        tunedStrings.removeAll()
        confirmedStrings.removeAll()
        allStringsTuned = false
        showTuneConfirmation = false
        frequencyHistory.removeAll()
        displayedCents = 0
        smoothedCents = 0
    }

    func setMode(_ mode: TunerMode) {
        tunerMode = mode
        detectedFrequency = 0
        centsDeviation = 0
        isInTune = false
        sustainedInTune = false
        inTuneCount = 0
        inTuneStartTime = nil
        detectedNote = nil
        frequencyHistory.removeAll()
        displayedCents = 0
        smoothedCents = 0

        // Reset instrument-specific state when switching modes
        if mode == .chromatic {
            selectedString = nil
        } else {
            selectedString = selectedTuning.strings.first
        }
    }

    private func triggerAllTunedFlash() {
        // Set allStringsTuned and show flash
        allStringsTuned = true
        showAllTunedFlash = true

        // Strong haptic feedback for completion
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        // Auto-dismiss the flash after 1.5 seconds
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                self.showAllTunedFlash = false
            }
        }
    }

    func resetTuningSession() {
        tunedStrings.removeAll()
        confirmedStrings.removeAll()
        allStringsTuned = false
        showAllTunedFlash = false
        selectedString = selectedTuning.strings.first
        detectedFrequency = 0
        centsDeviation = 0
        isInTune = false
        sustainedInTune = false
        inTuneCount = 0
        inTuneStartTime = nil
        showTuneConfirmation = false
        frequencyHistory.removeAll()
        displayedCents = 0
        smoothedCents = 0
    }

    func requestPermission() {
        audioEngine.requestPermission()
    }

    // MARK: - Tone Playback Methods

    /// Toggle reference tone playback for the selected string
    func toggleTone() {
        if isPlayingTone {
            stopTone()
        } else {
            playTone()
        }
    }

    /// Toggle tone playback for a specific string (used by double-tap on tuning pegs)
    func toggleToneForString(_ string: GuitarString) {
        // Always play/re-pluck the string (ToneGenerator handles re-pluck if same note)
        // This gives guitar-like behavior where double-tap = new pluck
        selectedString = string
        let frequency = adjustedFrequency(for: string.frequency)
        toneGenerator.toneType = toneType
        toneGenerator.play(frequency: frequency)
        isPlayingTone = true
        playingToneStringId = string.id

        // Reset tuning state to prevent carry-over from previous detection
        sustainedInTune = false
        inTuneStartTime = nil
        isDetectingPitch = false
        frequencyHistory.removeAll()
    }

    /// Start playing the reference tone for the selected string
    private func playTone() {
        guard let string = selectedString else { return }

        // Calculate frequency adjusted for reference pitch
        let frequency = adjustedFrequency(for: string.frequency)
        toneGenerator.toneType = toneType
        toneGenerator.play(frequency: frequency)
        isPlayingTone = true
        playingToneStringId = string.id
    }

    /// Stop playing the reference tone
    func stopTone() {
        toneGenerator.stop()
        isPlayingTone = false
        playingToneStringId = nil

        // Clear history for fresh detection after tone stops
        frequencyHistory.removeAll()
        smoothedCents = 0
    }
}
