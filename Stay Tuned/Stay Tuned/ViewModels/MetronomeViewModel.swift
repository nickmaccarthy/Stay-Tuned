//
//  MetronomeViewModel.swift
//  Stay Tuned
//
//  Created for Phase 6: Metronome
//

import Combine
import SwiftUI

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
    private let maxTapCount = 4
    private let tapResetInterval: TimeInterval = 2.0 // Reset if no tap for 2 seconds
    private var cancellables = Set<AnyCancellable>()

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

    /// Process a tap for tap tempo feature
    func tap() {
        let now = Date()

        // Reset if too long since last tap
        if let lastTap = tapTimes.last,
           now.timeIntervalSince(lastTap) > tapResetInterval {
            tapTimes.removeAll()
        }

        // Add new tap
        tapTimes.append(now)

        // Keep only the last N taps
        if tapTimes.count > maxTapCount {
            tapTimes.removeFirst()
        }

        // Need at least 2 taps to calculate tempo
        guard tapTimes.count >= 2 else { return }

        // Calculate average interval between taps
        var totalInterval: TimeInterval = 0
        for i in 1 ..< tapTimes.count {
            totalInterval += tapTimes[i].timeIntervalSince(tapTimes[i - 1])
        }
        let averageInterval = totalInterval / Double(tapTimes.count - 1)

        // Convert to BPM (60 seconds / interval)
        let calculatedBPM = 60.0 / averageInterval

        // Clamp to valid range
        tempo = max(40, min(240, calculatedBPM))
    }
}
