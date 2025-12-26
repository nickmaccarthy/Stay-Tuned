//
//  TuningMeterView.swift
//  Stay Tuned
//
//  Created by Nick MacCarthy on 12/21/25.
//

import SwiftUI

/// Displays the tuning meter with needle indicator and cents deviation
struct TuningMeterView: View {
    let centsDeviation: Int
    let isInTune: Bool
    let selectedString: GuitarString?
    var showConfirmation: Bool = false
    var sustainedInTune: Bool = false  // True when in tune for 2+ seconds
    var detectedFrequency: Double = 0  // Current detected Hz
    var targetFrequency: Double = 0  // Adjusted target Hz (accounts for reference pitch)
    var currentDecibels: Float?  // Current dB level when detecting
    var chromaticNote: ChromaticNote? = nil  // For chromatic mode
    
    /// Animation state for the needle
    @State private var animatedCents: Double = 0
    
    private let meterRange: ClosedRange<Int> = -50...50
    private let tickCount = 25
    
    var body: some View {
        VStack(spacing: 16) {
            // Status text - fixed height to prevent layout shift
            statusText
                .frame(height: 60)
            
            // Main meter
            meterView
            
            // Cents display
            centsDisplay
            
            // dB reading below cents - always reserve space to prevent layout shift
            Text(currentDecibels.map { String(format: "%.0f dB", $0) } ?? " ")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(Color(hex: "9a8aba").opacity(0.8))
                .opacity(currentDecibels != nil ? 1 : 0)
        }
        .onChange(of: centsDeviation) { _, newValue in
            withAnimation(.spring(response: 0.015, dampingFraction: 0.9)) {
                animatedCents = Double(newValue)
            }
        }
    }
    
