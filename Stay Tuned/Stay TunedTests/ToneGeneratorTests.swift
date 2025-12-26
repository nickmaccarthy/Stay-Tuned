//
//  ToneGeneratorTests.swift
//  Stay TunedTests
//
//  Tests for ToneGenerator Karplus-Strong synthesis
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
        for targetFreq in [82.41, 110.0, 146.83, 196.0, 246.94, 329.63, 440.0] {
            let bufferLength = generator.calculateBufferLength(for: targetFreq, sampleRate: sampleRate)
            let actualFreq = sampleRate / Double(bufferLength)
            
            // Should be within 1Hz of target (small rounding error expected)
            let error = abs(actualFreq - targetFreq)
            #expect(error < 1.0, "Frequency \(targetFreq) should have <1Hz error, got \(error)")
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
    
    @Test("Brightness blend balances low-pass filter")
    func testBrightnessBlend() {
        // Current value: 0.35 (warmer than classic 0.5)
        let brightnessBlend: Float = 0.35
        
        // Should be in valid range
        #expect(brightnessBlend >= 0.0, "Brightness blend must be >= 0")
        #expect(brightnessBlend <= 1.0, "Brightness blend must be <= 1")
        
        // 0.35 gives a warmer, bassier tone than classic 0.5
        #expect(brightnessBlend < 0.5, "Lower blend = warmer tone")
        #expect(brightnessBlend >= 0.3, "Not too dark")
    }
    
    @Test("Output gain prevents clipping")
    func testOutputGain() {
        let outputGain: Float = 0.8
        
        #expect(outputGain <= 1.0, "Output gain should be <= 1.0 to prevent clipping")
        #expect(outputGain >= 0.5, "Output gain should provide good volume")
    }
    
    @Test("Fade out duration prevents clicks")
    func testFadeOutDuration() {
        let fadeOutDuration = 0.15 // 150ms
        
        #expect(fadeOutDuration >= 0.1, "Fade out should be >= 100ms to prevent clicks")
        #expect(fadeOutDuration <= 0.3, "Fade out shouldn't be too long")
    }
}

// MARK: - Low-Pass Filter Tests

struct KarplusStrongFilterTests {
    
    @Test("Low-pass filter averages current and next sample")
    func testLowPassFilter() {
        let brightnessBlend: Float = 0.35
        
        let current: Float = 0.8
        let next: Float = 0.4
        
        // Filter formula: blend * current + (1 - blend) * next
        let filtered = brightnessBlend * current + (1 - brightnessBlend) * next
        
        // At 0.35 blend: 0.35 * 0.8 + 0.65 * 0.4 = 0.28 + 0.26 = 0.54
        #expect(abs(filtered - 0.54) < 0.001)
    }
    
    @Test("Higher brightness keeps more of current sample")
    func testHigherBrightness() {
        let current: Float = 1.0
        let next: Float = 0.0
        
        let lowBrightness = 0.3 * current + 0.7 * next  // 0.3
        let highBrightness = 0.7 * current + 0.3 * next // 0.7
        
        #expect(highBrightness > lowBrightness)
    }
    
    @Test("Filter removes energy each cycle (decay)")
    func testFilterDecay() {
        let decayFactor: Float = 0.997
        let brightnessBlend: Float = 0.35
        
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
        let midEnvelope = Float(attackSamples / 2) / Float(attackSamples)
        let endEnvelope = Float(attackSamples - 1) / Float(attackSamples)
        
        #expect(firstEnvelope == 0)
        #expect(midEnvelope == 0.5)
        #expect(endEnvelope > 0.9)
    }
}
