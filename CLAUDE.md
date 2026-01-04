# CLAUDE.md

This file provides context for AI assistants working with this codebase.

## Project Overview

**Stay Tuned** is an iOS Guitar Tuner written in SwiftUI. It features a modern glassmorphism UI with animated gradients, real-time pitch detection, and support for multiple instruments and tunings.

## Tech Stack

- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Audio:** AVAudioEngine, AVAudioSession
- **Signal Processing:** Accelerate/vDSP for optimized audio processing
- **Testing:** Swift Testing framework
- **Target:** iOS 17.0+
- **IDE:** Xcode 15.0+

## ⚠️ Development Requirements

### Unit Tests Are MANDATORY

**All new code must include unit tests.** This prevents regressions and ensures code quality.

When building new features or modifying existing code:
1. Write tests BEFORE or ALONGSIDE the implementation
2. Test all business logic, calculations, and model methods
3. Document critical configuration values in tests (like audio sensitivity)
4. Run tests before committing: `Cmd+U` in Xcode

Test files are located in `Stay TunedTests/`:
- `ChromaticNoteTests.swift` - Chromatic note detection from frequency
- `TuningTests.swift` - Tuning and GuitarString models
- `AudioTests.swift` - Pitch detection and spectrum analyzer sensitivity
- `TunerViewModelTests.swift` - ViewModel business logic
- `BeatDetectorTests.swift` - Autocorrelation & BPM logic

### Critical Audio Configuration (DO NOT CHANGE WITHOUT TESTING)

The spectrum analyzer sensitivity was carefully tuned. These values are tested in `AudioTests.swift`:

| Parameter | Value | Purpose |
|-----------|-------|---------|
| dB floor | -70 | Lower = more sensitive to quiet sounds |
| dB range | 40 | Dynamic range for normalization |
| Sensitivity boost | 2.5x | Amplifies visual response |

**Formula:** `normalizedDb = (db + 70) / 40 * 2.5`

If you change these values, update the tests in `SpectrumSensitivityTests` to match.

## Project Structure

```
docs/                           # GitHub Pages - App Store required pages
├── index.html                  # Landing page with features
├── privacy.html                # Privacy Policy
└── support.html                # Support & FAQ

Stay Tuned/
├── Models/
│   ├── GuitarString.swift      # String model (id, name, frequency, octave)
│   ├── Tuning.swift            # Tuning model with closestString() and centsDeviation()
│   ├── TuningPresets.swift     # All tuning definitions organized by instrument
│   └── Instrument.swift        # Instrument model for multi-instrument support
├── Audio/
│   ├── AudioEngine.swift       # AVAudioEngine wrapper for mic capture
│   └── PitchDetector.swift     # YIN-based pitch detection algorithm
├── ViewModels/
│   └── TunerViewModel.swift    # Main app state and audio processing logic
├── Views/
│   ├── TunerView.swift         # Main tuner screen with Tools Menu integration
│   ├── StageModeView.swift     # High-contrast, landscape-only performance view
│   ├── ToolsMenuView.swift     # Consolidated menu for app tools (Settings, Stage Mode, etc.)
│   ├── HeadstockView.swift     # Visual headstock with tappable tuning pegs
│   ├── TuningMeterView.swift   # Animated needle meter with cents/Hz display
│   ├── TuningPickerView.swift  # Tuning selection menu
│   ├── SettingsView.swift      # Settings hub with navigation to sub-settings
│   └── ReferencePitchView.swift # Reference pitch adjustment (A=432-444Hz)
└── Store/
    ├── StoreManager.swift      # StoreKit integration
    └── TipProduct.swift        # Tip jar product definitions
```

## Key Implementation Details

### Pitch Detection (PitchDetector.swift)
- Uses YIN-inspired algorithm with vDSP optimizations
- Sample accumulation buffer for low-frequency accuracy
- Difference function + cumulative mean normalized difference (CMNDF)
- Parabolic interpolation for sub-sample precision
- Frequency range: ~70Hz to ~450Hz (covers guitar range)
- Amplitude threshold: 0.008 (sensitive enough for high E string)

### Tuning Logic (TunerViewModel.swift)
- **Auto-detect mode:** Automatically finds closest string to detected frequency
- **Manual mode:** User selects string by tapping peg
- **In-tune tolerance:** ±7 cents
- **Sustained confirmation:** 0.5 seconds in-tune to confirm a string
- **Confirmed strings:** Persist green state until user taps to retune
- **All-tuned celebration:** Quick flash + haptic when all strings confirmed

### Beat Detection (BeatDetector.swift)
- **Algorithm:** Normalized Autocorrelation (172Hz resolution)
- **Harmonic Correction:** "Double-Time Check" favors 2x tempos (e.g., 120 vs 60 BPM) if detected strength > 50%
- **Buffer:** 3.5s circular buffer of RMS energy
- **Range:** 60-200 BPM

