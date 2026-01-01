//
//  ToneGenerator.swift
//  Stay Tuned
//
//  Supports both harmonic-enriched sine wave and extended Karplus-Strong synthesis
//

import AVFoundation
import Foundation

/// Generates reference tones for tuning
///
/// Supports two synthesis modes:
/// - **Sine Wave**: Harmonic-enriched tone for better audibility on phone speakers
/// - **Plucked String (Karplus-Strong)**: Realistic guitar-like sound with body resonance
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

    // MARK: - Sine Wave Parameters

    /// Harmonic amplitudes for enriched sine wave (relative to fundamental)
    /// These overtones make low frequencies audible on phone speakers
    // let sineHarmonic2Amplitude: Float = 0.5   // 2nd harmonic (octave above)
    // let sineHarmonic3Amplitude: Float = 0.35  // 3rd harmonic
    // let sineHarmonic4Amplitude: Float = 0.25  // 4th harmonic (2 octaves above)
    let sineHarmonic2Amplitude: Float = 1 // 2nd harmonic (octave above)
    let sineHarmonic3Amplitude: Float = 0.70 // 3rd harmonic
    let sineHarmonic4Amplitude: Float = 0.50 // 4th harmonic (2 octaves above)

    /// Normalization factor for combined harmonics (sum of all amplitudes)
    private var sineNormalizationFactor: Float {
        1.0 + sineHarmonic2Amplitude + sineHarmonic3Amplitude + sineHarmonic4Amplitude
    }

    /// Base output gain for sine wave (increased from 0.7)
    private let sineOutputGain: Float = 0.95

    /// Frequency threshold below which extra gain boost is applied
    let lowFrequencyThreshold: Double = 200.0

    /// Maximum frequency boost multiplier for low frequencies
    let maxFrequencyBoost: Float = 1.7

    // MARK: - Karplus-Strong Parameters

    /// Decay factor: Controls sustain (0.99 = short, 0.999 = long)
    private let decayFactor: Float = 0.997

    /// Brightness blend: Low-pass filter balance (0 = mellow/warm, 1 = bright/harsh)
    /// Reduced from 0.35 to 0.25 for warmer guitar-like tone
    private let brightnessBlend: Float = 0.25

    /// Output volume for plucked string (increased from 0.85)
    private let outputGain: Float = 0.95

    /// Pick position: 0.5 = middle of string (warmer), closer to 0 = near bridge (brighter)
    /// 0.35 gives a natural acoustic guitar sound
    let pickPosition: Float = 0.35

    /// Body resonance amount (subtle warmth simulation)
    let bodyResonance: Float = 0.15

    /// Body resonance filter state
    private var bodyResonanceState: Float = 0

    /// Frequency threshold for low-frequency harmonic boost
    let stringLowFreqThreshold: Double = 150.0

    /// Very low frequency threshold - needs extra harmonics (C, D strings)
    let stringVeryLowFreqThreshold: Double = 100.0

    /// Harmonic boost amount for 2x frequency
    let stringHarmonicBoost2x: Float = 0.5

    /// Harmonic boost amount for 3x frequency (very low strings only)
    let stringHarmonicBoost3x: Float = 0.7

    /// Harmonic boost amount for 4x frequency (very low strings only)
    let stringHarmonicBoost4x: Float = 0.5

    /// Phase for low-frequency harmonic generation (2x)
    private var lowFreqHarmonicPhase2x: Double = 0

    /// Phase for low-frequency harmonic generation (3x)
    private var lowFreqHarmonicPhase3x: Double = 0

    /// Phase for low-frequency harmonic generation (4x)
    private var lowFreqHarmonicPhase4x: Double = 0

    // MARK: - Common Parameters

    /// Fade durations in seconds
    private let fadeInDuration: Double = 0.02 // 20ms fade in for sine
    private let fadeOutDuration: Double = 0.05 // 50ms fade out

    /// Store sample rate for calculations
    private var sampleRate: Double = 48000

    // MARK: - Public Methods

    /// Start playing a tone at the specified frequency
    /// If already playing the same note with string type, "re-pluck" by refilling the buffer
    func play(frequency: Double) {
        // If already playing same note with string type, re-pluck
        if isPlaying, !isFadingOut, currentFrequency == frequency, toneType == .string {
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
        bodyResonanceState = 0
        lowFreqHarmonicPhase2x = 0
        lowFreqHarmonicPhase3x = 0
        lowFreqHarmonicPhase4x = 0

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
        delayBuffer = (0 ..< bufferLength).map { _ in
            Float.random(in: -0.5 ... 0.5)
        }

        // First pass: aggressive low-pass to make noise warmer
        // (increased from 0.6/0.4 to 0.4/0.6 for more warmth)
        for idx in 1 ..< bufferLength {
            delayBuffer[idx] = 0.4 * delayBuffer[idx] + 0.6 * delayBuffer[idx - 1]
        }

        // Second pass: additional smoothing for even warmer tone
        for idx in 1 ..< bufferLength {
            delayBuffer[idx] = 0.5 * delayBuffer[idx] + 0.5 * delayBuffer[idx - 1]
        }

        // Apply pick position simulation using comb filter
        // This removes harmonics at multiples of (1/pickPosition) for more natural timbre
        let pickDelay = max(1, Int(Float(bufferLength) * pickPosition))
        for idx in pickDelay ..< bufferLength {
            delayBuffer[idx] -= delayBuffer[idx - pickDelay] * 0.5
        }

        // Apply short attack envelope to noise for softer pluck transient
        let attackSamples = min(bufferLength / 4, 60)
        for idx in 0 ..< attackSamples {
            let envelope = Float(idx) / Float(attackSamples)
            delayBuffer[idx] *= envelope
        }

        bufferIndex = 0
        bodyResonanceState = 0
    }

    /// Calculate the expected delay buffer length for a given frequency
    /// Exposed for testing
    func calculateBufferLength(for frequency: Double, sampleRate: Double) -> Int {
        max(2, Int(sampleRate / frequency))
    }

    /// Calculate frequency-dependent gain boost for low frequencies
    /// Exposed for testing
    func calculateFrequencyBoost(for frequency: Double) -> Float {
        Float(min(Double(maxFrequencyBoost), max(1.0, lowFrequencyThreshold / frequency)))
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
        bodyResonanceState = 0
        lowFreqHarmonicPhase2x = 0
        lowFreqHarmonicPhase3x = 0
        lowFreqHarmonicPhase4x = 0
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
        guard let audioEngine else { return }

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
            guard let self else { return noErr }

            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)

            if useSineWave {
                // Sine wave synthesis with harmonics
                self.generateSineWave(frameCount: frameCount, ablPointer: ablPointer)
            } else {
                // Extended Karplus-Strong synthesis
                self.generateKarplusStrong(frameCount: frameCount, ablPointer: ablPointer)
            }

            return noErr
        }

        guard let sourceNode else { return }

        audioEngine.attach(sourceNode)
        audioEngine.connect(sourceNode, to: mainMixer, format: outputFormat)
    }

    // MARK: - Sine Wave Generation

    private func generateSineWave(frameCount: UInt32, ablPointer: UnsafeMutableAudioBufferListPointer) {
        let twoPi = 2.0 * Double.pi
        let fadeInRate = Float(1.0 / (fadeInDuration * sampleRate))
        let fadeOutRate = Float(1.0 / (fadeOutDuration * sampleRate))

        // Calculate frequency-dependent boost for low frequencies
        let frequencyBoost = calculateFrequencyBoost(for: currentFrequency)

        // For very low frequencies, add even more upper harmonics
        let isVeryLowFreq = currentFrequency < stringVeryLowFreqThreshold

        for frame in 0 ..< Int(frameCount) {
            // Smooth envelope transition
            if sineEnvelopeGain < sineEnvelopeTarget {
                sineEnvelopeGain = min(sineEnvelopeGain + fadeInRate, sineEnvelopeTarget)
            } else if sineEnvelopeGain > sineEnvelopeTarget {
                sineEnvelopeGain = max(sineEnvelopeGain - fadeOutRate, sineEnvelopeTarget)
            }

            // Generate fundamental + harmonics for phone speaker audibility
            // The brain perceives the fundamental even when mainly hearing harmonics
            let fundamental = Float(sin(sinePhase))
            let harmonic2 = Float(sin(sinePhase * 2)) * sineHarmonic2Amplitude
            let harmonic3 = Float(sin(sinePhase * 3)) * sineHarmonic3Amplitude
            let harmonic4 = Float(sin(sinePhase * 4)) * sineHarmonic4Amplitude

            var combined = (fundamental + harmonic2 + harmonic3 + harmonic4) / sineNormalizationFactor

            // For very low frequencies (below 100Hz), add 5th and 6th harmonics
            // These are the frequencies phone speakers can actually reproduce
            if isVeryLowFreq {
                let harmonic5 = Float(sin(sinePhase * 5)) * 0.4
                let harmonic6 = Float(sin(sinePhase * 6)) * 0.3
                // Add extra harmonics with additional normalization
                combined += (harmonic5 + harmonic6) / 2.0
            }

            // Apply envelope, frequency boost, and output gain
            let sample = combined * sineEnvelopeGain * sineOutputGain * frequencyBoost

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
        let twoPi = 2.0 * Double.pi
        let needsHarmonicBoost = currentFrequency < stringLowFreqThreshold
        let isVeryLowFreq = currentFrequency < stringVeryLowFreqThreshold

        for frame in 0 ..< Int(frameCount) {
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

            // Apply body resonance simulation (simple one-pole filter)
            let withResonance = currentSample + bodyResonanceState * bodyResonance
            bodyResonanceState = withResonance * 0.95 // Slight decay to prevent buildup

            var outputSample = withResonance * outputGain

            // Add harmonic boost for low strings (below 150 Hz) to improve phone speaker audibility
            if needsHarmonicBoost {
                let sampleAmplitude = abs(currentSample)

                // Generate 2x harmonic (octave above)
                let harmonic2x = Float(sin(lowFreqHarmonicPhase2x)) * stringHarmonicBoost2x * sampleAmplitude
                outputSample += harmonic2x

                // Advance 2x harmonic phase
                lowFreqHarmonicPhase2x += twoPi * currentFrequency * 2.0 / sampleRate
                if lowFreqHarmonicPhase2x >= twoPi {
                    lowFreqHarmonicPhase2x -= twoPi
                }

                // For very low frequencies (below 100Hz like C, D), add 3x and 4x harmonics
                // These are the frequencies phone speakers can actually reproduce
                if isVeryLowFreq {
                    // Generate 3x harmonic
                    let harmonic3x = Float(sin(lowFreqHarmonicPhase3x)) * stringHarmonicBoost3x * sampleAmplitude
                    outputSample += harmonic3x

                    // Generate 4x harmonic
                    let harmonic4x = Float(sin(lowFreqHarmonicPhase4x)) * stringHarmonicBoost4x * sampleAmplitude
                    outputSample += harmonic4x

                    // Advance 3x harmonic phase
                    lowFreqHarmonicPhase3x += twoPi * currentFrequency * 3.0 / sampleRate
                    if lowFreqHarmonicPhase3x >= twoPi {
                        lowFreqHarmonicPhase3x -= twoPi
                    }

                    // Advance 4x harmonic phase
                    lowFreqHarmonicPhase4x += twoPi * currentFrequency * 4.0 / sampleRate
                    if lowFreqHarmonicPhase4x >= twoPi {
                        lowFreqHarmonicPhase4x -= twoPi
                    }
                }
            }

            // Apply fade out if stopping
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
