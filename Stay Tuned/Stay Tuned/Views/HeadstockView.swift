//
//  HeadstockView.swift
//  Stay Tuned
//
//  Created by Nick MacCarthy on 12/21/25.
//

import SwiftUI

/// Headstock style options
enum HeadstockStyle: String, CaseIterable {
    case martin = "Martin"
    case taylor = "Taylor"
}

/// Visual representation of a guitar headstock
struct HeadstockView: View {
    let tuning: Tuning
    let selectedString: GuitarString?
    let isInTune: Bool
    let tunedStrings: Set<Int>
    let onStringSelected: (GuitarString) -> Void
    var style: HeadstockStyle = .martin
    var playingToneStringId: Int? // Which string's tone is playing
    var onDoubleTap: ((GuitarString) -> Void)? // Double-tap to play tone
    var sizeClass: UserInterfaceSizeClass? // For adaptive sizing

    /// Tuner button size based on size class
    private var tunerButtonSize: CGFloat {
        LayoutConstants.tunerButtonSize(for: sizeClass)
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            // Headstock dimensions
            let headstockWidth = width * 0.85
            let headstockHeight = height * 0.90
            let headstockTop: CGFloat = 8
            let nutY = headstockTop + headstockHeight

            ZStack {
                // Headstock shape based on style
                Group {
                    switch style {
                    case .martin:
                        MartinHeadstockShape()
                            .stroke(Color(hex: "6a5a8a"), lineWidth: 2)
                    case .taylor:
                        TaylorHeadstockShape()
                            .stroke(Color(hex: "6a5a8a"), lineWidth: 2)
                    }
                }
                .frame(width: headstockWidth, height: headstockHeight)
                .position(x: width / 2, y: headstockTop + headstockHeight / 2)

                // Nut (bone colored bar at bottom of headstock)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "d4c8b8"))
                    .frame(width: headstockWidth * 0.60, height: 6)
                    .position(x: width / 2, y: nutY)

                // Short neck/fretboard below headstock
                neckView(width: width, height: height, headstockWidth: headstockWidth, nutY: nutY)

                // Strings running from tuners down through nut
                stringsView(width: width, height: height, headstockWidth: headstockWidth, headstockTop: headstockTop, headstockHeight: headstockHeight, nutY: nutY)

                // Left tuners (strings 3, 2, 1 = D, A, E from top to bottom)
                leftTuners(width: width, height: height, headstockWidth: headstockWidth, headstockTop: headstockTop, headstockHeight: headstockHeight)

                // Right tuners (strings 4, 5, 6 = G, B, E from top to bottom)
                rightTuners(width: width, height: height, headstockWidth: headstockWidth, headstockTop: headstockTop, headstockHeight: headstockHeight)
            }
        }
        .aspectRatio(0.52, contentMode: .fit)
    }

    @ViewBuilder
    private func neckView(width: CGFloat, height: CGFloat, headstockWidth: CGFloat, nutY: CGFloat) -> some View {
        let neckWidth = headstockWidth * 0.55

        // Neck sides
        Path { path in
            path.move(to: CGPoint(x: width / 2 - neckWidth / 2, y: nutY))
            path.addLine(to: CGPoint(x: width / 2 - neckWidth / 2 - 2, y: height))
        }
        .stroke(Color(hex: "6a5a8a"), lineWidth: 2)

        Path { path in
            path.move(to: CGPoint(x: width / 2 + neckWidth / 2, y: nutY))
            path.addLine(to: CGPoint(x: width / 2 + neckWidth / 2 + 2, y: height))
        }
        .stroke(Color(hex: "6a5a8a"), lineWidth: 2)

        // 1 fret
        let neckLength = height - nutY
        let fretY = nutY + neckLength * 0.5
        Rectangle()
            .fill(Color(hex: "8a7aaa"))
            .frame(width: neckWidth + 4, height: 3)
            .position(x: width / 2, y: fretY)
    }

    @ViewBuilder
    private func leftTuners(width: CGFloat, height _: CGFloat, headstockWidth: CGFloat, headstockTop: CGFloat, headstockHeight: CGFloat) -> some View {
        let indices = [2, 1, 0] // D, A, E (low) from top to bottom
        // Position on the flat sides - start higher, closer together
        let tunerAreaTop = headstockTop + headstockHeight * 0.08
        let spacing = headstockHeight * 0.22 // Tighter spacing
        let tunerX = width / 2 - headstockWidth * 0.42 // More toward edge

        ForEach(0 ..< 3, id: \.self) { i in
            let string = tuning.strings[indices[i]]
            let y = tunerAreaTop + CGFloat(i) * spacing

            HStack(spacing: 2) {
                TunerButton(
                    string: string,
                    isSelected: selectedString?.id == string.id,
                    isInTune: (selectedString?.id == string.id && isInTune) || tunedStrings.contains(string.id),
                    isTuned: tunedStrings.contains(string.id),
                    isPlayingTone: playingToneStringId == string.id,
                    onTap: { onStringSelected(string) },
                    onDoubleTap: { onDoubleTap?(string) },
                    buttonSize: tunerButtonSize
                )

                TunerPost(isSelected: selectedString?.id == string.id)
            }
            .position(x: tunerX, y: y)
        }
    }

    @ViewBuilder
    private func rightTuners(width: CGFloat, height _: CGFloat, headstockWidth: CGFloat, headstockTop: CGFloat, headstockHeight: CGFloat) -> some View {
        let indices = [3, 4, 5] // G, B, E (high) from top to bottom
        // Position on the flat sides - start higher, closer together
        let tunerAreaTop = headstockTop + headstockHeight * 0.08
        let spacing = headstockHeight * 0.22 // Tighter spacing
        let tunerX = width / 2 + headstockWidth * 0.42 // More toward edge

        ForEach(0 ..< 3, id: \.self) { i in
            let string = tuning.strings[indices[i]]
            let y = tunerAreaTop + CGFloat(i) * spacing

            HStack(spacing: 2) {
                TunerPost(isSelected: selectedString?.id == string.id)

                TunerButton(
                    string: string,
                    isSelected: selectedString?.id == string.id,
                    isInTune: (selectedString?.id == string.id && isInTune) || tunedStrings.contains(string.id),
                    isTuned: tunedStrings.contains(string.id),
                    isPlayingTone: playingToneStringId == string.id,
                    onTap: { onStringSelected(string) },
                    onDoubleTap: { onDoubleTap?(string) },
                    buttonSize: tunerButtonSize
                )
            }
            .position(x: tunerX, y: y)
        }
    }

    @ViewBuilder
    private func stringsView(width: CGFloat, height: CGFloat, headstockWidth: CGFloat, headstockTop: CGFloat, headstockHeight: CGFloat, nutY: CGFloat) -> some View {
        let neckWidth = headstockWidth * 0.50
        let stringSpacing = neckWidth / 5
        let nutStartX = width / 2 - neckWidth / 2

        // Match tuner positions
        let tunerAreaTop = headstockTop + headstockHeight * 0.08
        let tunerSpacing = headstockHeight * 0.22

        ForEach(0 ..< 6, id: \.self) { stringId in
            let string = tuning.strings[stringId]
            let isSelected = selectedString?.id == string.id
            let isTuned = tunedStrings.contains(string.id)

            let isLeft = stringId <= 2
            let pegIndex = isLeft ? (2 - stringId) : (stringId - 3)
            let pegY = tunerAreaTop + CGFloat(pegIndex) * tunerSpacing
            // Peg position near the tuner post (inside edge of tuner buttons)
            let pegX = isLeft ? (width / 2 - headstockWidth * 0.28) : (width / 2 + headstockWidth * 0.28)

            let nutX = nutStartX + stringSpacing * CGFloat(stringId) + stringSpacing / 2

            // String from peg to nut - straight lines like real guitars
            Path { path in
                path.move(to: CGPoint(x: pegX, y: pegY))
                path.addLine(to: CGPoint(x: nutX, y: nutY))
            }
            .stroke(stringColor(isSelected: isSelected, isTuned: isTuned), lineWidth: isSelected ? 2 : 1)

            // String down neck
            Path { path in
                path.move(to: CGPoint(x: nutX, y: nutY))
                path.addLine(to: CGPoint(x: nutX, y: height))
            }
            .stroke(stringColor(isSelected: isSelected, isTuned: isTuned), lineWidth: isSelected ? 2 : 1)
        }
    }

    private func stringColor(isSelected: Bool, isTuned: Bool) -> Color {
        if isSelected { return Color(hex: "9B59B6") }
        if isTuned { return Color.green.opacity(0.6) }
        return Color(hex: "7a6a9a").opacity(0.5)
    }
}

