import SwiftUI

struct TextStepView: View {
    @ObservedObject var viewModel: NewOrderViewModel
    @StateObject private var speech = SpeechService()
    @State private var text: String = ""
    @State private var textBeforeDictation: String = ""

    var body: some View {
        VStack(spacing: Theme.spacing) {
            Text("Auftragstext")
                .font(Theme.titleFont)
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
                    Image(systemName: speech.isRecording ? "mic.fill" : "mic")
                    Text(speech.isRecording ? "Aufnahme beenden" : "Sprache aufnehmen")
                }
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(height: Theme.buttonHeight)
                .foregroundStyle(.white)
                .background(speech.isRecording ? Color.red : Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            }

            if let errorMessage = speech.errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }

            Spacer()

            HStack {
                SecondaryButton(title: "Zurück", systemImage: "chevron.left") {
                    speech.stopRecording()
                    viewModel.backToCamera()
                }
                Spacer()
                PrimaryButton(title: "Weiter", systemImage: "arrow.right") {
                    speech.stopRecording()
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
        .onChange(of: speech.transcript) { newValue in
            guard speech.isRecording else { return }
            text = textBeforeDictation.isEmpty ? newValue : "\(textBeforeDictation) \(newValue)"
        }
    }

    private func toggleDictation() {
        if speech.isRecording {
            speech.stopRecording()
            viewModel.updateText(text)
        } else {
            speech.requestAuthorization { granted in
                guard granted else {
                    speech.errorMessage = "Zugriff auf Mikrofon oder Spracherkennung wurde nicht erlaubt."
                    return
                }
                textBeforeDictation = text
                speech.transcript = ""
                speech.startRecording()
            }
        }
    }
}
