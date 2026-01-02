//
//  ToolsMenuView.swift
//  Stay Tuned
//
//  Created for UI Refinement.
//

import SwiftUI

struct ToolsMenuView: View {
    @ObservedObject
    var viewModel: TunerViewModel
    @Binding
    var showStageMode: Bool
    @Environment(\.dismiss)
    private var dismiss

    // State for sub-sheets
    @State
    private var showSettings = false
    @State
    private var showMetronome = false
    @State
    private var showTipJar = false

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
                    VStack(spacing: 24) {

                        // Stage Mode Access
                        menuSection(title: "Performance") {
                            Button {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    showStageMode = true
                                }
                            } label: {
                                menuRow(
                                    icon: "rectangle.expand.vertical",
                                    iconColor: Color(hex: "4ECDC4"),
                                    title: "Enter Stage Mode",
                                    subtitle: "Or rotate device to landscape"
                                )
                            }
                        }

                        // Tools
                        menuSection(title: "Tools") {
                            Button {
                                showMetronome = true
                            } label: {
                                menuRow(
                                    icon: "metronome",
                                    iconColor: Color(hex: "FF6B9D"),
                                    title: "Metronome",
                                    subtitle: ""
                                )
                            }

                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.leading, 58)

                            Button {
                                showSettings = true
                            } label: {
                                menuRow(
                                    icon: "gearshape.fill",
                                    iconColor: Color(hex: "9a8aba"),
                                    title: "Settings",
                                    subtitle: ""
                                )
                            }
                        }

                        // Support
                        menuSection(title: "Support") {
                            Button {
                                showTipJar = true
                            } label: {
                                menuRow(
                                    icon: "heart.fill",
                                    iconColor: .pink,
                                    title: "Tip Jar",
                                    subtitle: ""
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
            }
            .navigationTitle("Menu")
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
            .sheet(isPresented: $showMetronome) {
                MetronomeView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(
                    referencePitch: $viewModel.referencePitch,
                    toneType: Binding(
                        get: { viewModel.toneType },
                        set: { viewModel.toneType = $0 }
                    )
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showTipJar) {
                TipJarView()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Helper Views

    private func menuSection(title: String, @ViewBuilder content: () -> some View) -> some View {
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

    private func menuRow(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
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

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "9a8aba"))
                }
            }

            Spacer()

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
