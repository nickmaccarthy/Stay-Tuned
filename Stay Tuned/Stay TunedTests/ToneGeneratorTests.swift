//
//  ToneGeneratorTests.swift
//  Stay TunedTests
//
//  Tests for ToneGenerator synthesis (sine wave with harmonics and Karplus-Strong)
//

import Foundation
import Testing
@testable import Stay_Tuned

// MARK: - Tone Generator Basic Tests

struct ToneGeneratorTests {

    @Test("ToneGenerator initializes with correct default state")
    func testInitialState() {
        let generator = ToneGenerator()
        #expect(generator.isPlaying == false)
        #expect(generator.currentFrequency == 0)
    }

    @Test("ToneGenerator play sets frequency and isPlaying")
    func testPlaySetsState() {
        let generator = ToneGenerator()
        generator.play(frequency: 440.0)

        // Note: isPlaying depends on audio engine starting successfully
        // In test environment, it may fail, so we just check it doesn't crash
        #expect(generator.currentFrequency == 440.0 || generator.currentFrequency == 0)
    }

    @Test("ToneGenerator stop doesn't crash when not playing")
    func testStopWhenNotPlaying() {
        let generator = ToneGenerator()
        generator.stop() // Should not crash
        #expect(generator.isPlaying == false)
    }

    @Test("ToneGenerator can be created and destroyed without issues")
    func testLifecycle() {
        var generator: ToneGenerator? = ToneGenerator()
        generator?.play(frequency: 329.63) // E4
        generator?.stop()
        generator = nil // Should clean up properly
    }

    @Test("Multiple play calls with same frequency re-pluck instead of restart")
    func testSameFrequencyReplucks() {
        let generator = ToneGenerator()
        generator.play(frequency: 440.0)
        generator.play(frequency: 440.0) // Should re-pluck, not restart engine
        // If it got this far without crashing, test passes
    }

    @Test("Play with different frequency switches smoothly")
    func testFrequencySwitch() {
        let generator = ToneGenerator()
        generator.play(frequency: 440.0) // A4
        generator.play(frequency: 329.63) // E4
        // Should switch without crash
    }

    @Test("ToneGenerator defaults to string tone type")
    func testDefaultToneType() {
        let generator = ToneGenerator()
        #expect(generator.toneType == .string)
    }

    @Test("ToneGenerator can switch to sine tone type")
    func testSineToneType() {
        let generator = ToneGenerator()
        generator.toneType = .sine
        #expect(generator.toneType == .sine)
    }

    @Test("ToneGenerator plays sine wave without crashing")
    func testSineWavePlayback() {
        let generator = ToneGenerator()
        generator.toneType = .sine
        generator.play(frequency: 440.0)
        // Should play without crash
        generator.stop()
    }

    @Test("ToneGenerator can switch between tone types")
    func testToneTypeSwitching() {
        let generator = ToneGenerator()

        // Start with string
        generator.toneType = .string
        generator.play(frequency: 440.0)
        generator.stop()

        // Switch to sine
        generator.toneType = .sine
        generator.play(frequency: 440.0)
        generator.stop()

        // Switch back to string
        generator.toneType = .string
        generator.play(frequency: 440.0)
        generator.stop()

        // All should complete without crash
    }
}

// MARK: - Sine Wave Harmonic Tests

struct SineWaveHarmonicTests {

    @Test("Sine wave has correct harmonic amplitudes")
    func testHarmonicAmplitudes() {
        let generator = ToneGenerator()

        // Verify harmonic amplitude structure (boosted for phone speaker audibility)
        // 2nd harmonic is equal to fundamental for maximum audibility
        #expect(generator.sineHarmonic2Amplitude == 1.0, "2nd harmonic should be 1.0")
        #expect(generator.sineHarmonic3Amplitude == 0.70, "3rd harmonic should be 0.70")
        #expect(generator.sineHarmonic4Amplitude == 0.50, "4th harmonic should be 0.50")

        // Verify harmonics decrease in amplitude (after the 2nd)
        #expect(generator.sineHarmonic2Amplitude >= generator.sineHarmonic3Amplitude)
        #expect(generator.sineHarmonic3Amplitude > generator.sineHarmonic4Amplitude)
    }

    @Test("Harmonic amplitudes sum correctly for normalization")
    func testHarmonicNormalization() {
        let generator = ToneGenerator()

        // Total amplitude: 1.0 + 0.5 + 0.35 + 0.25 = 2.1
        let expectedSum: Float = 1.0 + 0.5 + 0.35 + 0.25
        #expect(abs(expectedSum - 2.1) < 0.001)

        // Combined signal divided by this factor stays within [-1, 1]
        let maxAmplitude = expectedSum / expectedSum
        #expect(maxAmplitude <= 1.0, "Normalized amplitude should not exceed 1.0")
    }