// MARK: - Martin Headstock Shape

/// Martin-style solid headstock - rectangular with rounded top corners
struct MartinHeadstockShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        let cornerRadius = w * 0.10
        let neckWidth = w * 0.52
        let shoulderY = h * 0.82

        // Start at top-left corner
        path.move(to: CGPoint(x: cornerRadius, y: 0))

        // Top edge
        path.addLine(to: CGPoint(x: w - cornerRadius, y: 0))

        // Top-right corner
        path.addQuadCurve(
            to: CGPoint(x: w, y: cornerRadius),
            control: CGPoint(x: w, y: 0)
        )

        // Right side - straight down
        path.addLine(to: CGPoint(x: w, y: shoulderY * 0.7))

        // Right shoulder curves into neck
        path.addQuadCurve(
            to: CGPoint(x: w / 2 + neckWidth / 2, y: shoulderY),
            control: CGPoint(x: w * 0.80, y: shoulderY * 0.85)
        )

        // Neck right side
        path.addLine(to: CGPoint(x: w / 2 + neckWidth / 2, y: h))

        // Neck bottom (open)
        path.addLine(to: CGPoint(x: w / 2 - neckWidth / 2, y: h))

        // Neck left side
        path.addLine(to: CGPoint(x: w / 2 - neckWidth / 2, y: shoulderY))

        // Left shoulder curves out
        path.addQuadCurve(
            to: CGPoint(x: 0, y: shoulderY * 0.7),
            control: CGPoint(x: w * 0.20, y: shoulderY * 0.85)
        )

        // Left side - straight up
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))

        // Top-left corner
        path.addQuadCurve(
            to: CGPoint(x: cornerRadius, y: 0),
            control: CGPoint(x: 0, y: 0)
        )

        path.closeSubpath()
        return path
    }
}

