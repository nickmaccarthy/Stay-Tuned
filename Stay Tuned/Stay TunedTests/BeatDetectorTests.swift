//
//  BeatDetectorTests.swift
//  Stay TunedTests
//
//  Tests for BeatDetector tempo detection using Autocorrelation
//

import Foundation
import Testing
@testable import Stay_Tuned
import Accelerate

struct BeatDetectorTests {

    // MARK: - Autocorrelation Tests

    @Test("Detects 120 BPM correctly")
    func detects120BPM() {
        let detector = BeatDetector()
        let sampleRate: Double = 44100

        // Generate 4s of 120 BPM pulses
        // 120 BPM = 2 beats per second = 0.5s period
        let samples = generatePulseTrain(bpm: 120, duration: 4.5, sampleRate: sampleRate)

        let result = processAll(detector: detector, samples: samples, sampleRate: sampleRate)

        #expect(result != nil, "Should return a result")

        if let bpm = result?.bpm {
            // At 172Hz envelope rate, 120 BPM is lag ~86.
            // Resolution is ~1.4 BPM. Allow small margin.
            let diff = abs(bpm - 120)
            #expect(diff < 2.5, "Detected \(bpm) BPM, expected 120 BPM (Diff: \(diff))")
        }
    }

    @Test("Detects 90 BPM correctly")
    func detects90BPM() {
        let detector = BeatDetector()
        let sampleRate: Double = 44100

        // 90 BPM = 1.5 beats per second = 0.666s period
        let samples = generatePulseTrain(bpm: 90, duration: 4.5, sampleRate: sampleRate)

        let result = processAll(detector: detector, samples: samples, sampleRate: sampleRate)

        #expect(result != nil)

        if let bpm = result?.bpm {
            let diff = abs(bpm - 90)
            #expect(diff < 2.0, "Detected \(bpm) BPM, expected 90 BPM")
        }
    }

    // MARK: - Harmonic Correction Tests

    @Test("Favors 120 BPM over 60 BPM (Harmonic Check)")
    func favorsDoubleTime() {
        // This tests the "Half-Time Error" fix.
        // A pure 120 BPM pulse train has periodicity at 0.5s (120 BPM) AND 1.0s (60 BPM).
        // Without the fix, normalized autocorrelation often picks the longer period (60 BPM)
        // because it's a "safer" match.
        // The fix forces it to pick 120 BPM if it's strong enough.

        let detector = BeatDetector()
        let sampleRate: Double = 44100

        let samples = generatePulseTrain(bpm: 120, duration: 4.5, sampleRate: sampleRate)
        let result = processAll(detector: detector, samples: samples, sampleRate: sampleRate)

        if let bpm = result?.bpm {
            // Should be closer to 120 than 60
            let dist120 = abs(bpm - 120)
            let dist60 = abs(bpm - 60)

            #expect(dist120 < dist60, "Should favor 120 BPM (Dist: \(dist120)) over 60 BPM (Dist: \(dist60)). Detected: \(bpm)")
        }
    }

    // MARK: - Edge Case Tests

    @Test("Returns nil for silence")
    func returnsNilForSilence() {
        let detector = BeatDetector()
        let sampleRate: Double = 44100

        let samples = [Float](repeating: 0, count: Int(sampleRate * 4.0))

        let result = processAll(detector: detector, samples: samples, sampleRate: sampleRate)

        // Silence should produce 0 RMS, no peaks, nil result
        #expect(result == nil)
    }

    @Test("Progress fills up")
    func progressIncreases() {
        let detector = BeatDetector()
        let sampleRate: Double = 44100

        // 1 second of audio (not enough for full result)
        let samples = generatePulseTrain(bpm: 100, duration: 1.0, sampleRate: sampleRate)

        let _ = processAll(detector: detector, samples: samples, sampleRate: sampleRate)

        // Should be partially full
        #expect(detector.analysisProgress > 0.0)
        #expect(detector.analysisProgress < 1.0)
    }

    // MARK: - Helpers

    func generatePulseTrain(bpm: Double, duration: Double, sampleRate: Double) -> [Float] {
        let n = Int(duration * sampleRate)
        var samples = [Float](repeating: 0, count: n)

        let interval = 60.0 / bpm
        let samplesPerBeat = Int(interval * sampleRate)

        // Create a strong transient every beat
        for i in stride(from: 0, to: n, by: samplesPerBeat) {
            // 50ms pulse
            let pulseLen = Int(0.05 * sampleRate)
            for j in 0..<pulseLen {
                if i + j < n {
                    // Simple decay
                    samples[i+j] = Float(1.0 - Double(j)/Double(pulseLen))
                }
            }
        }

        return samples
    }

    func processAll(detector: BeatDetector, samples: [Float], sampleRate: Double) -> BeatDetectionResult? {
        // Feed in chunks of 1024 to simulate real engine
        let chunkSize = 1024
        var lastResult: BeatDetectionResult? = nil

        var offset = 0
        while offset < samples.count {
            let end = min(offset + chunkSize, samples.count)
            let chunk = Array(samples[offset..<end])

            if let res = detector.analyze(samples: chunk, sampleRate: sampleRate) {
                lastResult = res
            }
            offset += chunkSize
        }
        return lastResult
    }
}
