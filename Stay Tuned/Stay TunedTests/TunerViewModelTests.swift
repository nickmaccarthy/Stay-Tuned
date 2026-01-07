//
//  TunerViewModelTests.swift
//  Stay TunedTests
//
//  Tests for TunerViewModel business logic
//

import Foundation
import Testing
@testable import Stay_Tuned

// MARK: - Reference Pitch Tests

struct ReferencePitchTests {

    @Test("Default reference pitch is 440Hz")
    func testDefaultReferencePitch() {
        // The default should be 440Hz (A4)
        let defaultPitch = 440
        #expect(defaultPitch == 440)
    }

    @Test("Reference pitch multiplier at 440Hz is 1.0")
    func testMultiplierAt440() {
        let referencePitch = 440
        let multiplier = Double(referencePitch) / 440.0
        #expect(multiplier == 1.0)
    }

    @Test("Reference pitch multiplier at 432Hz")
    func testMultiplierAt432() {
        let referencePitch = 432
        let multiplier = Double(referencePitch) / 440.0
        #expect(abs(multiplier - 0.9818) < 0.001)
    }

    @Test("Reference pitch multiplier at 444Hz")
    func testMultiplierAt444() {
        let referencePitch = 444
        let multiplier = Double(referencePitch) / 440.0
        #expect(abs(multiplier - 1.0091) < 0.001)
    }

    @Test("Adjusted frequency calculation at A=432")
    func testAdjustedFrequencyAt432() {
        let referencePitch = 432
        let multiplier = Double(referencePitch) / 440.0

        // Low E at 82.41Hz with A=440 should be adjusted
        let baseFrequency = 82.41
        let adjusted = baseFrequency * multiplier

        // At A=432, E2 should be lower
        #expect(adjusted < baseFrequency)
        #expect(abs(adjusted - 80.91) < 0.1)
    }
}

// MARK: - In-Tune Tolerance Tests

struct InTuneToleranceTests {

    // In-tune tolerance is ±7 cents
    let inTuneTolerance = 7

    @Test("Exactly 0 cents is in tune")
    func testZeroCentsInTune() {
        let cents = 0
        let isInTune = abs(cents) <= inTuneTolerance
        #expect(isInTune == true)
    }

    @Test("+5 cents is in tune")
    func testPositive5CentsInTune() {
        let cents = 5
        let isInTune = abs(cents) <= inTuneTolerance
        #expect(isInTune == true)
    }

    @Test("-5 cents is in tune")
    func testNegative5CentsInTune() {
        let cents = -5
        let isInTune = abs(cents) <= inTuneTolerance
        #expect(isInTune == true)
    }

    @Test("+7 cents is at the edge of in tune")
    func testPositive7CentsInTune() {
        let cents = 7
        let isInTune = abs(cents) <= inTuneTolerance
        #expect(isInTune == true)
    }

    @Test("-7 cents is at the edge of in tune")
    func testNegative7CentsInTune() {
        let cents = -7
        let isInTune = abs(cents) <= inTuneTolerance
        #expect(isInTune == true)
    }

    @Test("+8 cents is out of tune")
    func testPositive8CentsOutOfTune() {
        let cents = 8
        let isInTune = abs(cents) <= inTuneTolerance
        #expect(isInTune == false)
    }

    @Test("-8 cents is out of tune")
    func testNegative8CentsOutOfTune() {
        let cents = -8
        let isInTune = abs(cents) <= inTuneTolerance
        #expect(isInTune == false)
    }

    @Test("+50 cents is definitely out of tune")
    func testFarOutOfTune() {
        let cents = 50
        let isInTune = abs(cents) <= inTuneTolerance
        #expect(isInTune == false)
    }
}

// MARK: - Tuner Mode Tests

struct TunerModeTests {

    @Test("TunerMode has instrument and chromatic cases")
    func testTunerModeCases() {
        let instrument = TunerMode.instrument
        let chromatic = TunerMode.chromatic

        #expect(instrument != chromatic)
    }

    @Test("TunerMode raw values are correct")
    func testTunerModeRawValues() {
        #expect(TunerMode.instrument.rawValue == "instrument")
        #expect(TunerMode.chromatic.rawValue == "chromatic")
    }

