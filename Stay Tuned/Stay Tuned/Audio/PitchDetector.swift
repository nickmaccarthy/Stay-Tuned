//
//  PitchDetector.swift
//  Stay Tuned
//
//  Created by Nick MacCarthy on 12/21/25.
//

import Accelerate
import Foundation

/// Detects pitch from audio samples using YIN algorithm (more accurate than simple autocorrelation)
final class PitchDetector {

    /// Frequency range for chromatic tuning (covers B0 to B7)
    private let minFrequency: Double = 30.0 // ~B0 (30.87 Hz) - covers full piano range
    private let maxFrequency: Double = 4000.0 // ~B7 (3951 Hz) - covers full audible musical range

    /// Amplitude threshold - balanced for sustain tracking (around -55 dB cutoff)
    private let amplitudeThreshold: Float = 0.0018

    /// Sample buffer for accumulation
    private var sampleBuffer: [Float] = []
    // Buffer must be > 2 * (sampleRate / minFrequency) for YIN algorithm
    // At 48kHz: 2 * (48000/30) = 3200, so use 4096 for safety
    private let bufferSize = 4096

    /// Last detected frequency (for continuous updates during rate limiting)
    private var lastDetectedFrequency: Double?
    private var lastAmplitudeOk: Bool = false

    /// Current decibel level (only valid when above threshold)
    private(set) var currentDecibels: Float?

    /// Detect pitch using YIN-inspired algorithm
    func detectPitch(samples: [Float], sampleRate: Double) -> Double? {
        // Accumulate samples
        sampleBuffer.append(contentsOf: samples)
        if sampleBuffer.count > bufferSize {
            sampleBuffer.removeFirst(sampleBuffer.count - bufferSize)
        }

        guard sampleBuffer.count >= bufferSize else { return nil }

        // Check amplitude first
        var rms: Float = 0
        vDSP_rmsqv(sampleBuffer, 1, &rms, vDSP_Length(sampleBuffer.count))

        // If amplitude is too low, clear cache and return nil
        guard rms > amplitudeThreshold else {
            lastDetectedFrequency = nil
            lastAmplitudeOk = false
            currentDecibels = nil
            return nil
        }

        lastAmplitudeOk = true

        // Calculate decibels (dB) from RMS - reference is 1.0 (max amplitude)
        // 20 * log10(rms) gives us dB, typically ranging from -60 to 0
        currentDecibels = 20 * log10(rms)

        // Calculate lag range based on frequency range
        let minLag = Int(sampleRate / maxFrequency) // ~110 at 44.1kHz
        let maxLag = Int(sampleRate / minFrequency) // ~630 at 44.1kHz

        guard maxLag < bufferSize / 2 else { return nil }

        // Compute difference function (YIN step 2) - optimized with Accelerate
        var difference = [Float](repeating: 0, count: maxLag)
        var tempBuffer = [Float](repeating: 0, count: bufferSize)

        sampleBuffer.withUnsafeBufferPointer { samplesPtr in
            guard let baseAddress = samplesPtr.baseAddress else { return }

            for tau in minLag ..< maxLag {
                let length = vDSP_Length(bufferSize - tau)
                // Compute difference: tempBuffer = sampleBuffer[0...] - sampleBuffer[tau...]
                vDSP_vsub(baseAddress + tau, 1, baseAddress, 1, &tempBuffer, 1, length)
                // Compute sum of squares using dot product
                var sum: Float = 0
                vDSP_dotpr(tempBuffer, 1, tempBuffer, 1, &sum, length)
                difference[tau] = sum
            }
        }

        // Cumulative mean normalized difference (YIN step 3)
        var cmndf = [Float](repeating: 0, count: maxLag)
        cmndf[minLag] = 1.0
        var runningSum: Float = difference[minLag]

        for tau in (minLag + 1) ..< maxLag {
            runningSum += difference[tau]
            if runningSum > 0 {
                cmndf[tau] = difference[tau] * Float(tau - minLag + 1) / runningSum
            } else {
                cmndf[tau] = 1.0
            }
        }

        // Find first minimum below threshold (YIN step 4)
        // Higher threshold helps detect high E string better
        let threshold: Float = 0.20
        var bestLag = minLag
        var bestValue: Float = 1.0

        for tau in minLag ..< (maxLag - 1) {
            if cmndf[tau] < threshold {
                // Found a dip below threshold
                if cmndf[tau] < cmndf[tau - 1], cmndf[tau] <= cmndf[tau + 1] {
                    // Local minimum
                    bestLag = tau
                    bestValue = cmndf[tau]
                    break
                }
            }
        }

        // If no dip below threshold, find absolute minimum
        if bestValue >= threshold {
            for tau in minLag ..< maxLag {
                if cmndf[tau] < bestValue {
                    bestValue = cmndf[tau]
                    bestLag = tau
                }
            }
        }

        // Need a reasonably good match (relaxed for high strings)
        guard bestValue < 0.6 else { return nil }

        // Parabolic interpolation for sub-sample accuracy
        let y0 = bestLag > minLag ? cmndf[bestLag - 1] : cmndf[bestLag]
        let y1 = cmndf[bestLag]
        let y2 = bestLag < maxLag - 1 ? cmndf[bestLag + 1] : cmndf[bestLag]

        var interpolatedLag = Float(bestLag)
        let denominator = 2 * y1 - y0 - y2
        if abs(denominator) > 0.0001 {
            interpolatedLag += (y0 - y2) / (2 * denominator)
        }

        let frequency = sampleRate / Double(interpolatedLag)

        guard frequency >= minFrequency, frequency <= maxFrequency else { return nil }

        // Cache for continuous response
        lastDetectedFrequency = frequency
        return frequency
    }

    func reset() {
        sampleBuffer.removeAll()
        lastDetectedFrequency = nil
        lastAmplitudeOk = false
        currentDecibels = nil
    }
}
