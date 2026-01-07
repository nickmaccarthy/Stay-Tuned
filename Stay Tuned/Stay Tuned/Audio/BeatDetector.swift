//
//  BeatDetector.swift
//  Stay Tuned
//
//  Beat/tempo detection using onset detection and interval measurement
//

import Accelerate
import Foundation

/// Result of beat detection analysis
struct BeatDetectionResult {
    let bpm: Double
    let confidence: Float
    /// Alternative tempo (half or double time)
    let alternativeBPM: Double?
}

/// Detects tempo/BPM from audio using onset detection and interval measurement
final class BeatDetector {

    // MARK: - Configuration

    /// Minimum BPM to detect
    private let minBPM: Double = 60.0
    /// Maximum BPM to detect
    private let maxBPM: Double = 200.0

    /// Size of the audio envelope history in seconds
    /// 3-4 seconds is usually enough to capture 2-3 beats of slow tempos
    private let historyDuration: TimeInterval = 3.5

    /// Number of audio envelopes per second (downsample rate)
    /// 172Hz provides ~1.5 BPM resolution at 120 BPM, preventing quantization errors
    /// 44100 / 256 = ~172Hz
    private let envelopeRate: Double = 172.0

    // MARK: - State

    /// Circular buffer storing RMS energy history
    private var envelopeBuffer: [Float]
    private var writeIndex: Int = 0
    private var isBufferFull = false

    /// Total sub-frames processed
    private var framesProcessed: Int = 0

    /// Progress 0-1
    private(set) var analysisProgress: Float = 0

    // MARK: - Callbacks

    /// Called when an onset/beat is detected (used for visual pulse)
    var onOnsetDetected: ((Float) -> Void)?

    // MARK: - Initialization

    init() {
        // Calculate buffer size needed
        let bufferSize = Int(historyDuration * envelopeRate)
        envelopeBuffer = [Float](repeating: 0, count: bufferSize)
    }

    // MARK: - Public Interface

    /// Reset detector state
    func reset() {
        envelopeBuffer.withUnsafeMutableBufferPointer { ptr in
            ptr.baseAddress?.initialize(repeating: 0, count: ptr.count)
        }
        writeIndex = 0
        isBufferFull = false
        framesProcessed = 0
        analysisProgress = 0
    }

    /// Process incoming audio samples and return detected BPM
    func analyze(samples: [Float], sampleRate: Double) -> BeatDetectionResult? {
        // We process the buffer in sub-chunks to achieve higher temporal resolution (172Hz)
        // without requesting tiny buffers from the audio engine.
        let step = Int(sampleRate / envelopeRate)
        var bpmResult: BeatDetectionResult?

        var currentIndex = 0
        while currentIndex + step <= samples.count {
            // Process sub-chunk
            let chunkStart = currentIndex
            let chunkEnd = currentIndex + step

            // 1. Calculate RMS for this sub-chunk
            var rawRMS: Float = 0
            // We can assume contiguous memory for simple array slicing in vDSP
            samples.withUnsafeBufferPointer { ptr in
                guard let base = ptr.baseAddress else { return }
                vDSP_rmsqv(base + chunkStart, 1, &rawRMS, vDSP_Length(step))
            }

            // Boost quiet signals
            rawRMS = min(1.0, rawRMS * 3.0)

            // 2. Store in circular buffer
            envelopeBuffer[writeIndex] = rawRMS
            writeIndex = (writeIndex + 1) % envelopeBuffer.count

            framesProcessed += 1

            if writeIndex == 0 {
                isBufferFull = true
            }

            // Visual feedback (Pulse)
            if rawRMS > 0.05 {
                onOnsetDetected?(rawRMS)
            }

            currentIndex += step
        }

        // Update progress
        if !isBufferFull {
            analysisProgress = Float(writeIndex) / Float(envelopeBuffer.count)
            return nil
        }
        analysisProgress = 1.0

        // 3. Perform Autocorrelation
        // Only run occasionally (e.g., every ~40 sub-frames, approx 4 times/sec)
        // 172Hz / 40 = ~4.3Hz updates
        if framesProcessed % 40 == 0 {
            bpmResult = performAutocorrelation()
        }

        return bpmResult
    }

