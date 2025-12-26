//
//  TuningPickerView.swift
//  Stay Tuned
//
//  Created by Nick MacCarthy on 12/21/25.
//

import SwiftUI

/// Dropdown picker for selecting guitar tuning or chromatic mode
struct TuningPickerView: View {
    @Binding var selectedTuning: Tuning
    let availableTunings: [Tuning]
    @Binding var tunerMode: TunerMode
    
    @State private var showingSheet = false
    
    var body: some View {
        Button {
            showingSheet = true
        } label: {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(labelTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(labelSubtitle)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "9a8aba"))
                }
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(hex: "9a8aba"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "2d1b4e").opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: "5a4a7a"), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingSheet) {
            TuningSelectionSheet(
                selectedTuning: $selectedTuning,
                availableTunings: availableTunings,
                tunerMode: $tunerMode,
                isPresented: $showingSheet
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
    
    private var labelTitle: String {
        tunerMode == .chromatic ? "Chromatic" : "Guitar"
    }
    
    private var labelSubtitle: String {
        tunerMode == .chromatic ? "All Notes" : selectedTuning.name
    }
}

/// Sheet-based tuning/mode selector
struct TuningSelectionSheet: View {
    @Binding var selectedTuning: Tuning
    let availableTunings: [Tuning]
    @Binding var tunerMode: TunerMode
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                // Chromatic mode section
                Section {
                    Button {
                        tunerMode = .chromatic
                        isPresented = false
                    } label: {
                        HStack {
                            Label("Chromatic", systemImage: "waveform")
                                .foregroundColor(.primary)
                            Spacer()
                            if tunerMode == .chromatic {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                } header: {
                    Text("Mode")
                }
                
                // Tunings section
                Section {
                    ForEach(availableTunings) { tuning in
                        Button {
                            tunerMode = .instrument
                            selectedTuning = tuning
                            isPresented = false
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tuning.name)
                                        .foregroundColor(.primary)
                                    Text(tuning.strings.map { $0.name }.joined(separator: " "))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if tunerMode == .instrument && tuning.id == selectedTuning.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Guitar Tunings")
                }
            }
            .navigationTitle("Select Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "1a0a2e")
            .ignoresSafeArea()
        
        VStack {
            TuningPickerView(
                selectedTuning: .constant(.standard),
                availableTunings: Tuning.allTunings,
                tunerMode: .constant(.instrument)
            )
            
            Spacer()
        }
        .padding()
    }
}

