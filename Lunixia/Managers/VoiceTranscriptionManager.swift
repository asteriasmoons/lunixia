//
//  VoiceTranscriptionManager.swift
//  Lunixia
//

import Foundation
import AVFoundation
import Speech
import Combine

@MainActor
final class VoiceTranscriptionManager: NSObject, ObservableObject {

    // MARK: - Published State

    @Published var isRecording: Bool = false
    @Published var liveTranscript: String = ""
    @Published var permissionError: VoicePermissionError? = nil
    @Published var recognizerAvailable: Bool = true

    // MARK: - Private

    private let audioEngine = AVAudioEngine()
    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    /// Incremented each time a session starts. The recognition callback captures
    /// the value at launch and ignores results/errors from prior sessions.
    private var sessionID: Int = 0

    // MARK: - Init

    override init() {
        super.init()
        let recognizer = SFSpeechRecognizer(locale: .current)
        recognizer?.delegate = self
        self.recognizer = recognizer
        self.recognizerAvailable = recognizer?.isAvailable ?? false
    }

    // MARK: - Public API

    func startRecording() async {
        liveTranscript = ""
        permissionError = nil

        guard let recognizer, recognizer.isAvailable else {
            permissionError = .recognizerUnavailable
            return
        }

        let speechStatus = await requestSpeechAuthorization()
        guard speechStatus == .authorized else {
            permissionError = .speechRecognitionDenied
            return
        }

        let micGranted = await requestMicrophoneAuthorization()
        guard micGranted else {
            permissionError = .microphoneDenied
            return
        }

        teardown()

        do {
            try beginAudioSession()
            try beginRecognition(recognizer: recognizer)
            isRecording = true
        } catch {
            permissionError = .engineError(error.localizedDescription)
            teardown()
        }
    }

    func stopRecording() {
        teardown()
    }

    // MARK: - Private

    /// Unconditionally tears down the audio engine and recognition task.
    /// Safe to call multiple times.
    private func teardown() {
        sessionID += 1

        recognitionTask?.cancel()
        recognitionTask = nil

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        isRecording = false
    }

    private func requestSpeechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    private func requestMicrophoneAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func beginAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func beginRecognition(recognizer: SFSpeechRecognizer) throws {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = false
        request.shouldReportPartialResults = true
        self.recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        let capturedSessionID = sessionID

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            // Discard callbacks that belong to a prior session.
            guard self.sessionID == capturedSessionID else { return }

            if let result {
                Task { @MainActor in
                    guard self.sessionID == capturedSessionID else { return }
                    self.liveTranscript = result.bestTranscription.formattedString
                }
            }

            if let error {
                let nsError = error as NSError
                // Ignore cancellation — codes 301 (kAFAssistantErrorDomain) and
                // 2 (AVAudioSession interrupted) are expected on manual stop.
                let isCancellation = (nsError.code == 301) ||
                                     (nsError.code == 2 && nsError.domain == "com.apple.coreaudio")
                if !isCancellation {
                    Task { @MainActor in
                        guard self.sessionID == capturedSessionID else { return }
                        self.permissionError = .engineError(error.localizedDescription)
                        self.teardown()
                    }
                }
            }

            if result?.isFinal == true {
                Task { @MainActor in
                    guard self.sessionID == capturedSessionID else { return }
                    self.teardown()
                }
            }
        }
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension VoiceTranscriptionManager: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            self.recognizerAvailable = available
            if !available && self.isRecording {
                self.permissionError = .recognizerUnavailable
                self.teardown()
            }
        }
    }
}

// MARK: - VoicePermissionError

enum VoicePermissionError: Identifiable, LocalizedError {
    case microphoneDenied
    case speechRecognitionDenied
    case recognizerUnavailable
    case engineError(String)

    var id: String {
        switch self {
        case .microphoneDenied:          return "microphoneDenied"
        case .speechRecognitionDenied:   return "speechRecognitionDenied"
        case .recognizerUnavailable:     return "recognizerUnavailable"
        case .engineError(let msg):      return "engineError-\(msg)"
        }
    }

    var errorDescription: String? {
        switch self {
        case .microphoneDenied:
            return "Microphone access was denied. Please enable it in Settings > Privacy & Security > Microphone."
        case .speechRecognitionDenied:
            return "Speech recognition access was denied. Please enable it in Settings > Privacy & Security > Speech Recognition."
        case .recognizerUnavailable:
            return "Speech recognition is not currently available. Please check your connection or try again later."
        case .engineError(let message):
            return "An audio error occurred: \(message)"
        }
    }
}
