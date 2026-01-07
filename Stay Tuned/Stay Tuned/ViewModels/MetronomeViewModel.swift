//
//  MetronomeViewModel.swift
//  Stay Tuned
//
//  Created for Phase 6: Metronome
//

import Combine
import SwiftUI
import UIKit

/// ViewModel for the metronome feature
@MainActor
final class MetronomeViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published
    var tempo: Double = 120
    @Published
    var isPlaying = false
    @Published
    var currentBeat: Int = 1
    @Published
    var timeSignature: TimeSignature = .fourFour
    @Published
    var selectedGrouping: BeatGrouping = TimeSignature.fourFour.defaultGrouping
    @Published
    var volume: Float = 0.7

    // Listen mode properties
    @Published
    var isListening = false
    @Published
    var detectedBPM: Double?
    @Published
    var alternativeBPM: Double?
    @Published
    var listenConfidence: Float = 0
    @Published
    var listenProgress: Float = 0
    @Published
    var listenStatus: ListenStatus = .idle
    @Published
    var onsetStrength: Float = 0 // Triggers UI pulse on beat detection (0-1)

    // MARK: - Listen Status

    enum ListenStatus: Equatable {
        case idle
        case listening
        case analyzing
        case detected
        case tooQuiet
    }

    // MARK: - Persistence

    @AppStorage("metronomeTempo")
    private var savedTempo: Int = 120
    @AppStorage("metronomeTimeSignature")
    private var savedTimeSignature: String = "4/4"
    @AppStorage("metronomeGrouping")
    private var savedGrouping: String = ""

    // MARK: - Private Properties

    private let engine = MetronomeEngine()
    private var tapTimes: [Date] = []
    private let maxTapCount = 6 // Increased for more stability
    private let tapResetInterval: TimeInterval = 2.5 // Slightly longer for breathing room
    private var lastCalculatedBPM: Double? // For EMA smoothing
    private var cancellables = Set<AnyCancellable>()

    // Haptic feedback generator
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)
    private let successHapticGenerator = UINotificationFeedbackGenerator()

    // Listen mode components
    private var listenAudioEngine: AudioEngine?
    private let beatDetector = BeatDetector()
    private var silenceCounter = 0
    private let silenceThreshold = 20 // Number of quiet buffers before showing "too quiet"

    // MARK: - Initialization

    init() {
        // Load saved values after all stored properties are initialized
        let loadedTempo = Double(savedTempo)
        let loadedTimeSignature = TimeSignature(rawValue: savedTimeSignature) ?? .fourFour

        // Load saved grouping or use default for the time signature
        let loadedGrouping = loadGrouping(for: loadedTimeSignature, savedValue: savedGrouping)

        self.tempo = loadedTempo
        self.timeSignature = loadedTimeSignature
        self.selectedGrouping = loadedGrouping

        // Apply saved values to engine
        engine.setTempo(loadedTempo)
        engine.setTimeSignature(loadedTimeSignature)
        engine.setAccentPositions(loadedGrouping.accentPositions)
        engine.volume = volume

        // Prepare haptic generators
        hapticGenerator.prepare()
        successHapticGenerator.prepare()

        // Set up beat callback
        engine.onBeat = { [weak self] beat in
            Task { @MainActor in
                self?.currentBeat = beat
            }
        }

        // Observe property changes using Combine
        setupObservers()
    }

    private func loadGrouping(for timeSignature: TimeSignature, savedValue: String) -> BeatGrouping {
        // Try to find matching grouping from available options
        if !savedValue.isEmpty {
            if let matching = timeSignature.availableGroupings.first(where: { $0.displayName == savedValue }) {
                return matching
            }
        }
        return timeSignature.defaultGrouping
    }

    private func setupObservers() {
        // Tempo changes
        $tempo
            .dropFirst() // Skip initial value
            .sink { [weak self] newTempo in
                guard let self else { return }
                let clamped = max(40, min(240, newTempo))
                self.savedTempo = Int(clamped)
                self.engine.setTempo(clamped)
            }
            .store(in: &cancellables)

        // Time signature changes
        $timeSignature
            .dropFirst()
            .sink { [weak self] newSignature in
                guard let self else { return }
                self.savedTimeSignature = newSignature.rawValue
                self.engine.setTimeSignature(newSignature)

                // Reset grouping if current one isn't valid for new time signature
                if !newSignature.availableGroupings.contains(self.selectedGrouping) {
                    self.selectedGrouping = newSignature.defaultGrouping
                }
            }
            .store(in: &cancellables)

        // Grouping changes
        $selectedGrouping
            .dropFirst()
            .sink { [weak self] newGrouping in
                guard let self else { return }
                self.savedGrouping = newGrouping.displayName
                self.engine.setAccentPositions(newGrouping.accentPositions)
            }
            .store(in: &cancellables)

        // Volume changes
        $volume
            .dropFirst()
            .sink { [weak self] newVolume in
                self?.engine.volume = newVolume
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// Toggle play/stop
    func togglePlayback() {
        if isPlaying {
            stop()
        } else {
            start()
        }
    }

    /// Start the metronome
    func start() {
        // Stop listening if active
        if isListening {
            stopListening()
        }

        currentBeat = 1
        engine.start()
        isPlaying = true
    }

    /// Stop the metronome
    func stop() {
        engine.stop()
        isPlaying = false
        currentBeat = 1
    }

    /// Increment tempo by 1 BPM
    func incrementTempo() {
        tempo = min(240, tempo + 1)
    }

    /// Decrement tempo by 1 BPM
    func decrementTempo() {
        tempo = max(40, tempo - 1)
    }

    // MARK: - Tap Tempo

    /// Process a tap for tap tempo feature using EMA with outlier rejection
    func tap() {
        let now = Date()

        // 1. Reset if too long since last tap
        if let lastTap = tapTimes.last,
           now.timeIntervalSince(lastTap) > tapResetInterval {
            tapTimes.removeAll()
            lastCalculatedBPM = nil
        }

        // Add new tap
        tapTimes.append(now)

        // Keep only the last N taps
        if tapTimes.count > maxTapCount {
            tapTimes.removeFirst()
        }

        // Need at least 2 taps to calculate tempo
        guard tapTimes.count >= 2 else {
            // First tap - just provide haptic feedback
            hapticGenerator.impactOccurred()
            return
        }

        // 2. Calculate current interval (time since previous tap)
        let currentInterval = now.timeIntervalSince(tapTimes[tapTimes.count - 2])
        let currentBPM = 60.0 / currentInterval

        // 3. Outlier rejection - ignore if wildly different from last BPM
        if let lastBPM = lastCalculatedBPM {
            let ratio = currentBPM / lastBPM
            // Reject if more than 50% different (likely a double-tap or missed tap)
            if ratio < 0.5 || ratio > 1.5 {
                // Remove the bad tap and skip update
                tapTimes.removeLast()
                return
            }
        }

        // Tap was valid - provide haptic feedback
        hapticGenerator.impactOccurred()

        // 4. Calculate new tempo using Exponential Moving Average
        if let lastBPM = lastCalculatedBPM {
            // Weight: 30% new, 70% old = smooth but responsive
            let smoothedBPM = 0.3 * currentBPM + 0.7 * lastBPM
            lastCalculatedBPM = smoothedBPM
            tempo = max(40, min(240, smoothedBPM))
        } else {
            // First valid calculation - use average of all intervals for stability
            let avgInterval = calculateAverageInterval()
            let avgBPM = 60.0 / avgInterval
            lastCalculatedBPM = avgBPM
            tempo = max(40, min(240, avgBPM))
        }
    }

    /// Calculate average interval between all stored taps
    private func calculateAverageInterval() -> TimeInterval {
        guard tapTimes.count >= 2 else { return 0.5 } // Default to 120 BPM

        var totalInterval: TimeInterval = 0
        for i in 1 ..< tapTimes.count {
            totalInterval += tapTimes[i].timeIntervalSince(tapTimes[i - 1])
        }
        return totalInterval / Double(tapTimes.count - 1)
    }

    // MARK: - Listen Mode

    /// Start listening for tempo via microphone
    func startListening() {
        // Stop metronome if playing
        if isPlaying {
            stop()
        }

        // Reset state
        beatDetector.reset()
        detectedBPM = nil
        alternativeBPM = nil
        listenConfidence = 0
        listenProgress = 0
        onsetStrength = 0
        silenceCounter = 0
        listenStatus = .listening

        // Set up onset detection callback for visual feedback
        beatDetector.onOnsetDetected = { [weak self] strength in
            Task { @MainActor in
                self?.onsetStrength = strength
                // Light haptic on each detected beat
                self?.hapticGenerator.impactOccurred()
            }
        }

        // Create and start audio engine
        listenAudioEngine = AudioEngine()

        listenAudioEngine?.onBufferReceived = { [weak self] samples, sampleRate in
            Task { @MainActor in
                self?.processListenBuffer(samples: samples, sampleRate: sampleRate)
            }
        }

        listenAudioEngine?.start()
        isListening = true
    }

    /// Stop listening and optionally keep detected tempo
    func stopListening() {
        listenAudioEngine?.stop()
        listenAudioEngine = nil
        isListening = false
        listenStatus = .idle
    }

    /// Apply the detected BPM to the metronome tempo
    func applyDetectedBPM() {
        guard let detected = detectedBPM else { return }

        tempo = detected
        successHapticGenerator.notificationOccurred(.success)
        stopListening()
    }

    /// Apply the alternative BPM (half/double time)
    func applyAlternativeBPM() {
        guard let alternative = alternativeBPM else { return }

        tempo = alternative
        successHapticGenerator.notificationOccurred(.success)
        stopListening()
    }

    /// Process audio buffer for beat detection
    private func processListenBuffer(samples: [Float], sampleRate: Double) {
        guard isListening else { return }

        // Check if audio is too quiet
        var rms: Float = 0
        samples.withUnsafeBufferPointer { ptr in
            vDSP_rmsqv(ptr.baseAddress!, 1, &rms, vDSP_Length(samples.count))
        }

        if rms < 0.002 {
            silenceCounter += 1
            if silenceCounter > silenceThreshold {
                listenStatus = .tooQuiet
            }
        } else {
            silenceCounter = 0
            if listenStatus == .tooQuiet {
                listenStatus = .listening
            }
        }

        // Analyze audio for beats
        if let result = beatDetector.analyze(samples: samples, sampleRate: sampleRate) {
            detectedBPM = result.bpm
            alternativeBPM = result.alternativeBPM
            listenConfidence = result.confidence

            // Show detected as soon as we have a BPM (no separate "analyzing" phase)
            listenStatus = .detected
        }

        // Update progress
        listenProgress = beatDetector.analysisProgress
    }
}

// Import Accelerate for RMS calculation in listen mode
import Accelerate