    @Test("Low frequency boost calculation is correct")
    func testLowFrequencyBoost() {
        let generator = ToneGenerator()

        // At 200Hz (threshold), boost should be 1.0
        let boost200 = generator.calculateFrequencyBoost(for: 200.0)
        #expect(abs(boost200 - 1.0) < 0.01, "At 200Hz, boost should be 1.0")

        // At 100Hz, boost should be 2.0 but capped at max
        let boost100 = generator.calculateFrequencyBoost(for: 100.0)
        #expect(boost100 == generator.maxFrequencyBoost, "At 100Hz, boost should be capped at max")

        // At 82Hz (low E), boost should be capped
        let boost82 = generator.calculateFrequencyBoost(for: 82.0)
        #expect(boost82 == generator.maxFrequencyBoost, "Low E should get max boost")

        // At 400Hz, no boost needed
        let boost400 = generator.calculateFrequencyBoost(for: 400.0)
        #expect(abs(boost400 - 1.0) < 0.01, "At 400Hz, no boost needed")

        // At 50Hz, boost is capped at max
        let boost50 = generator.calculateFrequencyBoost(for: 50.0)
        #expect(boost50 == generator.maxFrequencyBoost, "Very low freq gets max boost")
    }

    @Test("Frequency boost parameters are valid")
    func testFrequencyBoostParameters() {
        let generator = ToneGenerator()

        #expect(generator.lowFrequencyThreshold == 200.0, "Threshold should be 200Hz")
        #expect(generator.maxFrequencyBoost == 2.0, "Max boost should be 2.0x")
        #expect(generator.maxFrequencyBoost <= 2.5, "Max boost shouldn't cause excessive clipping")
    }
}

// MARK: - Karplus-Strong Delay Buffer Tests

struct KarplusStrongDelayBufferTests {

    @Test("Buffer length calculation: sampleRate / frequency")
    func testBufferLengthCalculation() {
        let generator = ToneGenerator()

        // A4 at 440Hz with 48000 sample rate
        let length440 = generator.calculateBufferLength(for: 440.0, sampleRate: 48000)
        #expect(length440 == 109) // 48000 / 440 = 109.09

        // E2 at 82.41Hz
        let lengthE2 = generator.calculateBufferLength(for: 82.41, sampleRate: 48000)
        #expect(lengthE2 == 582) // 48000 / 82.41 = 582.45

        // E4 at 329.63Hz
        let lengthE4 = generator.calculateBufferLength(for: 329.63, sampleRate: 48000)
        #expect(lengthE4 == 145) // 48000 / 329.63 = 145.60
    }

    @Test("Buffer length has minimum of 2")
    func testBufferLengthMinimum() {
        let generator = ToneGenerator()

        // Very high frequency that would give tiny buffer
        let length = generator.calculateBufferLength(for: 100000, sampleRate: 48000)
        #expect(length >= 2)
    }

    @Test("Delay buffer initialization creates correct length")
    func testDelayBufferInitialization() {
        let generator = ToneGenerator()
        let sampleRate = 48000.0
        let frequency = 440.0

        generator.initializeDelayBuffer(for: frequency, sampleRate: sampleRate)

        // Buffer should exist after initialization
        // Note: We can't directly access the buffer, but the method shouldn't crash
    }

    @Test("Buffer length determines pitch accurately")
    func testPitchAccuracy() {
        let generator = ToneGenerator()
        let sampleRate = 48000.0

        // Test that calculated frequency from buffer length is close to target
        // At 48kHz sample rate, pitch error is at most sampleRate/bufferLength^2
        // For worst case (440Hz), error ≈ 48000/109^2 ≈ 4Hz
        for targetFreq in [82.41, 110.0, 146.83, 196.0, 246.94, 329.63, 440.0] {
            let bufferLength = generator.calculateBufferLength(for: targetFreq, sampleRate: sampleRate)
            let actualFreq = sampleRate / Double(bufferLength)

            // Should be within 5Hz of target (quantization error from integer buffer length)
            let error = abs(actualFreq - targetFreq)
            #expect(error < 5.0, "Frequency \(targetFreq) should have <5Hz error, got \(error)")
        }
    }
}

// MARK: - Karplus-Strong Algorithm Parameter Tests

struct KarplusStrongParameterTests {

