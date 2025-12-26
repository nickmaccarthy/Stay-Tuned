<p align="center">
  <img src="app-logo.png" alt="Stay Tuned Logo" width="120" height="120">
</p>

<h1 align="center">Stay Tuned</h1>

<p align="center">
  <strong>A beautiful, precise guitar tuner for iOS</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2017%2B-blue" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.9%2B-orange" alt="Swift">
  <img src="https://img.shields.io/badge/SwiftUI-✓-green" alt="SwiftUI">
  <img src="https://img.shields.io/badge/License-MIT-lightgrey" alt="License">
</p>

---

## ✨ Features

- **Real-time Pitch Detection** — YIN-inspired algorithm with vDSP optimizations for accurate, low-latency tuning
- **Chromatic Tuner** — Detect any note across the full chromatic scale
- **Multiple Tunings** — Standard, Drop D, DADGAD, Open G/D/C/E/A/B, and more
- **Visual Headstock** — Martin-style guitar headstock with tappable tuning pegs
- **Auto & Manual Modes** — Auto-detect closest string or manually select which string to tune
- **Animated Needle Meter** — Smooth, responsive meter showing cents deviation
- **Spectrum Analyzer** — Real-time frequency visualization
- **Tone Generator** — Play reference tones for tuning by ear
- **Metronome** — Built-in metronome with customizable tempo and time signatures
- **Adjustable Reference Pitch** — Set A4 anywhere from 432Hz to 444Hz
- **Glassmorphism UI** — Modern, beautiful interface with animated gradients
- **Haptic Feedback** — Satisfying confirmation when strings are in tune

## 📱 Screenshots

<!-- Add your screenshots here -->
<p align="center">
  <em>Screenshots coming soon</em>
</p>

## 🛠 Tech Stack

| Category | Technology |
|----------|------------|
| Language | Swift 5.9+ |
| UI Framework | SwiftUI |
| Audio Capture | AVAudioEngine, AVAudioSession |
| Signal Processing | Accelerate/vDSP |
| Testing | Swift Testing Framework |
| Minimum Target | iOS 17.0+ |

## 📋 Requirements

- **Xcode:** 15.0+
- **iOS:** 17.0+
- **Device:** iPhone with microphone access

## 🚀 Getting Started

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/stay-tuned.git
   cd stay-tuned
   ```

2. Open the project in Xcode:
   ```bash
   open "Stay Tuned/Stay Tuned.xcodeproj"
   ```

3. Select your target device or simulator

4. Build and run (`Cmd + R`)

### Running Tests

Run the test suite with `Cmd + U` in Xcode, or from the command line:
```bash
xcodebuild test -project "Stay Tuned/Stay Tuned.xcodeproj" -scheme "Stay Tuned" -destination 'platform=iOS Simulator,name=iPhone 15'
```

## 🏗 Architecture

Stay Tuned follows the **MVVM (Model-View-ViewModel)** architecture pattern.

```
Stay Tuned/
├── Models/           # Data models (GuitarString, Tuning, Instrument, etc.)
├── Audio/            # Audio engine, pitch detection, tone generation
├── ViewModels/       # Observable objects managing app state
├── Views/            # SwiftUI views
├── Store/            # StoreKit integration for tips
└── Configuration/    # App configuration files
```

### Key Components

| Component | Description |
|-----------|-------------|
| `PitchDetector` | YIN-based pitch detection with parabolic interpolation |
| `AudioEngine` | AVAudioEngine wrapper for microphone capture |
| `TunerViewModel` | Main app state and tuning logic |
| `ToneGenerator` | Reference tone playback |
| `MetronomeEngine` | Precision metronome with multiple sounds |

### Pitch Detection Algorithm

The tuner uses a YIN-inspired algorithm optimized with Apple's Accelerate framework:

1. **Sample Accumulation** — Buffers audio for low-frequency accuracy
2. **Difference Function** — Calculates autocorrelation-based differences
3. **CMNDF** — Cumulative Mean Normalized Difference Function for period detection
4. **Parabolic Interpolation** — Sub-sample precision for accurate frequency estimation

## 🎸 Supported Tunings

| Tuning | Notes |
|--------|-------|
| Standard | E A D G B E |
| Half Step Down | Eb Ab Db Gb Bb Eb |
| Whole Step Down | D G C F A D |
| Drop D | D A D G B E |
| DADGAD | D A D G A D |
| Open G | D G D G B D |
| Open D | D A D F# A D |
| Open C | C G C G C E |
| Open E | E B E G# B E |
| Open A | E A E A C# E |
| Open B | B F# B F# B D# |

*More tunings and instruments coming soon!*

## ⚙️ Configuration

Key tuning parameters can be found in the source:

| Parameter | Value | File |
|-----------|-------|------|
| In-tune tolerance | ±7 cents | `TunerViewModel.swift` |
| Reference pitch range | 432-444 Hz | `ReferencePitchView.swift` |
| Default reference pitch | 440 Hz (A4) | `TunerViewModel.swift` |
| Frequency range | 30-4000 Hz | `PitchDetector.swift` |

## 🧪 Testing

The project includes comprehensive unit tests covering:

- Chromatic note detection from frequency
- Tuning and string models
- Pitch detection accuracy
- Spectrum analyzer sensitivity
- ViewModel business logic
- Metronome timing

**All new code must include unit tests.** See `CLAUDE.md` for development guidelines.

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for your changes
4. Ensure all tests pass (`Cmd + U`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 💝 Support

If you find Stay Tuned useful, consider supporting development:

- **Venmo:** @NickMacCarthy
- **Cash App:** $NickMacCarthy
- **PayPal:** nickmaccarthy

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with SwiftUI and ❤️
- Pitch detection inspired by the YIN algorithm
- Audio processing powered by Apple's Accelerate framework

---

<p align="center">
  Made with 🎸 for musicians
</p>

