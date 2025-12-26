//
//  SettingsView.swift
//  Stay Tuned
//
//  Created by Nick MacCarthy on 12/25/25.
//

import SwiftUI

/// Main settings view with navigation to sub-settings
struct SettingsView: View {
    @Binding
    var referencePitch: Int
    @Binding
    var toneType: ToneType
    @Environment(\.dismiss)
    private var dismiss
    @State
    private var showTipJar = false

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient matching app theme
                LinearGradient(
                    colors: [
                        Color(hex: "1a0a2e"),
                        Color(hex: "2d1b4e"),
                        Color(hex: "1a0a2e"),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Tuning section
                        settingsSection(title: "Tuning") {
                            // Reference Pitch row
                            NavigationLink {
                                ReferencePitchView(referencePitch: $referencePitch)
                            } label: {
                                settingsRow(
                                    icon: "tuningfork",
                                    iconColor: Color(hex: "4ECDC4"),
                                    title: "Reference Pitch",
                                    value: "A = \(referencePitch) Hz"
                                )
                            }

                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.leading, 58)

                            // Reference Tone row
                            NavigationLink {
                                ToneTypeView(toneType: $toneType)
                            } label: {
                                settingsRow(
                                    icon: toneType.iconName,
                                    iconColor: Color(hex: "FF6B9D"),
                                    title: "Reference Tone",
                                    value: toneType.displayName
                                )
                            }
                        }

                        // Support section
                        settingsSection(title: "Support") {
                            Button {
                                showTipJar = true
                            } label: {
                                settingsRow(
                                    icon: "heart.fill",
                                    iconColor: .pink,
                                    title: "Tip Jar",
                                    value: ""
                                )
                            }
                        }
                        .sheet(isPresented: $showTipJar) {
                            TipJarView()
                                .presentationDetents([.medium])
                                .presentationDragIndicator(.visible)
                        }

                        // About section
                        settingsSection(title: "About") {
                            NavigationLink {
                                AboutView()
                            } label: {
                                settingsRow(
                                    icon: "info.circle",
                                    iconColor: Color(hex: "9a8aba"),
                                    title: "About Stay Tuned",
                                    value: appVersion
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "4ECDC4"))
                }
            }
            .toolbarBackground(Color(hex: "1a0a2e"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func settingsSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "7c6c9a"))
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }

    private func settingsRow(icon: String, iconColor: Color, title: String, value: String) -> some View {
        HStack(spacing: 14) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(iconColor.opacity(0.15))
                )

            // Title
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)

            Spacer()

            // Value
            Text(value)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(hex: "9a8aba"))

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "7c6c9a"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

#Preview {
    SettingsView(referencePitch: .constant(440), toneType: .constant(.string))
}
