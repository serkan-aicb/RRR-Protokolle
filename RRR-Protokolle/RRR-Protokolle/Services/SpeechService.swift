import Foundation
import Speech
import AVFoundation
import Combine

/// Nutzt ausschließlich die nativen Apple-Sprachfunktionen (Speech-Framework)
/// zur Diktat-Erfassung. Keine externe KI, keine kostenpflichtigen APIs.
///
/// Während der Aufnahme wird bewusst nichts live im Textfeld angezeigt –
/// erst wenn der Monteur die Aufnahme beendet, wird komplett zugehört und
/// das Ergebnis in einem Rutsch zu einem sauberen, formatierten Satz
/// zusammengefasst (Großschreibung, Satzzeichen, keine Füllwörter).
@MainActor
final class SpeechService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var finalizedText: String?
    @Published var errorMessage: String?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "de-DE"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var rawTranscript = ""
    private var finalizeWatchdog: DispatchWorkItem?

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
            if #available(iOS 16.0, *) {
                newRequest.addsPunctuation = true
            }
            if recognizer.supportsOnDeviceRecognition {
                newRequest.requiresOnDeviceRecognition = true
            }
            request = newRequest
            rawTranscript = ""
            finalizedText = nil

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
                        self.rawTranscript = result.bestTranscription.formattedString
                    }
                    if error != nil || (result?.isFinal ?? false) {
                        self.finalizeRecognition()
                    }
                }
            }
        } catch {
            errorMessage = "Aufnahme konnte nicht gestartet werden."
            cancelRecording()
        }
    }

    /// Beendet die Aufnahme. Das Diktat wird erst jetzt – nach vollständigem
    /// Zuhören – zu einem sauberen Text zusammengefasst und über
    /// `finalizedText` bereitgestellt.
    func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        isProcessing = true

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        // Falls der Erkenner nach dem Ende der Aufnahme kein finales Ergebnis
        // mehr liefert, wird nach kurzer Wartezeit trotzdem finalisiert.
        let watchdog = DispatchWorkItem { [weak self] in self?.finalizeRecognition() }
        finalizeWatchdog = watchdog
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: watchdog)
    }

    /// Bricht die Aufnahme ohne Ergebnis ab (z. B. bei einem Startfehler).
    func cancelRecording() {
        finalizeWatchdog?.cancel()
        finalizeWatchdog = nil
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        task?.cancel()
        task = nil
        request = nil
        rawTranscript = ""
        isRecording = false
        isProcessing = false
    }

    private func finalizeRecognition() {
        guard isProcessing || isRecording else { return }
        finalizeWatchdog?.cancel()
        finalizeWatchdog = nil

        let beautified = SpeechTextFormatter.beautify(Self.removingFillerWords(rawTranscript))
        finalizedText = beautified

        task?.cancel()
        task = nil
        request = nil
        rawTranscript = ""
        isRecording = false
        isProcessing = false
    }

    /// Entfernt gängige Füllwörter, falls der Erkenner sie wortwörtlich
    /// transkribiert hat, damit der Text natürlich wirkt.
    private static func removingFillerWords(_ text: String) -> String {
        let words = text.split(separator: " ")
        let filtered = words.filter { !fillerWords.contains($0.lowercased()) }
        return filtered.joined(separator: " ")
    }
}
