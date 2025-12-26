//
//  ToneTypeView.swift
//  Stay Tuned
//
//  Settings view for selecting reference tone type
//

import SwiftUI

/// View for selecting the reference tone type
struct ToneTypeView: View {
    @Binding var toneType: ToneType
    
    var body: some View {
        ZStack {
            // Background gradient matching app theme
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
            
            ScrollView {
                VStack(spacing: 24) {
                    // Current selection display
                    VStack(spacing: 8) {
                        Image(systemName: toneType.iconName)
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(Color(hex: "4ECDC4"))
                        
                        Text(toneType.displayName)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(toneType.description)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "9a8aba"))
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 8)
                    
                    // Tone type options
                    VStack(spacing: 12) {
                        ForEach(ToneType.allCases) { type in
                            toneTypeButton(type: type)
                        }
                    }
                    
                    // Explanation blurb
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About Reference Tones")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "9a8aba"))
                        
                        Text("**Sine Wave** produces a pure, clean tone that's easy to match precisely. It's the classic tuner sound.\n\n**Plucked String** uses physical modeling to create a realistic guitar-like sound. Double-tap a tuning peg to hear the reference tone and \"re-pluck\" by tapping again.")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "7c6c9a"))
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
                    .padding(.top, 8)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationTitle("Reference Tone")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(hex: "1a0a2e"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    private func toneTypeButton(type: ToneType) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                toneType = type
            }
        } label: {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: type.iconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(toneType == type ? Color(hex: "1a0a2e") : Color(hex: "4ECDC4"))
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(toneType == type ? Color(hex: "4ECDC4") : Color(hex: "4ECDC4").opacity(0.15))
                    )
                
                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(toneType == type ? Color(hex: "1a0a2e") : .white)
                    
                    Text(type.description)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(toneType == type ? Color(hex: "1a0a2e").opacity(0.7) : Color(hex: "9a8aba"))
                }
                
                Spacer()
                
                // Checkmark
                if toneType == type {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "1a0a2e"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(toneType == type ? Color(hex: "4ECDC4") : Color.white.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ToneTypeView(toneType: .constant(.string))
    }
}