// MARK: - Taylor Headstock Shape

/// Taylor-style headstock - pointed peak at top center with angled shoulders
struct TaylorHeadstockShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        let peakY: CGFloat = 0 // Top of peak
        let shoulderY = h * 0.12 // Where the angled top meets the sides
        let neckStartY = h * 0.82 // Where shoulders curve into neck
        let neckWidth = w * 0.52

        // Start at peak (top center)
        path.move(to: CGPoint(x: w / 2, y: peakY))

        // Right angled edge from peak to shoulder
        path.addLine(to: CGPoint(x: w * 0.92, y: shoulderY))

        // Small corner radius at right shoulder
        path.addQuadCurve(
            to: CGPoint(x: w, y: shoulderY + w * 0.06),
            control: CGPoint(x: w, y: shoulderY)
        )

        // Right side - straight down
        path.addLine(to: CGPoint(x: w, y: neckStartY * 0.75))

        // Right shoulder curves into neck
        path.addQuadCurve(
            to: CGPoint(x: w / 2 + neckWidth / 2, y: neckStartY),
            control: CGPoint(x: w * 0.78, y: neckStartY * 0.88)
        )

        // Neck right side
        path.addLine(to: CGPoint(x: w / 2 + neckWidth / 2, y: h))

        // Neck bottom (open for fretboard)
        path.addLine(to: CGPoint(x: w / 2 - neckWidth / 2, y: h))

        // Neck left side
        path.addLine(to: CGPoint(x: w / 2 - neckWidth / 2, y: neckStartY))

        // Left shoulder curves out
        path.addQuadCurve(
            to: CGPoint(x: 0, y: neckStartY * 0.75),
            control: CGPoint(x: w * 0.22, y: neckStartY * 0.88)
        )

        // Left side - straight up
        path.addLine(to: CGPoint(x: 0, y: shoulderY + w * 0.06))

        // Small corner radius at left shoulder
        path.addQuadCurve(
            to: CGPoint(x: w * 0.08, y: shoulderY),
            control: CGPoint(x: 0, y: shoulderY)
        )

        // Left angled edge back to peak
        path.addLine(to: CGPoint(x: w / 2, y: peakY))

        path.closeSubpath()
        return path
    }
}

// MARK: - Tuner Components

