//
//  AudioWaveformView.swift
//  Stay Tuned
//
//  Created by Nick MacCarthy on 12/24/25.
//

import SwiftUI

/// A fluid, spectrum-analyzer style audio visualization
struct AudioWaveformView: View {
    
    // MARK: - Configuration
    
    /// Number of frequency bands (control points) for the wave visualization.
    /// Higher values = more wave peaks/valleys, more detailed frequency response.
    /// Lower values = fewer, broader waves.
    /// Recommended range: 100-600. Default: 300.
    private static let frequencyBandCount = 300
    
    // MARK: - Input Properties
    
    /// Target amplitude from 0.0 (silent) to 1.0 (loud)
    let amplitude: Double
    
    /// Whether the tuner is actively listening
    let isListening: Bool
    
    // MARK: - State
    
    // Smoothed overall amplitude
    @State private var smoothedAmplitude: Double = 0.0
    
    // Frequency band energies - each band represents a portion of the audio spectrum
    @State private var bandEnergies: [Double] = Array(repeating: 0.0, count: frequencyBandCount)
    
    // Time for subtle organic movement
    @State private var time: Double = 0
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/60)) { timeline in
            Canvas { context, size in
                drawSpectrumWave(context: context, size: size)
            }
            .onChange(of: timeline.date) { _, _ in
                time += 0.016
                
                // Smooth overall amplitude
                if amplitude > smoothedAmplitude {
                    smoothedAmplitude += (amplitude - smoothedAmplitude) * 0.30
                } else {
                    smoothedAmplitude += (amplitude - smoothedAmplitude) * 0.08
                }
                
                // Update each frequency band
                for i in 0..<bandEnergies.count {
                    let bandPosition = Double(i) / Double(bandEnergies.count - 1)
                    
                    // Natural frequency distribution
                    let bassBump = exp(-pow((bandPosition - 0.15) * 4, 2)) * 0.8
                    let midBump = exp(-pow((bandPosition - 0.45) * 3, 2)) * 1.0
                    let trebleBump = exp(-pow((bandPosition - 0.75) * 4, 2)) * 0.6
                    
                    let frequencyWeight = bassBump + midBump + trebleBump
                    
                    // Variation per band
                    let variation = sin(time * 2 + Double(i) * 0.5) * 0.15 +
                                   sin(time * 3.7 + Double(i) * 0.3) * 0.1
                    
                    let bandTarget = amplitude * frequencyWeight * (0.85 + variation)
                    
                    // Fast rise, medium fall
                    if bandTarget > bandEnergies[i] {
                        bandEnergies[i] += (bandTarget - bandEnergies[i]) * 0.35
                    } else {
                        bandEnergies[i] += (bandTarget - bandEnergies[i]) * 0.12
                    }
                    
                    bandEnergies[i] = max(0, min(1, bandEnergies[i]))
                }
            }
        }
        .opacity(isListening ? 0.5 : 0.15)
        .animation(.easeInOut(duration: 0.8), value: isListening)
    }
    
    private func drawSpectrumWave(context: GraphicsContext, size: CGSize) {
        let width = size.width
        let height = size.height
        
        // Base position
        let minHeight: CGFloat = 25
        let maxHeight: CGFloat = height * 0.28
        let baseFluidHeight = minHeight + CGFloat(smoothedAmplitude) * (maxHeight - minHeight) * 0.3
        let baseY = height - baseFluidHeight
        
        // Create control points from band energies
        var controlPoints: [CGPoint] = []
        
        for i in 0..<bandEnergies.count {
            let x = (CGFloat(i) / CGFloat(bandEnergies.count - 1)) * width
            let energy = CGFloat(bandEnergies[i])
            let bandHeight = energy * maxHeight * 0.85
            let y = baseY - bandHeight
            controlPoints.append(CGPoint(x: x, y: y))
        }
        
        // Build smooth path using quadratic bezier curves
        var path = Path()
        path.move(to: CGPoint(x: -10, y: height + 10))
        path.addLine(to: CGPoint(x: -10, y: baseY))
        
        if controlPoints.count >= 2 {
            // Start at first point
            path.addLine(to: controlPoints[0])
            
            // Draw smooth curves through all points
            for i in 0..<controlPoints.count - 1 {
                let current = controlPoints[i]
                let next = controlPoints[i + 1]
                
                // Calculate control point for smooth curve
                let midX = (current.x + next.x) / 2
                let midY = (current.y + next.y) / 2
                
                // Use quadratic curve to midpoint, then to next point
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
        
        // Color based on amplitude
        let baseColor = amplitudeColor(smoothedAmplitude)
        let darkColor = amplitudeColorDark(smoothedAmplitude)
        
        let minY = controlPoints.map { $0.y }.min() ?? baseY
        
        let gradient = Gradient(stops: [
            .init(color: baseColor.opacity(0.9), location: 0.0),
            .init(color: baseColor.opacity(0.55), location: 0.3),
            .init(color: darkColor.opacity(0.35), location: 0.65),
            .init(color: Color(hex: "0a0a15").opacity(0.2), location: 1.0)
        ])
        
        let linearGradient = GraphicsContext.Shading.linearGradient(
            gradient,
            startPoint: CGPoint(x: width / 2, y: minY - 20),
            endPoint: CGPoint(x: width / 2, y: height)
        )
        
        // Glow layer
        context.drawLayer { glowContext in
            glowContext.addFilter(.blur(radius: 25))
            glowContext.fill(path, with: .color(baseColor.opacity(0.2 + smoothedAmplitude * 0.3)))
        }
        
        // Main fill
        context.fill(path, with: linearGradient)
        
        // Top edge - rebuild just the top curve
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
                with: .color(baseColor.opacity(0.5 + smoothedAmplitude * 0.3)),
                style: StrokeStyle(lineWidth: 5, lineCap: .round)
            )
        }
        
        // Sharp highlight
        context.stroke(
            topLine,
            with: .color(.white.opacity(0.15 + smoothedAmplitude * 0.35)),
            style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
        )
    }
    
    /// Color based on amplitude: blue → cyan → orange → red
    private func amplitudeColor(_ amp: Double) -> Color {
        if amp < 0.3 {
            let t = amp / 0.3
            return interpolateColor(
                from: Color(hex: "2a4a8a"),
                to: Color(hex: "3aafcf"),
                t: t
            )
        } else if amp < 0.6 {
            let t = (amp - 0.3) / 0.3
            return interpolateColor(
                from: Color(hex: "3aafcf"),
                to: Color(hex: "df8a3a"),
                t: t
            )
        } else {
            let t = (amp - 0.6) / 0.4
            return interpolateColor(
                from: Color(hex: "df8a3a"),
                to: Color(hex: "df3a3a"),
                t: min(t, 1.0)
            )
        }
    }
    
    private func amplitudeColorDark(_ amp: Double) -> Color {
        if amp < 0.3 {
            let t = amp / 0.3
            return interpolateColor(
                from: Color(hex: "1a2a4a"),
                to: Color(hex: "1a4a5a"),
                t: t
            )
        } else if amp < 0.6 {
            let t = (amp - 0.3) / 0.3
            return interpolateColor(
                from: Color(hex: "1a4a5a"),
                to: Color(hex: "4a3a1a"),
                t: t
            )
        } else {
            let t = (amp - 0.6) / 0.4
            return interpolateColor(
                from: Color(hex: "4a3a1a"),
                to: Color(hex: "4a1a1a"),
                t: min(t, 1.0)
            )
        }
    }
    
    private func interpolateColor(from: Color, to: Color, t: Double) -> Color {
        let fromUI = UIColor(from)
        let toUI = UIColor(to)
        
        var fromR: CGFloat = 0, fromG: CGFloat = 0, fromB: CGFloat = 0, fromA: CGFloat = 0
        var toR: CGFloat = 0, toG: CGFloat = 0, toB: CGFloat = 0, toA: CGFloat = 0
        
        fromUI.getRed(&fromR, green: &fromG, blue: &fromB, alpha: &fromA)
        toUI.getRed(&toR, green: &toG, blue: &toB, alpha: &toA)
        
        let r = fromR + (toR - fromR) * CGFloat(t)
        let g = fromG + (toG - fromG) * CGFloat(t)
        let b = fromB + (toB - fromB) * CGFloat(t)
        let a = fromA + (toA - fromA) * CGFloat(t)
        
        return Color(red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color(hex: "1a0a2e"),
                Color(hex: "2d1b4e"),
                Color(hex: "1a0a2e")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        AudioWaveformView(amplitude: 0.6, isListening: true)
    }
}
