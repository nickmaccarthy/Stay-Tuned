//
//  SpectrumAnalyzerView.swift
//  Stay Tuned
//
//  Created by Nick MacCarthy on 12/25/25.
//

import Accelerate
import SwiftUI

/// A fluid, glass-like spectrum visualization using real FFT data
struct SpectrumAnalyzerView: View {
    
    // MARK: - Configuration
    
    /// Number of frequency bands for the wave
    private let bandCount = 128
    
    /// Frequency range to display (Hz)
    private let minFrequency: Float = 60
    private let maxFrequency: Float = 1200
    
    // MARK: - Input Properties
    
    /// Raw audio samples for FFT analysis
    let samples: [Float]
    
    /// Sample rate of the audio
    let sampleRate: Double
    
    /// Whether the tuner is actively listening
    let isListening: Bool
    
    /// Detected frequency (to highlight)
    let detectedFrequency: Double?
    
    // MARK: - State
    
    @State private var bandEnergies: [CGFloat] = Array(repeating: 0, count: 128)
    @State private var smoothedAmplitude: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1/60)) { _ in
                Canvas { context, size in
                    drawFluidSpectrum(context: context, size: size)
                }
                .onChange(of: samples) { _, newSamples in
                    updateSpectrum(samples: newSamples)
                }
            }
        }
        .opacity(isListening ? 0.5 : 0.2)
        .animation(.easeInOut(duration: 0.5), value: isListening)
    }
    
    private func drawFluidSpectrum(context: GraphicsContext, size: CGSize) {
        let width = size.width
        let height = size.height
        
        // Base wave height
        let minHeight: CGFloat = 20
        let maxHeight: CGFloat = height * 0.85
        let baseY = height - minHeight
        
        // Build control points from band energies
        var controlPoints: [CGPoint] = []
        
        for i in 0..<bandEnergies.count {
            let x = (CGFloat(i) / CGFloat(bandEnergies.count - 1)) * width
            let energy = bandEnergies[i]
            let bandHeight = energy * maxHeight
            let y = baseY - bandHeight
            controlPoints.append(CGPoint(x: x, y: y))
        }
        
        // Build smooth path using quadratic bezier curves
        var path = Path()
        path.move(to: CGPoint(x: -10, y: height + 10))
        path.addLine(to: CGPoint(x: -10, y: baseY))
        
        if controlPoints.count >= 2 {
            path.addLine(to: controlPoints[0])
            
            for i in 0..<controlPoints.count - 1 {
                let current = controlPoints[i]
                let next = controlPoints[i + 1]
                let midX = (current.x + next.x) / 2
                let midY = (current.y + next.y) / 2
                
                if i == 0 {
                    path.addQuadCurve(to: CGPoint(x: midX, y: midY), control: current)
                } else {
                    path.addQuadCurve(to: CGPoint(x: midX, y: midY), control: current)
                }
                
                if i == controlPoints.count - 2 {
                    path.addQuadCurve(to: next, control: CGPoint(x: midX, y: midY))
                }
            }
            
            path.addLine(to: controlPoints.last!)
        }
        
        path.addLine(to: CGPoint(x: width + 10, y: baseY))
        path.addLine(to: CGPoint(x: width + 10, y: height + 10))
        path.closeSubpath()
        
        // Glass-like colors based on overall amplitude
        let baseColor = amplitudeColor(Double(smoothedAmplitude))
        let darkColor = amplitudeColorDark(Double(smoothedAmplitude))
        
        let minY = controlPoints.map { $0.y }.min() ?? baseY
        
        // Glass gradient
        let gradient = Gradient(stops: [
            .init(color: baseColor.opacity(0.85), location: 0.0),
            .init(color: baseColor.opacity(0.5), location: 0.3),
            .init(color: darkColor.opacity(0.3), location: 0.65),
            .init(color: Color(hex: "0a0a15").opacity(0.15), location: 1.0)
        ])
        
        let linearGradient = GraphicsContext.Shading.linearGradient(
            gradient,
            startPoint: CGPoint(x: width / 2, y: minY - 20),
            endPoint: CGPoint(x: width / 2, y: height)
        )
        
        // Glow layer
        context.drawLayer { glowContext in
            glowContext.addFilter(.blur(radius: 25))
            glowContext.fill(path, with: .color(baseColor.opacity(0.15 + Double(smoothedAmplitude) * 0.25)))
        }
        
        // Main glass fill
        context.fill(path, with: linearGradient)
        
        // Top edge curve for highlight
        var topLine = Path()
        if controlPoints.count >= 2 {
            topLine.move(to: controlPoints[0])
            
            for i in 0..<controlPoints.count - 1 {
                let current = controlPoints[i]
                let next = controlPoints[i + 1]
                let midX = (current.x + next.x) / 2
                let midY = (current.y + next.y) / 2
                
                if i == 0 {
                    topLine.addQuadCurve(to: CGPoint(x: midX, y: midY), control: current)
                } else {
                    topLine.addQuadCurve(to: CGPoint(x: midX, y: midY), control: current)
                }
                
                if i == controlPoints.count - 2 {
                    topLine.addQuadCurve(to: next, control: CGPoint(x: midX, y: midY))
                }
            }
        }
        
        // Edge glow
        context.drawLayer { edgeGlow in
            edgeGlow.addFilter(.blur(radius: 10))
            edgeGlow.stroke(
                topLine,
                with: .color(baseColor.opacity(0.4 + Double(smoothedAmplitude) * 0.3)),
                style: StrokeStyle(lineWidth: 5, lineCap: .round)
            )
        }
        
        // Sharp highlight on top edge
        context.stroke(
            topLine,
            with: .color(.white.opacity(0.12 + Double(smoothedAmplitude) * 0.3)),
            style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
        )
    }
    
    private func updateSpectrum(samples: [Float]) {
        guard samples.count >= 512 else { return }
        
        // Perform FFT
        let fftMagnitudes = performFFT(samples: samples)
        guard !fftMagnitudes.isEmpty else { return }
        
        // Map FFT bins to our band count using logarithmic scale
        let nyquist = Float(sampleRate) / 2
        let binCount = fftMagnitudes.count
        
        var newEnergies = [CGFloat](repeating: 0, count: bandCount)
        var totalEnergy: CGFloat = 0
        
        for i in 0..<bandCount {
            // Logarithmic frequency mapping
            let t = Float(i) / Float(bandCount - 1)
            let freq = minFrequency * pow(maxFrequency / minFrequency, t)
            
            let binIndex = Int(freq / nyquist * Float(binCount))
            
            if binIndex < binCount && binIndex >= 0 {
                var sum: Float = 0
                var count = 0
                let spread = max(1, binCount / bandCount / 2)
                
                for j in max(0, binIndex - spread)..<min(binCount, binIndex + spread + 1) {
                    sum += fftMagnitudes[j]
                    count += 1
                }
                
                let magnitude = count > 0 ? sum / Float(count) : 0
                let db = 20 * log10(max(magnitude, 1e-10))
                // Increased sensitivity: lower floor (-70dB) and boost factor
                // Makes quieter ambient sounds visible
                let normalizedDb = (db + 70) / 40 * 2.5
                newEnergies[i] = CGFloat(max(0, min(1, normalizedDb)))
                totalEnergy += newEnergies[i]
            }
        }
        
        // Smooth animation
        for i in 0..<bandCount {
            if newEnergies[i] > bandEnergies[i] {
                bandEnergies[i] += (newEnergies[i] - bandEnergies[i]) * 0.5
            } else {
                bandEnergies[i] += (newEnergies[i] - bandEnergies[i]) * 0.12
            }
        }

        // Update overall amplitude
        let avgEnergy = totalEnergy / CGFloat(bandCount)
        if avgEnergy > smoothedAmplitude {
            smoothedAmplitude += (avgEnergy - smoothedAmplitude) * 0.4
        } else {
            smoothedAmplitude += (avgEnergy - smoothedAmplitude) * 0.1
        }
    }
    
    private func performFFT(samples: [Float]) -> [Float] {
        let fftSize = 2048
        let log2n = vDSP_Length(log2(Float(fftSize)))
        
        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else {
            return []
        }
        defer { vDSP_destroy_fftsetup(fftSetup) }
        
        var windowedSamples = [Float](repeating: 0, count: fftSize)
        let startIndex = max(0, samples.count - fftSize)
        let samplesToCopy = min(fftSize, samples.count)
        
        for i in 0..<samplesToCopy {
            windowedSamples[i] = samples[startIndex + i]
        }
        
        var window = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
        vDSP_vmul(windowedSamples, 1, window, 1, &windowedSamples, 1, vDSP_Length(fftSize))
        
        var realp = [Float](repeating: 0, count: fftSize / 2)
        var imagp = [Float](repeating: 0, count: fftSize / 2)
        
        windowedSamples.withUnsafeBufferPointer { samplesPtr in
            realp.withUnsafeMutableBufferPointer { realpPtr in
                imagp.withUnsafeMutableBufferPointer { imagpPtr in
                    var splitComplex = DSPSplitComplex(
                        realp: realpPtr.baseAddress!,
                        imagp: imagpPtr.baseAddress!
                    )
                    
                    samplesPtr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: fftSize / 2) { complexPtr in
                        vDSP_ctoz(complexPtr, 2, &splitComplex, 1, vDSP_Length(fftSize / 2))
                    }
                    
                    vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))
                }
            }
        }
        
        var magnitudes = [Float](repeating: 0, count: fftSize / 2)
        realp.withUnsafeBufferPointer { realpPtr in
            imagp.withUnsafeBufferPointer { imagpPtr in
                var splitComplex = DSPSplitComplex(
                    realp: UnsafeMutablePointer(mutating: realpPtr.baseAddress!),
                    imagp: UnsafeMutablePointer(mutating: imagpPtr.baseAddress!)
                )
                vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(fftSize / 2))
            }
        }
        
        var sqrtMagnitudes = [Float](repeating: 0, count: fftSize / 2)
        vvsqrtf(&sqrtMagnitudes, magnitudes, [Int32(fftSize / 2)])
        
        var scale = Float(1.0 / Float(fftSize))
        vDSP_vsmul(sqrtMagnitudes, 1, &scale, &sqrtMagnitudes, 1, vDSP_Length(fftSize / 2))
        
        return sqrtMagnitudes
    }
    
    // MARK: - Color Helpers
    
    private func amplitudeColor(_ amp: Double) -> Color {
        if amp < 0.3 {
            let t = amp / 0.3
            return interpolateColor(from: Color(hex: "2a4a8a"), to: Color(hex: "3aafcf"), t: t)
        } else if amp < 0.6 {
            let t = (amp - 0.3) / 0.3
            return interpolateColor(from: Color(hex: "3aafcf"), to: Color(hex: "4ecdc4"), t: t)
        } else {
            let t = (amp - 0.6) / 0.4
            return interpolateColor(from: Color(hex: "4ecdc4"), to: Color(hex: "a8e6cf"), t: min(t, 1.0))
        }
    }
    
    private func amplitudeColorDark(_ amp: Double) -> Color {
        if amp < 0.3 {
            let t = amp / 0.3
            return interpolateColor(from: Color(hex: "1a2a4a"), to: Color(hex: "1a4a5a"), t: t)
        } else if amp < 0.6 {
            let t = (amp - 0.3) / 0.3
            return interpolateColor(from: Color(hex: "1a4a5a"), to: Color(hex: "2a5a5a"), t: t)
        } else {
            let t = (amp - 0.6) / 0.4
            return interpolateColor(from: Color(hex: "2a5a5a"), to: Color(hex: "3a6a5a"), t: min(t, 1.0))
        }
    }
    
    private func interpolateColor(from: Color, to: Color, t: Double) -> Color {
        let fromUI = UIColor(from)
        let toUI = UIColor(to)
        
        var fromR: CGFloat = 0, fromG: CGFloat = 0, fromB: CGFloat = 0, fromA: CGFloat = 0
        var toR: CGFloat = 0, toG: CGFloat = 0, toB: CGFloat = 0, toA: CGFloat = 0
        
        fromUI.getRed(&fromR, green: &fromG, blue: &fromB, alpha: &fromA)
        toUI.getRed(&toR, green: &toG, blue: &toB, alpha: &toA)
        
        let r = fromR + (toR - fromR) * t
        let g = fromG + (toG - fromG) * t
        let b = fromB + (toB - fromB) * t
        
        return Color(red: r, green: g, blue: b)
    }
}

#Preview {
    ZStack {
        Color(hex: "1a0a2e")
            .ignoresSafeArea()
        
        SpectrumAnalyzerView(
            samples: (0..<2048).map { Float(sin(Double($0) * 0.1) * 0.5) },
            sampleRate: 48000,
            isListening: true,
            detectedFrequency: 110
        )
        .frame(height: 200)
    }
}
