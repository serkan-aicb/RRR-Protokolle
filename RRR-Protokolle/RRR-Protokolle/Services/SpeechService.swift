import Foundation
import Speech
import AVFoundation
import Combine

/// Nutzt ausschließlich die nativen Apple-Sprachfunktionen (Speech-Framework)
/// zur Diktat-Erfassung. Keine externe KI, keine kostenpflichtigen APIs.
@MainActor
final class SpeechService: NSObject, ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording = false
    @Published var errorMessage: String?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "de-DE"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    /// Füllwörter, die selbst dann entfernt werden, falls der Erkenner sie
    /// wortwörtlich transkribiert, damit der Text natürlich wirkt.
    private static let fillerWords: Set<String> = ["äh", "ähm", "öhm", "öh", "hm", "hmm", "halt", "sozusagen"]

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(status == .authorized && granted)
                }
            }
        }
    }

    func startRecording() {
        guard !isRecording else { return }
        guard let recognizer, recognizer.isAvailable else {
            errorMessage = "Spracherkennung ist derzeit nicht verfügbar."
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let newRequest = SFSpeechAudioBufferRecognitionRequest()
            newRequest.shouldReportPartialResults = true
            if recognizer.supportsOnDeviceRecognition {
                newRequest.requiresOnDeviceRecognition = true
            }
            request = newRequest

            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.request?.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
            errorMessage = nil

            task = recognizer.recognitionTask(with: newRequest) { [weak self] result, error in
                guard let self else { return }
                Task { @MainActor in
                    if let result {
                        self.transcript = Self.cleaned(result.bestTranscription.formattedString)
                    }
                    if error != nil || (result?.isFinal ?? false) {
                        self.stopRecording()
                    }
                }
            }
        } catch {
            errorMessage = "Aufnahme konnte nicht gestartet werden."
            stopRecording()
        }
    }

    func stopRecording() {
        guard isRecording || audioEngine.isRunning else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// Entfernt gängige Füllwörter und normalisiert Leerzeichen, damit der
    /// erkannte Text möglichst natürlich wirkt.
    private static func cleaned(_ text: String) -> String {
        let words = text.split(separator: " ")
        let filtered = words.filter { !fillerWords.contains($0.lowercased()) }
        return filtered.joined(separator: " ")
    }
}