### Audio Pipeline
1. AudioEngine captures mic input with small buffer (low latency)
2. PitchDetector accumulates samples and detects pitch
3. TunerViewModel processes frequency, calculates cents deviation
4. UI updates at high frequency (30+ times/sec) with minimal smoothing

### Supported Instruments & Tunings
Organized in `TuningPresets.swift`:
- **Guitar:** Standard, Half Step Down, Whole Step Down, Drop D, DADGAD, Open tunings (G, D, C, E, A, B)
- Future: Banjo, Ukulele, Bass, etc.

### Stage Mode (StageModeView.swift)
- **Purpose:** High-contrast, interference-free view for live performance
- **Entry:** Accessed via Tools Menu or by rotating device to landscape
- **Landscape Lock:** View enforces landscape orientation by hiding close button
- **Wake Lock:** Disables idle timer to keep screen on during performance
- **Responsive Layout:** Dynamically scales UI elements based on available screen space using `GeometryReader`

## Settings Architecture

Settings are organized under `SettingsView.swift`, which acts as a **settings hub**. Each setting category has its own dedicated view that the user navigates to from the main settings screen.

**Current Settings:**
- **Reference Pitch** (`ReferencePitchView.swift`) - Adjust A4 reference from 432-444Hz

**Adding New Settings:**
1. Create a new view (e.g., `AppearanceSettingsView.swift`)
2. Add a `NavigationLink` row in `SettingsView.swift` under the appropriate section
3. Use the existing `settingsSection()` and `settingsRow()` helper functions for consistency

**Settings Data:**
- Use `@AppStorage` for persistence (stored in UserDefaults)
- Pass bindings from `TunerViewModel` through `SettingsView` to sub-views
- Reference pitch is stored as `@AppStorage("referencePitch")`

## UI/UX Notes

- **Headstock:** Martin-style acoustic guitar headstock
- **Tuning pegs:** Tappable, show checkmark when confirmed
- **Meter needle:** Compressed movement in ±in-tune zone for stability
- **Hz display:** Shows current and target frequency
- **Haptic feedback:** Success haptic on string confirmation and all-tuned

## Important Thresholds & Timing

| Parameter | Value | Location |
|-----------|-------|----------|
| In-tune tolerance | ±7 cents | TunerViewModel.swift |
| Sustained duration | 0.5 seconds | TunerViewModel.swift |
| Amplitude threshold | 0.0018 | PitchDetector.swift |
| CMNDF threshold | 0.20 | PitchDetector.swift |
| Min frequency | 30 Hz | PitchDetector.swift |
| Max frequency | 4000 Hz | PitchDetector.swift |
| Reference pitch range | 432-444 Hz | ReferencePitchView.swift |
| Default reference pitch | 440 Hz (A4) | TunerViewModel.swift |
| Spectrum dB floor | -70 dB | SpectrumAnalyzerView.swift |
| Spectrum dB range | 40 | SpectrumAnalyzerView.swift |
| Spectrum sensitivity boost | 2.5x | SpectrumAnalyzerView.swift |

## Build Notes

- Microphone usage description is set in build settings (not Info.plist)
- No custom Info.plist file - removed to avoid build conflicts

## Documentation & App Store Pages

The `/docs` folder contains static web pages for GitHub Pages hosting. These are required for App Store submission.

### Pages

| Page | Purpose | URL (when published) |
|------|---------|---------------------|
| `docs/index.html` | Main landing/documentation page | `https://[username].github.io/stay-tuned/` |
| `docs/privacy.html` | Privacy Policy for App Store | `https://[username].github.io/stay-tuned/privacy.html` |
| `docs/support.html` | Support page with FAQ and contact | `https://[username].github.io/stay-tuned/support.html` |

### ⚠️ KEEP DOCS UPDATED

**When adding or removing features, update the docs pages:**

1. **`docs/index.html`** - Update the features grid if adding new major features
2. **`docs/support.html`** - Update FAQ section for new features or changed behavior
3. **`docs/privacy.html`** - Update if data collection practices change (currently: none)

### Publishing to GitHub Pages

1. Push the `/docs` folder to the `main` branch
2. In GitHub repo settings → Pages → Set source to "Deploy from branch"
3. Select `main` branch and `/docs` folder
4. Pages will be available at `https://[username].github.io/stay-tuned/`

### Design Notes

- Uses glassmorphism aesthetic matching the app's UI
- Fonts: DM Sans (body), Outfit (headings)
- Color scheme: Dark gradient with cyan/magenta/gold accents
- Responsive design for mobile and desktop

## Payment Links (Tip Jar)

Located in `TipJarView` within `ContentView.swift`:
- Venmo: `@NickMacCarthy`
- Cash App: `$NickMacCarthy`
- PayPal: `nickmaccarthy`
