import SwiftUI

struct TextStepView: View {
    @ObservedObject var viewModel: NewOrderViewModel
    @StateObject private var speech = SpeechService()
    @State private var text: String = ""

    var body: some View {
        VStack(spacing: Theme.spacing) {
            Text("Auftragstext")
                .font(Theme.titleFont)
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextEditor(text: $text)
                .font(Theme.fieldFont)
                .padding(8)
                .frame(maxWidth: .infinity, minHeight: 220)
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
                .onChange(of: text) { newValue in
                    viewModel.updateText(newValue)
                }

            Button {
                toggleDictation()
            } label: {
                HStack(spacing: 10) {
                    if speech.isProcessing {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: speech.isRecording ? "mic.fill" : "mic")
                    }
                    Text(dictationButtonTitle)
                }
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: Theme.buttonHeight)
                .foregroundStyle(.white)
                .background(speech.isRecording ? Color.black : Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            }
            .disabled(speech.isProcessing)

            if speech.isRecording {
                Text("Höre zu … zum Beenden erneut antippen.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }

            if let errorMessage = speech.errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }

            Spacer()

            HStack {
                SecondaryButton(title: "Zurück", systemImage: "chevron.left") {
                    speech.cancelRecording()
                    viewModel.backToCamera()
                }
                Spacer()
                PrimaryButton(title: "Weiter", systemImage: "arrow.right") {
                    speech.cancelRecording()
                    viewModel.goToSignature()
                }
                .frame(width: 180)
            }
        }
        .padding(Theme.spacing)
        .background(Theme.background)
        .navigationTitle("Auftragstext")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { text = viewModel.draft.text }
        .onChange(of: speech.finalizedText) { newValue in
            guard let dictated = newValue, !dictated.isEmpty else { return }
            text = text.isEmpty ? dictated : "\(text) \(dictated)"
            viewModel.updateText(text)
        }
    }

    private var dictationButtonTitle: String {
        if speech.isProcessing { return "Verarbeite Diktat …" }
        return speech.isRecording ? "Aufnahme beenden" : "Sprache aufnehmen"
    }

    private func toggleDictation() {
        if speech.isRecording {
            speech.stopRecording()
        } else {
            speech.requestAuthorization { granted in
                guard granted else {
                    speech.errorMessage = "Zugriff auf Mikrofon oder Spracherkennung wurde nicht erlaubt."
                    return
                }
                speech.startRecording()
            }
        }
    }
}
