//
//  MetronomeEngineTests.swift
//  Stay TunedTests
//
//  Tests for MetronomeEngine audio functionality
//

import Testing
@testable import Stay_Tuned

struct MetronomeEngineTests {
    
    // MARK: - Initialization Tests
    
    @Test("Engine initializes without crash")
    func engineInitializes() {
        let engine = MetronomeEngine()
        #expect(engine.isPlaying == false)
    }
    
    @Test("Default tempo is 120 BPM")
    func defaultTempo() {
        let engine = MetronomeEngine()
        #expect(engine.tempo == 120)
    }
    
    @Test("Default time signature is 4/4")
    func defaultTimeSignature() {
        let engine = MetronomeEngine()
        #expect(engine.timeSignature == .fourFour)
    }
    
    @Test("Default volume is 0.7")
    func defaultVolume() {
        let engine = MetronomeEngine()
        #expect(engine.volume == 0.7)
    }
    
    // MARK: - Tempo Tests
    
    @Test("Set tempo updates value")
    func setTempoUpdatesValue() {
        let engine = MetronomeEngine()
        engine.setTempo(100)
        #expect(engine.tempo == 100)
    }
    
    @Test("Set tempo clamps to minimum 40 BPM")
    func setTempoMinimum() {
        let engine = MetronomeEngine()
        engine.setTempo(20)
        #expect(engine.tempo == 40)
    }
    
    @Test("Set tempo clamps to maximum 240 BPM")
    func setTempoMaximum() {
        let engine = MetronomeEngine()
        engine.setTempo(300)
        #expect(engine.tempo == 240)
    }
    
    // MARK: - Time Signature Tests
    
    @Test("Set time signature updates value")
    func setTimeSignatureUpdatesValue() {
        let engine = MetronomeEngine()
        
        engine.setTimeSignature(.threeFour)
        #expect(engine.timeSignature == .threeFour)
        
        engine.setTimeSignature(.sixEight)
        #expect(engine.timeSignature == .sixEight)
    }
    
    // MARK: - Volume Tests
    
    @Test("Volume can be set")
    func volumeCanBeSet() {
        let engine = MetronomeEngine()
        engine.volume = 0.5
        #expect(engine.volume == 0.5)
        
        engine.volume = 1.0
        #expect(engine.volume == 1.0)
    }
    
    // MARK: - Playback State Tests
    
    @Test("Start sets isPlaying to true")
    func startSetsPlaying() {
        let engine = MetronomeEngine()
        engine.start()
        #expect(engine.isPlaying == true)
        engine.stop() // Clean up
    }
    
    @Test("Stop sets isPlaying to false")
    func stopSetsNotPlaying() {
        let engine = MetronomeEngine()
        engine.start()
        engine.stop()
        #expect(engine.isPlaying == false)
    }
    
    @Test("Start when already playing does nothing")
    func startWhenAlreadyPlaying() {
        let engine = MetronomeEngine()
        engine.start()
        engine.start() // Should not crash or change state
        #expect(engine.isPlaying == true)
        engine.stop() // Clean up
    }
    
    @Test("Stop when not playing does nothing")
    func stopWhenNotPlaying() {
        let engine = MetronomeEngine()
        engine.stop() // Should not crash
        #expect(engine.isPlaying == false)
    }
    
    // MARK: - Callback Tests
    
    @Test("OnBeat callback can be set")
    func onBeatCallbackCanBeSet() {
        let engine = MetronomeEngine()
        var callbackCalled = false
        
        engine.onBeat = { _ in
            callbackCalled = true
        }
        
        #expect(engine.onBeat != nil)
    }
}

