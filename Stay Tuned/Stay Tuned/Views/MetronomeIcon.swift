//
//  MetronomeIcon.swift
//  Stay Tuned
//
//  Created for Phase 6: Metronome
//

import SwiftUI

/// Custom metronome icon shape - geometric design with triangle body, arc, and pendulum
struct MetronomeIcon: Shape {
    
    /// Pendulum angle for animation (-1 to 1, where 0 is center)
    var pendulumPosition: CGFloat = 0
    
    var animatableData: CGFloat {
        get { pendulumPosition }
        set { pendulumPosition = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Define key points
        let centerX = rect.midX
        let triangleTop = height * 0.35
        let triangleBottom = height * 0.95
        let triangleHalfWidth = width * 0.38
        
        // Arc parameters
        let arcCenterY = height * 0.18
        let arcRadius = width * 0.32
        
        // Pendulum pivot point (at the arc center)
        let pivotX = centerX
        let pivotY = arcCenterY
        
        // MARK: - Draw Arc (pendulum swing range)
        let arcStartAngle = Angle(degrees: 210)
        let arcEndAngle = Angle(degrees: 330)
        
        path.addArc(
            center: CGPoint(x: centerX, y: arcCenterY),
            radius: arcRadius,
            startAngle: arcStartAngle,
            endAngle: arcEndAngle,
            clockwise: false
        )
        
        // MARK: - Draw Triangle Body
        path.move(to: CGPoint(x: centerX, y: triangleTop))
        path.addLine(to: CGPoint(x: centerX - triangleHalfWidth, y: triangleBottom))
        path.addLine(to: CGPoint(x: centerX + triangleHalfWidth, y: triangleBottom))
        path.closeSubpath()
        
        // MARK: - Draw Pendulum Arm
        // Pendulum swings based on pendulumPosition (-1 to 1)
        let maxSwingAngle: CGFloat = 35  // degrees
        let swingAngle = pendulumPosition * maxSwingAngle
        let pendulumAngleRad = (90 + swingAngle) * .pi / 180
        
        let pendulumLength = height * 0.55
        let pendulumEndX = pivotX + cos(pendulumAngleRad) * pendulumLength
        let pendulumEndY = pivotY + sin(pendulumAngleRad) * pendulumLength
        
        path.move(to: CGPoint(x: pivotX, y: pivotY))
        path.addLine(to: CGPoint(x: pendulumEndX, y: pendulumEndY))
        
        // Small circle at pendulum weight
        let weightRadius = width * 0.06
        path.addEllipse(in: CGRect(
            x: pendulumEndX - weightRadius,
            y: pendulumEndY - weightRadius,
            width: weightRadius * 2,
            height: weightRadius * 2
        ))
        
        return path
    }
}

/// Animated version that swings the pendulum when active
/// Driven by currentBeat to stay synced with audio
struct AnimatedMetronomeIcon: View {
    var isAnimating: Bool = false
    var currentBeat: Int = 1
    var tempo: Double = 120
    var size: CGFloat = 24
    var color: Color = Color(hex: "9a8aba")
    
    @State private var pendulumPosition: CGFloat = 0
    
    /// Duration for one full swing (one beat)
    private var beatDuration: Double {
        60.0 / tempo
    }
    
    var body: some View {
        MetronomeIcon(pendulumPosition: pendulumPosition)
            .stroke(color, style: StrokeStyle(lineWidth: size * 0.05, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
            .onChange(of: currentBeat) { _, beat in
                if isAnimating {
                    // Swing AWAY from current beat position toward opposite side
                    // Odd beats = pendulum at left, swing to right (+1)
                    // Even beats = pendulum at right, swing to left (-1)
                    let targetPosition: CGFloat = beat % 2 == 1 ? 1 : -1
                    // Smooth glide over the full beat duration
                    withAnimation(.easeInOut(duration: beatDuration)) {
                        pendulumPosition = targetPosition
                    }
                }
            }
            .onChange(of: isAnimating) { _, animating in
                if !animating {
                    // Return to center when stopped
                    withAnimation(.easeOut(duration: 0.3)) {
                        pendulumPosition = 0
                    }
                }
            }
    }
}

#Preview {
    VStack(spacing: 40) {
        // Static icon
        MetronomeIcon()
            .stroke(Color(hex: "4ECDC4"), style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
            .frame(width: 40, height: 40)
        
        // Animated icon (beat-driven)
        AnimatedMetronomeIcon(isAnimating: true, currentBeat: 1, tempo: 120, size: 60, color: Color(hex: "4ECDC4"))
    }
    .padding()
    .background(Color(hex: "1a0a2e"))
}

