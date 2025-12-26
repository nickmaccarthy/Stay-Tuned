//
//  MetronomeViewModelTests.swift
//  Stay TunedTests
//
//  Tests for MetronomeViewModel logic
//

import Testing
@testable import Stay_Tuned

@MainActor
struct MetronomeViewModelTests {
    
    // MARK: - Initialization Tests
    
    @Test("Default tempo is 120 BPM")
    func defaultTempo() {
        let viewModel = MetronomeViewModel()
        #expect(viewModel.tempo == 120)
    }
    
    @Test("Default time signature is 4/4")
    func defaultTimeSignature() {
        let viewModel = MetronomeViewModel()
        #expect(viewModel.timeSignature == .fourFour)
    }
    
    @Test("Default playing state is false")
    func defaultPlayingState() {
        let viewModel = MetronomeViewModel()
        #expect(viewModel.isPlaying == false)
    }
    
    @Test("Default current beat is 1")
    func defaultCurrentBeat() {
        let viewModel = MetronomeViewModel()
        #expect(viewModel.currentBeat == 1)
    }
    
    @Test("Default volume is 0.7")
    func defaultVolume() {
        let viewModel = MetronomeViewModel()
        #expect(viewModel.volume == 0.7)
    }
    
    // MARK: - Tempo Clamping Tests
    
    @Test("Tempo increment respects maximum of 240 BPM")
    func tempoIncrementMaximum() {
        let viewModel = MetronomeViewModel()
        viewModel.tempo = 239
        viewModel.incrementTempo()
        #expect(viewModel.tempo == 240)
        
        // Try to increment past max
        viewModel.incrementTempo()
        #expect(viewModel.tempo == 240)
    }
    
    @Test("Tempo decrement respects minimum of 40 BPM")
    func tempoDecrementMinimum() {
        let viewModel = MetronomeViewModel()
        viewModel.tempo = 41
        viewModel.decrementTempo()
        #expect(viewModel.tempo == 40)
        
        // Try to decrement past min
        viewModel.decrementTempo()
        #expect(viewModel.tempo == 40)
    }
    
    @Test("Increment tempo adds 1 BPM")
    func incrementTempoAddsOne() {
        let viewModel = MetronomeViewModel()
        let initialTempo = viewModel.tempo
        viewModel.incrementTempo()
        #expect(viewModel.tempo == initialTempo + 1)
    }
    
    @Test("Decrement tempo subtracts 1 BPM")
    func decrementTempoSubtractsOne() {
        let viewModel = MetronomeViewModel()
        let initialTempo = viewModel.tempo
        viewModel.decrementTempo()
        #expect(viewModel.tempo == initialTempo - 1)
    }
    
    // MARK: - Time Signature Change Tests
    
    @Test("Changing time signature updates beats per measure")
    func changingTimeSignatureUpdatesBeatCount() {
        let viewModel = MetronomeViewModel()
        
        viewModel.timeSignature = .threeFour
        #expect(viewModel.timeSignature.beatsPerMeasure == 3)
        
        viewModel.timeSignature = .sixEight
        #expect(viewModel.timeSignature.beatsPerMeasure == 6)
        
        viewModel.timeSignature = .twoFour
        #expect(viewModel.timeSignature.beatsPerMeasure == 2)
    }
    
    // MARK: - Playback State Tests
    
    @Test("Toggle playback changes playing state")
    func togglePlaybackChangesState() {
        let viewModel = MetronomeViewModel()
        #expect(viewModel.isPlaying == false)
        
        viewModel.togglePlayback()
        #expect(viewModel.isPlaying == true)
        
        viewModel.togglePlayback()
        #expect(viewModel.isPlaying == false)
    }
    
    @Test("Start sets playing to true")
    func startSetsPlayingTrue() {
        let viewModel = MetronomeViewModel()
        viewModel.start()
        #expect(viewModel.isPlaying == true)
        viewModel.stop() // Clean up
    }
    
    @Test("Stop sets playing to false")
    func stopSetsPlayingFalse() {
        let viewModel = MetronomeViewModel()
        viewModel.start()
        viewModel.stop()
        #expect(viewModel.isPlaying == false)
    }
    
    @Test("Stop resets current beat to 1")
    func stopResetsCurrentBeat() {
        let viewModel = MetronomeViewModel()
        viewModel.start()
        viewModel.stop()
        #expect(viewModel.currentBeat == 1)
    }
    
    // MARK: - Tap Tempo Tests
    
    @Test("Single tap does not change tempo")
    func singleTapNoChange() {
        let viewModel = MetronomeViewModel()
        let initialTempo = viewModel.tempo
        viewModel.tap()
        #expect(viewModel.tempo == initialTempo)
    }
    
    @Test("Tap tempo with valid taps calculates BPM")
    func tapTempoCalculation() async throws {
        let viewModel = MetronomeViewModel()
        
        // Simulate tapping at 120 BPM (0.5 seconds apart)
        viewModel.tap()
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        viewModel.tap()
        
        // Should be approximately 120 BPM (±10 for timing variance)
        #expect(viewModel.tempo >= 110 && viewModel.tempo <= 130)
    }
    
    @Test("Tap tempo respects minimum of 40 BPM")
    func tapTempoMinimum() async throws {
        let viewModel = MetronomeViewModel()
        
        // Simulate very slow tapping (would be below 40 BPM)
        viewModel.tap()
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds (30 BPM)
        viewModel.tap()
        
        // Should be clamped to minimum 40 BPM
        #expect(viewModel.tempo >= 40)
    }
    
    // MARK: - Volume Tests
    
    @Test("Volume can be changed")
    func volumeCanBeChanged() {
        let viewModel = MetronomeViewModel()
        viewModel.volume = 0.5
        #expect(viewModel.volume == 0.5)
        
        viewModel.volume = 1.0
        #expect(viewModel.volume == 1.0)
        
        viewModel.volume = 0.0
        #expect(viewModel.volume == 0.0)
    }
}