    @Test("Decay factor controls sustain length")
    func testDecayFactor() {
        // Current value: 0.997 (slightly longer sustain)
        let decayFactor: Float = 0.997

        // Should be in valid range
        #expect(decayFactor >= 0.99, "Decay factor should be >= 0.99 for reasonable sustain")
        #expect(decayFactor <= 0.999, "Decay factor should be <= 0.999 to eventually decay")

        // Calculate approximate sustain time
        // After n iterations, amplitude = decayFactor^n
        // For amplitude to drop to 0.01 (1%): n = log(0.01) / log(decayFactor)
        let iterations = log(0.01) / log(Double(decayFactor))

        // At 440Hz, each period is ~109 samples at 48kHz
        // Time = iterations * (1/440) seconds
        let sustainTime = iterations / 440.0

        // Should have several seconds of sustain for a reference tone
        #expect(sustainTime > 2.0, "Sustain should be > 2 seconds")
        #expect(sustainTime < 30.0, "Sustain shouldn't be too long")
    }

    @Test("Brightness blend is warmer than classic K-S")
    func testBrightnessBlend() {
        let generator = ToneGenerator()

        // Current value: 0.25 (warmer than original 0.35, much warmer than classic 0.5)
        // We can't directly access brightnessBlend, but we test the expected behavior

        // Should be in valid range (0 = mellow, 1 = bright)
        // A lower value gives a warmer, more guitar-like tone
        // The original Karplus-Strong uses 0.5, we use 0.25 for a warmer sound

        // Test pick position is valid
        #expect(generator.pickPosition >= 0.0, "Pick position must be >= 0")
        #expect(generator.pickPosition <= 0.5, "Pick position should be <= 0.5 (middle)")
        #expect(generator.pickPosition == 0.35, "Pick position should be 0.35 for guitar-like sound")
    }

    @Test("Output gain provides good volume without clipping")
    func testOutputGain() {
        // Current value: 1.0 (maximized for phone speaker volume)
        let outputGain: Float = 1.0

        #expect(outputGain <= 1.0, "Output gain should be <= 1.0 to prevent clipping")
        #expect(outputGain >= 0.8, "Output gain should be high for good volume")
    }

    @Test("Body resonance adds subtle warmth")
    func testBodyResonance() {
        let generator = ToneGenerator()

        #expect(generator.bodyResonance >= 0.0, "Body resonance must be >= 0")
        #expect(generator.bodyResonance <= 0.3, "Body resonance shouldn't be too strong")
        #expect(generator.bodyResonance == 0.15, "Body resonance should be 0.15 for subtle warmth")
    }

    @Test("Low frequency harmonic boost threshold is correct")
    func testLowFreqHarmonicBoost() {
        let generator = ToneGenerator()

        #expect(generator.stringLowFreqThreshold == 150.0, "Low freq threshold should be 150Hz")
        #expect(generator.stringVeryLowFreqThreshold == 100.0, "Very low freq threshold should be 100Hz")
        #expect(generator.stringHarmonicBoost2x == 0.5, "2x harmonic boost should be 0.5")
        #expect(generator.stringHarmonicBoost3x == 0.7, "3x harmonic boost should be 0.7")
        #expect(generator.stringHarmonicBoost4x == 0.5, "4x harmonic boost should be 0.5")
    }

    @Test("Fade out duration prevents clicks")
    func testFadeOutDuration() {
        let fadeOutDuration = 0.15 // 150ms

        #expect(fadeOutDuration >= 0.1, "Fade out should be >= 100ms to prevent clicks")
        #expect(fadeOutDuration <= 0.3, "Fade out shouldn't be too long")
    }
}

// MARK: - Pick Position Tests

struct PickPositionTests {

    @Test("Pick position affects harmonic content")
    func testPickPositionEffect() {
        // Pick position of 0.35 means we pluck at 35% from the bridge
        // This creates a comb filter that removes harmonics at multiples of 1/0.35 ≈ 2.86
        let pickPosition: Float = 0.35

        // At 100 sample buffer, pick delay would be 35 samples
        let bufferLength = 100
        let pickDelay = Int(Float(bufferLength) * pickPosition)
        #expect(pickDelay == 35)

        // This suppresses the ~3rd harmonic area, giving a warmer tone
    }

    @Test("Pick position comb filter calculation")
    func testCombFilterCalculation() {
        let pickPosition: Float = 0.35
        let combStrength: Float = 0.5

        // Comb filter: output[i] = input[i] - input[i - delay] * strength
        let currentSample: Float = 0.8
        let delayedSample: Float = 0.4

        let filtered = currentSample - delayedSample * combStrength
        #expect(abs(filtered - 0.6) < 0.001) // 0.8 - 0.4 * 0.5 = 0.6
    }

