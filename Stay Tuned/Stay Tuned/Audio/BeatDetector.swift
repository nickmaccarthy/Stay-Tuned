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

    // MARK: - Configuration (Sensitive Settings)

    /// BPM range constraints
    private let minBPM: Double = 40.0
    private let maxBPM: Double = 300.0

    /// Minimum interval between onsets (prevents double-triggers)
    /// 0.2s = max ~300 BPM
    private let minOnsetInterval: TimeInterval = 0.2

    /// Maximum interval before considering it a new phrase
    private let maxOnsetInterval: TimeInterval = 2.5

    /// Onset detection threshold - ratio of current energy to smoothed average
    /// 1.1 = extremely sensitive
    private let onsetThresholdRatio: Float = 1.1

    /// Rising edge threshold - current must be this much louder than previous
    /// 1.02 = extremely sensitive to any increase
    private let risingEdgeRatio: Float = 1.02

    /// Minimum absolute energy to consider (noise gate)
    /// Very low to catch quiet signals
    private let noiseFloor: Float = 0.0005

    /// Number of onsets to keep for interval calculation
    private let maxOnsetHistory = 16

    // MARK: - State

    /// History of onset timestamps
    private var onsetTimes: [Date] = []

    /// Previous buffer energy
    private var previousEnergy: Float = 0

    /// Smoothed energy for adaptive thresholding
    private var smoothedEnergy: Float = 0

    /// Last calculated BPM for smoothing
    private var lastCalculatedBPM: Double?

    /// Stable BPM after confirmation
    private var confirmedBPM: Double?

    /// Count of consistent readings for confirmation
    private var consistentReadings = 0

    /// Total samples processed (for progress tracking)
    private var totalSamplesProcessed: Int = 0

    /// Sample rate
    private var sampleRate: Double = 44100

    // MARK: - Callbacks

    /// Called when an onset is detected - use for visual feedback
    /// Parameter is the onset strength (0-1)
    var onOnsetDetected: ((Float) -> Void)?

    // MARK: - Public Interface

    /// Process incoming audio samples and return detected BPM
    func analyze(samples: [Float], sampleRate: Double) -> BeatDetectionResult? {
        self.sampleRate = sampleRate
        totalSamplesProcessed += samples.count

        // Simple full-band RMS energy (no low-pass filter)
        var energy: Float = 0
        vDSP_rmsqv(samples, 1, &energy, vDSP_Length(samples.count))

        // Check for onset BEFORE updating smoothed energy
        // This prevents clicks from raising their own threshold
        let isOnset = detectOnset(currentEnergy: energy)

        // Only update smoothed energy during quiet periods (non-onset)
        // This tracks the background level without being polluted by clicks
        if !isOnset {
            smoothedEnergy = 0.9 * smoothedEnergy + 0.1 * energy
        }

        previousEnergy = energy

        if isOnset {
            let now = Date()

            // Check minimum interval (debounce)
            if let lastOnset = onsetTimes.last {
                let interval = now.timeIntervalSince(lastOnset)
                if interval < minOnsetInterval {
                    return buildCurrentResult()
                }

                // Check if this is a new phrase (too long since last onset)
                if interval > maxOnsetInterval {
                    onsetTimes.removeAll()
                    lastCalculatedBPM = nil
                    confirmedBPM = nil
                    consistentReadings = 0
                }
            }

            // Record onset
            onsetTimes.append(now)

            // Trim history
            if onsetTimes.count > maxOnsetHistory {
                onsetTimes.removeFirst()
            }

            // Calculate onset strength for visual feedback (0-1)
            let strength = min(1.0, energy / max(smoothedEnergy * 2, 0.01))
            onOnsetDetected?(strength)

            // Calculate BPM from intervals
            return calculateBPM()
        }

        return buildCurrentResult()
    }

    /// Reset detector state for new detection session
    func reset() {
        onsetTimes.removeAll()
        previousEnergy = 0
        smoothedEnergy = 0
        lastCalculatedBPM = nil
        confirmedBPM = nil
        consistentReadings = 0
        totalSamplesProcessed = 0
    }

    /// Returns progress toward stable detection (0-1)
    var analysisProgress: Float {
        let onsetProgress = Float(onsetTimes.count) / 8.0
        return min(1.0, onsetProgress)
    }

    /// Whether we have enough data for a reliable estimate
    var hasStableEstimate: Bool {
        confirmedBPM != nil || (onsetTimes.count >= 6 && lastCalculatedBPM != nil)
    }

    // MARK: - Private Methods

    /// Detect if current buffer contains an onset
    private func detectOnset(currentEnergy: Float) -> Bool {
        // Must be above noise floor
        guard currentEnergy > noiseFloor else {
            return false
        }

        // Must exceed adaptive threshold (based on smoothed energy)
        let adaptiveThreshold = max(smoothedEnergy * onsetThresholdRatio, noiseFloor * 1.5)
        guard currentEnergy > adaptiveThreshold else {
            return false
        }

        // Must be rising (louder than previous buffer)
        guard currentEnergy > previousEnergy * risingEdgeRatio else {
            return false
        }

        return true
    }

    /// Calculate BPM from onset intervals
    private func calculateBPM() -> BeatDetectionResult? {
        // Need at least 2 onsets (1 interval) for first estimate
        guard onsetTimes.count >= 2 else {
            return nil
        }

        // Collect all valid intervals
        var intervals: [TimeInterval] = []
        for i in 1 ..< onsetTimes.count {
            let interval = onsetTimes[i].timeIntervalSince(onsetTimes[i - 1])
            let bpm = 60.0 / interval
            if bpm >= minBPM, bpm <= maxBPM {
                intervals.append(interval)
            }
        }

        guard !intervals.isEmpty else {
            return buildCurrentResult()
        }

        // Use median of all intervals (most robust to outliers)
        let medianInterval = median(intervals)
        let estimatedBPM = 60.0 / medianInterval

        // Light smoothing (50/50) for stability without lag
        let smoothedBPM: Double
        if let lastBPM = lastCalculatedBPM {
            smoothedBPM = 0.5 * estimatedBPM + 0.5 * lastBPM

            // Track consistency for confirmation
            if abs(round(smoothedBPM) - round(lastBPM)) < 1.0 {
                consistentReadings += 1
                if consistentReadings >= 3 {
                    confirmedBPM = round(smoothedBPM)
                }
            } else {
                consistentReadings = max(0, consistentReadings - 1)
            }
        } else {
            smoothedBPM = estimatedBPM
        }

        lastCalculatedBPM = smoothedBPM

        let confidence = calculateConfidence()
        let displayBPM = confirmedBPM ?? round(smoothedBPM)
        let alternative = findAlternativeTempo(bpm: displayBPM)

        return BeatDetectionResult(
            bpm: displayBPM,
            confidence: confidence,
            alternativeBPM: alternative
        )
    }

    /// Calculate median of an array
    private func median(_ values: [TimeInterval]) -> TimeInterval {
        let sorted = values.sorted()
        let count = sorted.count
        if count % 2 == 0 {
            return (sorted[count / 2 - 1] + sorted[count / 2]) / 2
        } else {
            return sorted[count / 2]
        }
    }

    /// Calculate confidence based on interval consistency
    private func calculateConfidence() -> Float {
        guard onsetTimes.count >= 2 else {
            return 0.2
        }

        var intervals: [Double] = []
        for i in 1 ..< onsetTimes.count {
            intervals.append(onsetTimes[i].timeIntervalSince(onsetTimes[i - 1]))
        }

        // Calculate coefficient of variation (std dev / mean)
        let mean = intervals.reduce(0, +) / Double(intervals.count)
        let variance = intervals.map { pow($0 - mean, 2) }.reduce(0, +) / Double(intervals.count)
        let stdDev = sqrt(variance)
        let cv = stdDev / mean

        // Lower CV = more consistent = higher confidence
        let consistencyConfidence: Float = if cv < 0.05 {
            1.0
        } else if cv < 0.15 {
            Float(1.0 - (cv - 0.05) * 4)
        } else {
            Float(max(0.2, 0.6 - (cv - 0.15) * 2))
        }

        // Boost with sample count and confirmation
        let sampleBoost = Float(min(onsetTimes.count, 8)) / 8.0 * 0.2
        let confirmBoost: Float = confirmedBPM != nil ? 0.1 : 0.0

        return min(1.0, consistencyConfidence * 0.7 + sampleBoost + confirmBoost)
    }

    /// Find alternative tempo (half or double time)
    private func findAlternativeTempo(bpm: Double) -> Double? {
        if bpm < 80, bpm * 2 <= maxBPM {
            return round(bpm * 2)
        }
        if bpm > 160, bpm / 2 >= minBPM {
            return round(bpm / 2)
        }
        return nil
    }

    /// Build result from current state
    private func buildCurrentResult() -> BeatDetectionResult? {
        guard let bpm = confirmedBPM ?? lastCalculatedBPM else {
            return nil
        }

        return BeatDetectionResult(
            bpm: round(bpm),
            confidence: calculateConfidence(),
            alternativeBPM: findAlternativeTempo(bpm: bpm)
        )
    }
}