    // MARK: - Autocorrelation Logic

    private func performAutocorrelation() -> BeatDetectionResult? {
        let n = envelopeBuffer.count

        // Create a linearized copy of the buffer
        var orderedBuffer = [Float](repeating: 0, count: n)
        if isBufferFull {
            let part1Count = n - writeIndex
            let part2Count = writeIndex

            // Copy oldest part
            for i in 0 ..< part1Count {
                orderedBuffer[i] = envelopeBuffer[writeIndex + i]
            }
            // Copy newest part (wrapped)
            for i in 0 ..< part2Count {
                orderedBuffer[part1Count + i] = envelopeBuffer[i]
            }
        } else {
            orderedBuffer = envelopeBuffer
        }

        // Remove DC component
        var sum: Float = 0
        vDSP_sve(orderedBuffer, 1, &sum, vDSP_Length(n))
        var mean = -sum / Float(n)
        vDSP_vsadd(orderedBuffer, 1, &mean, &orderedBuffer, 1, vDSP_Length(n))

        // Lag Search
        let minLag = Int((60.0 / maxBPM) * envelopeRate)
        let maxLag = Int((60.0 / minBPM) * envelopeRate)

        // Store correlations to check for harmonics later
        // We use a dictionary for sparse storage or array for full range
        // Since lags are indices, a simple array is fastest
        var correlations = [Float](repeating: 0, count: n / 2 + 1)

        var bestCorrelation: Float = -1.0
        var bestLag = 0

        for lag in minLag ... min(maxLag, n / 2) {
            var correlation: Float = 0
            let length = vDSP_Length(n - lag)

            orderedBuffer.withUnsafeBufferPointer { ptr in
                guard let base = ptr.baseAddress else { return }
                vDSP_dotpr(base, 1, base + lag, 1, &correlation, length)
            }

            // Normalize by length
            correlation /= Float(length)

            // Store for peak picking
            correlations[lag] = correlation

            if correlation > bestCorrelation {
                bestCorrelation = correlation
                bestLag = lag
            }
        }

        guard bestLag > 0 else { return nil }

        // --- Harmonic Correction (Double Time Check) ---
        // If we found a slow tempo (large lag), check if there is a strong peak at half the lag (fast tempo).
        // e.g., if BestLag=86 (60 BPM), check Lag=43 (120 BPM).
        // If Lag 43 has > 50% of the energy of Lag 86, prefer 120 BPM (it's more useful).

        let doubleTimeLag = bestLag / 2
        if doubleTimeLag >= minLag {
            let harmonicScore = correlations[doubleTimeLag]
            // "0.5" is the threshold ratio.
            // If the faster beat is at least half as strong as the slower one, pick it.
            if harmonicScore > (bestCorrelation * 0.5) {
                bestLag = doubleTimeLag
                bestCorrelation = harmonicScore
            }
        }

        // Parabolic Interpolation for sub-sample precision
        var fractionalOffset: Float = 0
        if bestLag > 0, bestLag < correlations.count - 1 {
            let valPrev = correlations[bestLag - 1]
            let valNext = correlations[bestLag + 1]

            let denominator = (valNext - 2 * correlations[bestLag] + valPrev)
            if abs(denominator) > 1e-6 {
                fractionalOffset = (valPrev - valNext) / (2 * denominator)
            }
        }

        let adjustedLag = Double(bestLag) + Double(fractionalOffset)
        let periodSeconds = adjustedLag / envelopeRate
        let bpm = 60.0 / periodSeconds

        let confidence = min(1.0, max(0.0, bestCorrelation * 1000.0))

        return BeatDetectionResult(
            bpm: bpm,
            confidence: confidence,
            alternativeBPM: nil
        )
    }
}