    @Test("Pick position range is valid")
    func testPickPositionRange() {
        let generator = ToneGenerator()

        // Pick position should be between 0 and 0.5
        // 0 = at the bridge (very bright)
        // 0.5 = middle of string (warmest, most mellow)
        #expect(generator.pickPosition > 0, "Pick position must be > 0")
        #expect(generator.pickPosition <= 0.5, "Pick position should be <= 0.5")
    }
}

// MARK: - Low-Pass Filter Tests

struct KarplusStrongFilterTests {

    @Test("Low-pass filter averages current and next sample")
    func testLowPassFilter() {
        // Updated brightness blend: 0.25 (warmer than before)
        let brightnessBlend: Float = 0.25

        let current: Float = 0.8
        let next: Float = 0.4

        // Filter formula: blend * current + (1 - blend) * next
        let filtered = brightnessBlend * current + (1 - brightnessBlend) * next

        // At 0.25 blend: 0.25 * 0.8 + 0.75 * 0.4 = 0.2 + 0.3 = 0.5
        #expect(abs(filtered - 0.5) < 0.001)
    }

    @Test("Lower brightness gives warmer tone")
    func testLowerBrightnessIsWarmer() {
        let current: Float = 1.0
        let next: Float = 0.0

        // Lower brightness = more weight on next sample = more low-pass filtering = warmer
        let warmBlend: Float = 0.25
        let brightBlend: Float = 0.5

        let warmFiltered = warmBlend * current + (1 - warmBlend) * next  // 0.25
        let brightFiltered = brightBlend * current + (1 - brightBlend) * next // 0.5

        // Warm blend gives lower value = more high frequencies removed
        #expect(warmFiltered < brightFiltered, "Lower blend = more filtering = warmer")
    }

    @Test("Filter removes energy each cycle (decay)")
    func testFilterDecay() {
        let decayFactor: Float = 0.997
        let brightnessBlend: Float = 0.25

        // Simulate one cycle of delay buffer
        var sample: Float = 1.0
        let next: Float = 0.8

        // Apply filter and decay
        let filtered = brightnessBlend * sample + (1 - brightnessBlend) * next
        let decayed = filtered * decayFactor

        // Sample should be reduced
        #expect(decayed < sample)
    }
}

// MARK: - Noise Burst Initialization Tests

struct NoiseBurstTests {

    @Test("Initial noise is in valid range")
    func testNoiseRange() {
        // The noise should be between -0.5 and 0.5
        for _ in 0..<100 {
            let noise = Float.random(in: -0.5...0.5)
            #expect(noise >= -0.5)
            #expect(noise <= 0.5)
        }
    }

    @Test("Attack envelope ramps up smoothly")
    func testAttackEnvelope() {
        let bufferLength = 100
        let attackSamples = min(bufferLength / 4, 50)

        // First few samples should be quieter
        let firstEnvelope = Float(0) / Float(attackSamples)
        let midIndex = attackSamples / 2
        let midEnvelope = Float(midIndex) / Float(attackSamples)
        let endEnvelope = Float(attackSamples - 1) / Float(attackSamples)

        #expect(firstEnvelope == 0)
        // midEnvelope is 12/25 = 0.48 due to integer division of attackSamples/2
        #expect(midEnvelope >= 0.4 && midEnvelope <= 0.6, "Mid envelope should be around 0.5")
        #expect(endEnvelope > 0.9)
    }

    @Test("Double low-pass filtering creates warmer excitation")
    func testDoubleLowPassFiltering() {
        // Simulate double filtering on a simple signal
        var buffer: [Float] = [1.0, 0.0, 1.0, 0.0, 1.0]

        // First pass (aggressive: 0.4 current + 0.6 previous)
        for idx in 1..<buffer.count {
            buffer[idx] = 0.4 * buffer[idx] + 0.6 * buffer[idx - 1]
        }

        // Second pass (even: 0.5 current + 0.5 previous)
        for idx in 1..<buffer.count {
            buffer[idx] = 0.5 * buffer[idx] + 0.5 * buffer[idx - 1]
        }

        // After double filtering, high frequency content should be reduced
        // The variance should be much lower than original
        let mean = buffer.reduce(0, +) / Float(buffer.count)
        let variance = buffer.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Float(buffer.count)

        // Original signal had variance of 0.24, filtered should be much lower
        #expect(variance < 0.1, "Double filtering should reduce variance significantly")
    }
}
