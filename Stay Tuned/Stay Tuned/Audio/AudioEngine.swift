//
//  AudioEngine.swift
//  Stay Tuned
//
//  Created by Nick MacCarthy on 12/21/25.
//

import AVFoundation
import Combine
import Foundation

/// Manages audio capture from the microphone
final class AudioEngine: ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?

    @Published
    private(set) var isRunning = false
    @Published
    private(set) var hasPermission = false

    var onBufferReceived: (([Float], Double) -> Void)?

    // Buffer size for audio capture
    private let bufferSize: AVAudioFrameCount = 1024

    init() {
        checkPermission()
    }

    func checkPermission() {
        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .granted:
            hasPermission = true
        case .denied:
            hasPermission = false
        case .undetermined:
            requestPermission()
        @unknown default:
            hasPermission = false
        }
    }

    func requestPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.hasPermission = granted
            }
        }
    }

    func start() {
        guard hasPermission else {
            requestPermission()
            return
        }

        guard !isRunning else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)

            guard session.isInputAvailable else { return }

            audioEngine = AVAudioEngine()
            guard let audioEngine else { return }

            inputNode = audioEngine.inputNode
            guard let inputNode else { return }

            inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: nil) { [weak self] buffer, _ in
                guard let self else { return }
                guard let channelData = buffer.floatChannelData else { return }

                let channelDataValue = channelData.pointee
                let frameLength = Int(buffer.frameLength)
                let sampleRate = Double(buffer.format.sampleRate)

                // Copy samples
                var samples = [Float](repeating: 0, count: frameLength)
                for i in 0 ..< frameLength {
                    samples[i] = channelDataValue[i]
                }

                // Call the callback
                self.onBufferReceived?(samples, sampleRate)
            }

            try audioEngine.start()

            DispatchQueue.main.async {
                self.isRunning = true
            }
        } catch {
            print("AudioEngine: Failed to start - \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isRunning = false
            }
        }
    }

    func stop() {
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        inputNode = nil

        DispatchQueue.main.async {
            self.isRunning = false
        }
    }

    deinit {
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
    }
}
