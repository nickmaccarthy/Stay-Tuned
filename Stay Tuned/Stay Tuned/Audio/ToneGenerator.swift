//
//  ToneGenerator.swift
//  Stay Tuned
//
//  Supports both pure sine wave and Karplus-Strong physical modeling synthesis
//

import AVFoundation
import Foundation

/// Generates reference tones for tuning
///
/// Supports two synthesis modes:
/// - **Sine Wave**: Pure, clean tone ideal for precise tuning
/// - **Plucked String (Karplus-Strong)**: Realistic guitar-like sound
final class ToneGenerator {
    
    // MARK: - Properties
    
    private var audioEngine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    
    private(set) var isPlaying = false
    private(set) var currentFrequency: Double = 0
    
    /// The current tone type (sine or string)
    var toneType: ToneType = .string
    
    // Sine wave phase
    private var sinePhase: Double = 0
    
    // Karplus-Strong delay line (circular buffer)
    private var delayBuffer: [Float] = []
    private var bufferIndex: Int = 0
    
    // Synthesis parameters
    private var isFadingOut = false
    private var fadeOutGain: Float = 1.0
    
    // Sine wave envelope
    private var sineEnvelopeGain: Float = 0
    private var sineEnvelopeTarget: Float = 1.0
    
    // Tunable parameters for Karplus-Strong
    // decayFactor: Controls sustain (0.99 = short, 0.999 = long)
    private let decayFactor: Float = 0.997
    
    // brightnessBlend: Low-pass filter balance (0 = mellow/warm, 1 = bright/harsh)
    private let brightnessBlend: Float = 0.35
    
    // Output volume
    private let outputGain: Float = 0.85
    private let sineOutputGain: Float = 0.7  // Sine is perceived louder, so slightly lower
    
    // Fade durations in seconds
    private let fadeInDuration: Double = 0.02   // 20ms fade in for sine
    private let fadeOutDuration: Double = 0.15  // 150ms fade out
    
    // Store sample rate for calculations
    private var sampleRate: Double = 48000
    
    // MARK: - Public Methods
    
    /// Start playing a tone at the specified frequency
    /// If already playing the same note with string type, "re-pluck" by refilling the buffer
    func play(frequency: Double) {
        // If already playing same note with string type, re-pluck
        if isPlaying && !isFadingOut && currentFrequency == frequency && toneType == .string {
            initializeDelayBuffer(for: frequency, sampleRate: sampleRate)
            return
        }
        
        // Cancel fade out if in progress
        if isFadingOut {
            stopImmediate()
        }
        
        currentFrequency = frequency
        isFadingOut = false
        fadeOutGain = 1.0
        sinePhase = 0
        sineEnvelopeGain = 0
        sineEnvelopeTarget = 1.0
        
        setupAudioEngine()
        
        do {
            try audioEngine?.start()
            isPlaying = true
        } catch {
            print("ToneGenerator: Failed to start - \(error.localizedDescription)")
            isPlaying = false
        }
    }
    
    /// Stop playing with smooth fade out
    func stop() {
        guard isPlaying, !isFadingOut else { return }
        
        isFadingOut = true
        sineEnvelopeTarget = 0
        
        // Poll until amplitude reaches zero, then stop
        checkAndStop()
    }
    
    // MARK: - Karplus-Strong Core
    
    /// Initialize the delay buffer with noise for the "pluck" excitation
    /// Buffer length determines the pitch: N = sampleRate / frequency
    func initializeDelayBuffer(for frequency: Double, sampleRate: Double) {
        // Buffer length determines pitch: N = sampleRate / frequency
        let bufferLength = max(2, Int(sampleRate / frequency))
        
        // Fill with band-limited noise for natural pluck sound
        // Use pink-ish noise (low-pass filtered) for warmer tone
        delayBuffer = (0..<bufferLength).map { _ in
            Float.random(in: -0.5...0.5)
        }
        
        // Simple low-pass to make noise warmer (reduce high frequency content)
        for i in 1..<bufferLength {
            delayBuffer[i] = 0.6 * delayBuffer[i] + 0.4 * delayBuffer[i - 1]
        }
        
        // Apply short attack envelope to noise for softer pluck transient
        let attackSamples = min(bufferLength / 4, 60)
        for i in 0..<attackSamples {
            let envelope = Float(i) / Float(attackSamples)
            delayBuffer[i] *= envelope
        }
        
        bufferIndex = 0
    }
    
    /// Calculate the expected delay buffer length for a given frequency
    /// Exposed for testing
    func calculateBufferLength(for frequency: Double, sampleRate: Double) -> Int {
        return max(2, Int(sampleRate / frequency))
    }
    