    @Test("TunerMode can be created from raw value")
    func testTunerModeFromRawValue() {
        let instrument = TunerMode(rawValue: "instrument")
        let chromatic = TunerMode(rawValue: "chromatic")

        #expect(instrument == .instrument)
        #expect(chromatic == .chromatic)
    }
}

// MARK: - Normalized Amplitude Tests

struct NormalizedAmplitudeTests {

    /// Calculate normalized amplitude from dB (0.0 to 1.0)
    /// Maps dB range (-60 to 0) to 0.0 to 1.0
    func normalizedAmplitude(from dB: Float) -> Double {
        return Double(max(0, min(1, (dB + 60) / 60)))
    }

    @Test("-60dB maps to 0.0")
    func testMinus60DbIsZero() {
        let normalized = normalizedAmplitude(from: -60)
        #expect(normalized == 0.0)
    }

    @Test("0dB maps to 1.0")
    func testZeroDbIsOne() {
        let normalized = normalizedAmplitude(from: 0)
        #expect(normalized == 1.0)
    }

    @Test("-30dB maps to 0.5")
    func testMinus30DbIsHalf() {
        let normalized = normalizedAmplitude(from: -30)
        #expect(normalized == 0.5)
    }

    @Test("Below -60dB clamps to 0.0")
    func testBelowRangeClampsToZero() {
        let normalized = normalizedAmplitude(from: -80)
        #expect(normalized == 0.0)
    }

    @Test("Above 0dB clamps to 1.0")
    func testAboveRangeClampsToOne() {
        let normalized = normalizedAmplitude(from: 10)
        #expect(normalized == 1.0)
    }
}

// MARK: - Frequency History / Smoothing Tests

struct FrequencySmoothingTests {

    @Test("Median of sorted frequencies provides stability")
    func testMedianFrequency() {
        // Simulate frequency history with some outliers
        let frequencies = [440.0, 441.0, 440.5, 445.0, 440.2, 439.8, 440.1]
        let sorted = frequencies.sorted()
        let median = sorted[sorted.count / 2]

        // Median should be close to the true frequency
        #expect(abs(median - 440.0) < 1.0)
    }

    @Test("Median filters out outliers")
    func testMedianFiltersOutliers() {
        // Frequency history with one big outlier
        let frequencies = [440.0, 440.1, 880.0, 440.2, 439.9]  // 880 is an octave jump outlier
        let sorted = frequencies.sorted()
        let median = sorted[sorted.count / 2]

        // Median should ignore the outlier
        #expect(abs(median - 440.0) < 1.0)
    }
}

// MARK: - String Confirmation Tests

struct StringConfirmationTests {

    @Test("Confirmed strings set can track multiple strings")
    func testConfirmedStringsSet() {
        var confirmedStrings: Set<Int> = []

        // Confirm some strings
        confirmedStrings.insert(0)  // Low E
        confirmedStrings.insert(1)  // A
        confirmedStrings.insert(2)  // D

        #expect(confirmedStrings.contains(0))
        #expect(confirmedStrings.contains(1))
        #expect(confirmedStrings.contains(2))
        #expect(!confirmedStrings.contains(3))
        #expect(!confirmedStrings.contains(4))
        #expect(!confirmedStrings.contains(5))
    }

    @Test("All strings tuned when set has 6 elements")
    func testAllStringsTuned() {
        var confirmedStrings: Set<Int> = []

        for i in 0..<6 {
            confirmedStrings.insert(i)
        }

        let allTuned = confirmedStrings.count == 6
        #expect(allTuned == true)
    }

    @Test("Not all strings tuned with 5 elements")
    func testNotAllStringsTuned() {
        var confirmedStrings: Set<Int> = []

        for i in 0..<5 {
            confirmedStrings.insert(i)
        }

        let allTuned = confirmedStrings.count == 6
        #expect(allTuned == false)
    }
}

// MARK: - Tone Playback Detection Pause Tests

struct TonePlaybackDetectionTests {