/// Hexagonal tuner button with single-tap to select and double-tap to play tone
struct TunerButton: View {
    let string: GuitarString
    let isSelected: Bool
    let isInTune: Bool
    let isTuned: Bool
    var isPlayingTone: Bool = false
    let onTap: () -> Void
    var onDoubleTap: (() -> Void)?
    var buttonSize: CGFloat = 46 // Adaptive size based on device

    /// Font size scales with button size
    private var fontSize: CGFloat {
        buttonSize * 0.35
    }

    /// Icon offset scales with button size
    private var iconOffset: CGFloat {
        buttonSize * 0.30
    }

    var body: some View {
        ZStack {
            HexagonShape()
                .fill(fillColor)
                .frame(width: buttonSize, height: buttonSize)

            HexagonShape()
                .stroke(strokeColor, lineWidth: isSelected ? 2.5 : 1.5)
                .frame(width: buttonSize, height: buttonSize)

            Text(string.name)
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundColor(textColor)

            // Tuned checkmark
            if isTuned, !isPlayingTone {
                Image(systemName: "checkmark")
                    .font(.system(size: buttonSize * 0.17, weight: .bold))
                    .foregroundColor(.green)
                    .offset(x: iconOffset, y: -iconOffset)
            }

            // Speaker icon when playing tone
            if isPlayingTone {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: buttonSize * 0.17, weight: .bold))
                    .foregroundColor(Color(hex: "4ECDC4"))
                    .symbolEffect(.pulse, options: .repeating)
                    .offset(x: iconOffset, y: -iconOffset)
            }
        }
        .shadow(color: shadowColor, radius: shadowRadius)
        .onTapGesture(count: 2) {
            onDoubleTap?()
        }
        .onTapGesture(count: 1) {
            onTap()
        }
    }

    private var fillColor: Color {
        if isPlayingTone {
            return Color(hex: "4ECDC4").opacity(0.15)
        } else if isInTune {
            return Color.green.opacity(0.15)
        }
        return Color(hex: "1a0a2e")
    }

    private var strokeColor: Color {
        if isPlayingTone {
            return Color(hex: "4ECDC4")
        } else if isInTune {
            return Color.green
        } else if isSelected {
            return Color(hex: "b8a8d8")
        }
        return Color(hex: "4a3a6a")
    }

    private var textColor: Color {
        if isPlayingTone {
            return Color(hex: "4ECDC4")
        } else if isInTune {
            return .green
        } else if isSelected {
            return .white
        }
        return Color(hex: "7a6a9a")
    }

    private var shadowColor: Color {
        if isPlayingTone {
            return Color(hex: "4ECDC4").opacity(0.5)
        } else if isInTune {
            return .green.opacity(0.4)
        }
        return .clear
    }

    private var shadowRadius: CGFloat {
        (isPlayingTone || isInTune) ? 6 : 0
    }
}

/// Small tuner post (the metal cylinder strings wrap around)
struct TunerPost: View {
    let isSelected: Bool

    var body: some View {
        Circle()
            .fill(Color(hex: "4a3a6a"))
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .fill(isSelected ? Color(hex: "9B59B6") : Color(hex: "3a2a5a"))
                    .frame(width: 6, height: 6)
            )
    }
}

/// Hexagon shape for tuner buttons
struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(rect.width, rect.height) / 2

        for i in 0 ..< 6 {
            let angle = CGFloat(i) * .pi / 3 - .pi / 6
            let x = rect.midX + radius * cos(angle)
            let y = rect.midY + radius * sin(angle)

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Previews

#Preview("Taylor Style") {
    ZStack {
        Color(hex: "1a0a2e")
            .ignoresSafeArea()

        HeadstockView(
            tuning: .standard,
            selectedString: Tuning.standard.strings[4],
            isInTune: false,
            tunedStrings: [0, 1, 2],
            onStringSelected: { _ in },
            style: .taylor
        )
        .frame(height: 420)
        .padding(.horizontal, 40)
    }
}

#Preview("Martin Style") {
    ZStack {
        Color(hex: "1a0a2e")
            .ignoresSafeArea()

        HeadstockView(
            tuning: .standard,
            selectedString: Tuning.standard.strings[2],
            isInTune: true,
            tunedStrings: [0, 1, 2, 3],
            onStringSelected: { _ in },
            style: .martin
        )
        .frame(height: 420)
        .padding(.horizontal, 40)
    }
}
