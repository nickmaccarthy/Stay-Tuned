//
//  AboutView.swift
//  Stay Tuned
//
//  Created by Nick MacCarthy on 12/26/25.
//

import SwiftUI

/// View displaying app information, developer details, and contact info
struct AboutView: View {
    // Get version from Bundle
    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
    
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
                    // App header with logo and name
                    appHeader
                    
                    // Version info card
                    versionSection
                    
                    // Developer info card
                    developerSection
                    
                    // Footer tagline
                    footer
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(hex: "1a0a2e"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    // MARK: - Subviews
    
    private var appHeader: some View {
        VStack(spacing: 12) {
            // App logo
            Image("InAppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .shadow(color: Color(hex: "4ECDC4").opacity(0.3), radius: 12, x: 0, y: 4)
            
            // App name
            Text("Stay Tuned")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            // Subtitle
            Text("Guitar Tuner")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "9a8aba"))
        }
        .padding(.bottom, 8)
    }
    
    private var versionSection: some View {
        VStack(spacing: 0) {
            infoRow(label: "Version", value: appVersion)
            
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.leading, 16)
            
            infoRow(label: "Build", value: buildNumber)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var developerSection: some View {
        VStack(spacing: 0) {
            infoRow(label: "Developer", value: "Nick MacCarthy")
            
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.leading, 16)
            
            // Contact row with tappable email
            Link(destination: URL(string: "mailto:nickmaccarthy@gmail.com")!) {
                HStack {
                    Text("Contact")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "9a8aba"))
                    
                    Spacer()
                    
                    Text("nickmaccarthy@gmail.com")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(hex: "4ECDC4"))
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "7c6c9a"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var footer: some View {
        Text("Made with ❤️ from Rhode Island, USA")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(Color(hex: "7c6c9a"))
            .padding(.top, 16)
    }
    
    // MARK: - Helper Views
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "9a8aba"))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}