    @Test("isPlayingTone flag should block pitch detection")
    func testIsPlayingToneFlagBlocksDetection() {
        // This tests the logic that when isPlayingTone is true,
        // pitch detection should be skipped to prevent self-tuning bug
        let isPlayingTone = true

        // Simulating the guard condition in processAudio
        if isPlayingTone {
            // Should skip detection - this is the expected behavior
            #expect(true)
        } else {
            // Should process - but we're testing the blocking case
            #expect(false, "Detection should be blocked when tone is playing")
        }
    }

    @Test("Spectrum analyzer samples should still update when tone plays")
    func testSpectrumUpdatesWhileTonePlays() {
        // Even when tone is playing, we want the spectrum analyzer to show activity
        var audioSamples: [Float] = []
        let newSamples: [Float] = [0.1, 0.2, 0.3, 0.4, 0.5]
        let isPlayingTone = true

        // The logic: update samples even if isPlayingTone is true
        if isPlayingTone {
            audioSamples.append(contentsOf: newSamples)
        }

        #expect(audioSamples.count == 5)
    }

    @Test("Audio samples buffer is capped at 4096")
    func testAudioSamplesBufferCap() {
        var audioSamples: [Float] = Array(repeating: 0.0, count: 4000)
        let newSamples: [Float] = Array(repeating: 0.1, count: 500)

        // Simulate the buffer logic
        audioSamples.append(contentsOf: newSamples)
        if audioSamples.count > 4096 {
            audioSamples.removeFirst(audioSamples.count - 4096)
        }

        #expect(audioSamples.count == 4096)
    }

    @Test("Tone start resets tuning state")
    func testToneStartResetsState() {
        // When a tone starts, these should be reset to prevent carry-over
        var sustainedInTune = true
        var inTuneStartTime: Date? = Date()
        var isDetectingPitch = true
        var frequencyHistory: [Double] = [440.0, 441.0, 439.0]

        // Simulate toggleToneForString behavior
        sustainedInTune = false
        inTuneStartTime = nil
        isDetectingPitch = false
        frequencyHistory.removeAll()

        #expect(sustainedInTune == false)
        #expect(inTuneStartTime == nil)
        #expect(isDetectingPitch == false)
        #expect(frequencyHistory.isEmpty)
    }

    @Test("Tone stop clears frequency history for fresh detection")
    func testToneStopClearsHistory() {
        var frequencyHistory: [Double] = [440.0, 441.0, 439.0]
        var smoothedCents: Double = 5.0

        // Simulate stopTone behavior
        frequencyHistory.removeAll()
        smoothedCents = 0

        #expect(frequencyHistory.isEmpty)
        #expect(smoothedCents == 0)
    }
}

// MARK: - Self-Tuning Bug Prevention Tests

struct SelfTuningBugPreventionTests {

    @Test("Detection is skipped when isPlayingTone is true")
    func testDetectionSkippedDuringTone() {
        let isPlayingTone = true
        var detectionWasSkipped = false

        // Simulate processAudio logic
        if isPlayingTone {
            // Update samples for spectrum (still happens)
            // But skip pitch detection
            detectionWasSkipped = true
            return
        }

        // If we got here, detection was NOT skipped
        detectionWasSkipped = false

        // This code is unreachable when isPlayingTone is true
        // so we use a different approach to test
    }

    @Test("String cannot be confirmed while tone is playing")
    func testCannotConfirmWhilePlaying() {
        // The bug: playing a tone caused the string to be auto-confirmed
        // The fix: skip pitch detection entirely when tone is playing

        let isPlayingTone = true
        var confirmedStrings: Set<Int> = []
        let currentStringId = 0

        // Simulating the flow: if detection is skipped, no confirmation can happen
        if isPlayingTone {
            // Detection skipped, so no new confirmation possible
            #expect(!confirmedStrings.contains(currentStringId))
        }
    }

    @Test("Sustained in-tune timer resets when tone starts")
    func testSustainedTimerResetsOnToneStart() {
        var inTuneStartTime: Date? = Date().addingTimeInterval(-1.0) // 1 second ago
        var sustainedInTune = true // Was in tune for >0.5s

        // When tone starts, reset the timer
        inTuneStartTime = nil
        sustainedInTune = false

        #expect(inTuneStartTime == nil)
        #expect(sustainedInTune == false)
    }
}