    // MARK: - Private Methods
    
    private func checkAndStop() {
        guard isFadingOut else { return }
        
        // Check if fade out is complete
        let fadeComplete = toneType == .sine ? sineEnvelopeGain <= 0.001 : fadeOutGain <= 0.001
        if fadeComplete {
            stopImmediate()
        } else {
            // Check again shortly
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { [weak self] in
                self?.checkAndStop()
            }
        }
    }
    
    private func stopImmediate() {
        audioEngine?.stop()
        sourceNode = nil
        audioEngine = nil
        isPlaying = false
        isFadingOut = false
        fadeOutGain = 1.0
        sineEnvelopeGain = 0
        sineEnvelopeTarget = 1.0
        delayBuffer.removeAll()
        bufferIndex = 0
        sinePhase = 0
    }
    
    private func setupAudioEngine() {
        // Configure audio session for playback
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("ToneGenerator: Audio session setup failed - \(error.localizedDescription)")
        }
        
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        let mainMixer = audioEngine.mainMixerNode
        mainMixer.outputVolume = 1.0
        let outputFormat = mainMixer.outputFormat(forBus: 0)
        sampleRate = outputFormat.sampleRate
        
        // Initialize based on tone type
        if toneType == .string {
            initializeDelayBuffer(for: currentFrequency, sampleRate: sampleRate)
        }
        
        // Capture tone type to avoid accessing self.toneType in audio thread
        let useSineWave = toneType == .sine
        
        // Create source node for real-time synthesis
        sourceNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            
            if useSineWave {
                // Sine wave synthesis
                self.generateSineWave(frameCount: frameCount, ablPointer: ablPointer)
            } else {
                // Karplus-Strong synthesis
                self.generateKarplusStrong(frameCount: frameCount, ablPointer: ablPointer)
            }
            
            return noErr
        }
        
        guard let sourceNode = sourceNode else { return }
        
        audioEngine.attach(sourceNode)
        audioEngine.connect(sourceNode, to: mainMixer, format: outputFormat)
    }
    
    // MARK: - Sine Wave Generation
    
    private func generateSineWave(frameCount: UInt32, ablPointer: UnsafeMutableAudioBufferListPointer) {
        let twoPi = 2.0 * Double.pi
        let fadeInRate = Float(1.0 / (fadeInDuration * sampleRate))
        let fadeOutRate = Float(1.0 / (fadeOutDuration * sampleRate))
        
        for frame in 0..<Int(frameCount) {
            // Smooth envelope transition
            if sineEnvelopeGain < sineEnvelopeTarget {
                sineEnvelopeGain = min(sineEnvelopeGain + fadeInRate, sineEnvelopeTarget)
            } else if sineEnvelopeGain > sineEnvelopeTarget {
                sineEnvelopeGain = max(sineEnvelopeGain - fadeOutRate, sineEnvelopeTarget)
            }
            
            // Generate sine wave sample
            let sample = Float(sin(sinePhase)) * sineEnvelopeGain * sineOutputGain
            
            // Advance phase
            sinePhase += twoPi * currentFrequency / sampleRate
            if sinePhase >= twoPi {
                sinePhase -= twoPi
            }
            
            // Write to all channels
            for buffer in ablPointer {
                let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                buf[frame] = sample
            }
        }
    }
    
    // MARK: - Karplus-Strong Generation
    
    private func generateKarplusStrong(frameCount: UInt32, ablPointer: UnsafeMutableAudioBufferListPointer) {
        guard !delayBuffer.isEmpty else { return }
        
        let bufferSize = delayBuffer.count
        
        for frame in 0..<Int(frameCount) {
            // Read current sample from delay line
            let currentSample = delayBuffer[bufferIndex]
            
            // Get next sample for averaging (wrap around)
            let nextIndex = (bufferIndex + 1) % bufferSize
            let nextSample = delayBuffer[nextIndex]
            
            // Low-pass filter: weighted average of current and next sample
            let filtered = brightnessBlend * currentSample +
                           (1 - brightnessBlend) * nextSample
            
            // Apply decay factor and feed back into delay line
            delayBuffer[bufferIndex] = filtered * decayFactor
            
            // Advance buffer index (circular)
            bufferIndex = nextIndex
            
            // Apply fade out if stopping
            var outputSample = currentSample * outputGain
            if isFadingOut {
                outputSample *= fadeOutGain
                fadeOutGain = max(0, fadeOutGain - Float(1.0 / (fadeOutDuration * sampleRate)))
            }
            
            // Write to all channels
            for buffer in ablPointer {
                let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                buf[frame] = outputSample
            }
        }
    }
    
    deinit {
        stopImmediate()
    }
}