    @ViewBuilder
    private var statusText: some View {
        if showConfirmation {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Perfect!")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
            }
        } else if let note = chromaticNote {
            // Chromatic mode display
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Text(note.fullName)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(sustainedInTune ? .green : .white)
                    
                    if sustainedInTune {
                        Text("In Tune")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.green)
                    } else if centsDeviation != 0 {
                        Text(centsDeviation > 0 ? "Too high" : "Too low")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "9a8aba"))
                    }
                }
                
                // Hz reading for chromatic mode
                HStack(spacing: 4) {
                    Text(String(format: "%.1f Hz", note.frequency))
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(isInTune ? .green.opacity(0.9) : Color(hex: "b8a8d8"))
                    
                    Text("→")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "9a8aba"))
                    
                    Text(String(format: "%.1f Hz", note.targetFrequency))
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.green)
                }
            }
        } else if let string = selectedString {
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Text(string.fullName)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(sustainedInTune ? .green : .white)
                    
                    if sustainedInTune {
                        Text("In Tune")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.green)
                    } else if centsDeviation != 0 {
                        Text(centsDeviation > 0 ? "Too high" : "Too low")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "9a8aba"))
                    }
                }
                
                // Hz reading - always reserve space to prevent layout shift
                HStack(spacing: 4) {
                    Text(detectedFrequency > 0 ? String(format: "%.1f Hz", detectedFrequency) : "--- Hz")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(isInTune ? .green.opacity(0.9) : Color(hex: "b8a8d8"))
                    
                    Text("→")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "9a8aba"))
                    
                    // Use adjusted target frequency if provided, otherwise fall back to string.frequency
                    Text(String(format: "%.1f Hz", targetFrequency > 0 ? targetFrequency : string.frequency))
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.green)
                }
                .opacity(detectedFrequency > 0 ? 1 : 0)
            }
        } else {
            Text("Play a note")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(hex: "9a8aba"))
        }
    }
    
    private var meterView: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            ZStack {
                // Tick marks
                HStack(spacing: 0) {
                    ForEach(0..<tickCount, id: \.self) { index in
                        let isCenterTick = index == tickCount / 2
                        let isQuarterTick = index % (tickCount / 4) == 0
                        
                        Rectangle()
                            .fill(tickColor(for: index))
                            .frame(
                                width: isCenterTick ? 3 : 1.5,
                                height: isCenterTick ? 50 : (isQuarterTick ? 35 : 20)
                            )
                        
                        if index < tickCount - 1 {
                            Spacer()
                        }
                    }
                }
                .frame(width: width - 40)
                
                // Left and right boundary markers
                HStack {
                    Rectangle()
                        .fill(Color(hex: "7c6c9a"))
                        .frame(width: 2, height: 60)
                    
                    Spacer()
                    
                    Rectangle()
                        .fill(Color(hex: "7c6c9a"))
                        .frame(width: 2, height: 60)
                }
                .frame(width: width)
                
                // Needle indicator
                needleIndicator(width: width, height: height)
            }
            .frame(width: width, height: height)
        }
        .frame(height: 70)
        .padding(.horizontal, 20)
    }
    
    private func tickColor(for index: Int) -> Color {
        let centerIndex = tickCount / 2
        let distanceFromCenter = abs(index - centerIndex)
        
        // Center tick is brightest
        if distanceFromCenter == 0 {
            return .white
        } else if distanceFromCenter <= 3 {
            // In-tune zone ±7 cents (green area)
            return Color(hex: "6a9a7a")
        } else {
            // Out of tune (gradient to red at edges)
            let intensity = Double(distanceFromCenter) / Double(tickCount / 2)
            return Color(hex: "b8a8d8").opacity(1 - intensity * 0.5)
        }
    }
    
    private func needleIndicator(width: CGFloat, height: CGFloat) -> some View {
        let meterWidth = width - 40
        
        // Compress the visual range for in-tune readings (±5 cents)
        // This makes small deviations look more centered
        var displayCents = animatedCents
        if abs(displayCents) <= 7 {
            // Within ±5 cents: compress to ±2 visual range (feels more "locked in")
            displayCents = displayCents * 0.4
        }
        
        let normalizedPosition = (displayCents + 50) / 100
        let xPosition = 20 + meterWidth * normalizedPosition
        
        return VStack(spacing: 0) {
            // Needle line
            Rectangle()
                .fill(needleColor)
                .frame(width: 3, height: 55)
            
            // Triangle pointer
            Triangle()
                .fill(needleColor)
                .frame(width: 12, height: 8)
        }
        .shadow(color: needleColor.opacity(0.6), radius: 4)
        .position(x: xPosition, y: height / 2)
    }
    
    private var needleColor: Color {
        if showConfirmation || isInTune {
            return .green
        } else {
            let deviation = abs(centsDeviation)
            if deviation > 30 {
                return .red
            } else if deviation > 15 {
                return .orange
            } else {
                return .yellow
            }
        }
    }
    
    private var centsDisplay: some View {
        HStack {
            if showConfirmation {
                Text("Locked In!")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.green.opacity(0.2))
                            .stroke(Color.green.opacity(0.5), lineWidth: 1)
                    )
            } else if isInTune {
                // Within ±5 cents - show green even if not exactly 0
                let displayText = centsDeviation == 0 ? "Perfect" : (centsDeviation > 0 ? "+\(centsDeviation)" : "\(centsDeviation)")
                Text(displayText)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.green.opacity(0.2))
                            .stroke(Color.green.opacity(0.5), lineWidth: 1)
                    )
            } else if centsDeviation != 0 {
                // Outside ±5 cents - show orange/red
                Text(centsDeviation > 0 ? "+\(centsDeviation)" : "\(centsDeviation)")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(centsDeviation > 0 ? .red : .orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.black.opacity(0.3))
                            .stroke(centsDeviation > 0 ? Color.red.opacity(0.5) : Color.orange.opacity(0.5), lineWidth: 1)
                    )
            } else {
                // Exactly 0 and in tune
                Text("Perfect")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.green.opacity(0.2))
                            .stroke(Color.green.opacity(0.5), lineWidth: 1)
                    )
            }
        }
        .frame(height: 30)
    }
}

/// Triangle shape for the needle pointer
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    ZStack {
        Color(hex: "1a0a2e")
            .ignoresSafeArea()
        
        VStack(spacing: 40) {
            TuningMeterView(
                centsDeviation: 0,
                isInTune: true,
                selectedString: Tuning.standard.strings[2],
                showConfirmation: true
            )
            
            TuningMeterView(
                centsDeviation: 18,
                isInTune: false,
                selectedString: Tuning.standard.strings[0]
            )
            
            TuningMeterView(
                centsDeviation: -25,
                isInTune: false,
                selectedString: Tuning.standard.strings[4]
            )
        }
        .padding()
    }
}
