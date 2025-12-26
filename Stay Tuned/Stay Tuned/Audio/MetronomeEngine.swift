//
//  MetronomeEngine.swift
//  Stay Tuned
//
//  Created for Phase 6: Metronome
//

import AVFoundation
import Foundation

/// Audio engine for metronome with sample-accurate beat scheduling
final class MetronomeEngine {
    
    // MARK: - Properties
    
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    
    private var regularClickBuffer: AVAudioPCMBuffer?
    private var accentClickBuffer: AVAudioPCMBuffer?
    
    private(set) var isPlaying = false
    private(set) var tempo: Double = 120
    private(set) var timeSignature: TimeSignature = .fourFour
    
    private var currentBeat: Int = 0
    private var nextBeatTime: AVAudioTime?
    
    /// Callback fired on each beat with the current beat number (1-indexed)
    var onBeat: ((Int) -> Void)?
    
    // Audio parameters
    private let sampleRate: Double = 44100
    private let regularClickFrequency: Double = 1000  // Hz
    private let accentClickFrequency: Double = 1500   // Hz
    private let clickDuration: Double = 0.015         // 15ms click
    
    // Volume control
    var volume: Float = 0.7 {
        didSet {
            playerNode?.volume = volume
        }
    }
    
    // MARK: - Initialization
    
    init() {
        generateClickBuffers()
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Public Methods
    
    /// Start the metronome
    func start() {
        guard !isPlaying else { return }
        
        setupAudioEngine()
        
        do {
            try audioEngine?.start()
            isPlaying = true
            currentBeat = 0
            scheduleNextBeat()
        } catch {
            print("MetronomeEngine: Failed to start - \(error.localizedDescription)")
            isPlaying = false
        }
    }
    
    /// Stop the metronome
    func stop() {
        guard isPlaying else { return }
        
        isPlaying = false
        playerNode?.stop()
        audioEngine?.stop()
        audioEngine = nil
        playerNode = nil
        currentBeat = 0
        nextBeatTime = nil
    }
    
    /// Update the tempo (can be called while playing)
    func setTempo(_ bpm: Double) {
        tempo = max(40, min(240, bpm))
    }
    
    /// Update the time signature
    func setTimeSignature(_ signature: TimeSignature) {
        timeSignature = signature
        // Reset beat counter if we're past the new beat count
        if currentBeat >= signature.beatsPerMeasure {
            currentBeat = 0
        }
    }
    
    // MARK: - Private Methods
    
    private func generateClickBuffers() {
        // Generate regular click (1000 Hz)
        regularClickBuffer = generateClickBuffer(frequency: regularClickFrequency, amplitude: 0.8)
        
        // Generate accent click (1500 Hz, slightly louder)
        accentClickBuffer = generateClickBuffer(frequency: accentClickFrequency, amplitude: 1.0)
    }
    
    private func generateClickBuffer(frequency: Double, amplitude: Float) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(clickDuration * sampleRate)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        
        buffer.frameLength = frameCount
        
        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else {
            return nil
        }
        
        let twoPi = 2.0 * Double.pi
        let angularFrequency = twoPi * frequency / sampleRate
        
        for frame in 0..<Int(frameCount) {
            // Sine wave
            let sine = Float(sin(angularFrequency * Double(frame)))
            
            // Apply envelope to avoid clicks (quick attack, quick release)
            let position = Double(frame) / Double(frameCount)
            let envelope: Float
            
            if position < 0.05 {
                // Attack (first 5%)
                envelope = Float(position / 0.05)
            } else if position > 0.7 {
                // Release (last 30%)
                envelope = Float((1.0 - position) / 0.3)
            } else {
                envelope = 1.0
            }
            
            let sample = sine * amplitude * envelope
            leftChannel[frame] = sample
            rightChannel[frame] = sample
        }
        
        return buffer
    }
    
    private func setupAudioEngine() {
        // Configure audio session for playback
        do {
            let session = AVAudioSession.sharedInstance()
            // Use playback category with default speaker
            try session.setCategory(.playback, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("MetronomeEngine: Audio session setup failed - \(error.localizedDescription)")
        }
        
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        
        guard let audioEngine = audioEngine,
              let playerNode = playerNode else { return }
        
        audioEngine.attach(playerNode)
        
        let mainMixer = audioEngine.mainMixerNode
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        
        audioEngine.connect(playerNode, to: mainMixer, format: format)
        
        playerNode.volume = volume
    }
    
    private func scheduleNextBeat() {
        guard isPlaying,
              let playerNode = playerNode,
              let audioEngine = audioEngine else { return }
        
        // Determine which buffer to play
        let isAccent = currentBeat == 0
        guard let buffer = isAccent ? accentClickBuffer : regularClickBuffer else { return }
        
        // Calculate samples per beat
        let samplesPerBeat = sampleRate * 60.0 / tempo
        
        // Fire callback on main thread immediately
        let beatNumber = currentBeat + 1  // 1-indexed for display
        DispatchQueue.main.async { [weak self] in
            self?.onBeat?(beatNumber)
        }
        
        if nextBeatTime == nil {
            // First beat - schedule immediately (nil time = play now)
            playerNode.scheduleBuffer(buffer, at: nil, options: []) { [weak self] in
                self?.beatCompleted()
            }
            
            // Start playing
            playerNode.play()
            
            // Set up next beat time based on player's current time
            if let nodeTime = playerNode.lastRenderTime,
               let playerTime = playerNode.playerTime(forNodeTime: nodeTime) {
                let nextSampleTime = playerTime.sampleTime + AVAudioFramePosition(samplesPerBeat)
                nextBeatTime = AVAudioTime(sampleTime: nextSampleTime, atRate: sampleRate)
            }
        } else {
            guard let beatTime = nextBeatTime else { return }
            
            // Schedule the buffer at the calculated time
            playerNode.scheduleBuffer(buffer, at: beatTime, options: []) { [weak self] in
                self?.beatCompleted()
            }
            
            // Calculate next beat time
            let nextSampleTime = beatTime.sampleTime + AVAudioFramePosition(samplesPerBeat)
            nextBeatTime = AVAudioTime(sampleTime: nextSampleTime, atRate: sampleRate)
        }
    }
    
    private func beatCompleted() {
        guard isPlaying else { return }
        
        // Advance to next beat
        currentBeat = (currentBeat + 1) % timeSignature.beatsPerMeasure
        
        // Schedule next beat
        scheduleNextBeat()
    }
}

