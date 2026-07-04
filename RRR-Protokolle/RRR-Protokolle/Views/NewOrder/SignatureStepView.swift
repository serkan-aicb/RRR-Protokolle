import SwiftUI

struct SignatureStepView: View {
    @ObservedObject var viewModel: NewOrderViewModel
    @StateObject private var padController = SignaturePadController()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            SignaturePad(controller: padController)
                .ignoresSafeArea()

            VStack {
                HStack {
                    topButton(systemImage: "chevron.left") {
                        viewModel.backToText()
                    }

                    if !viewModel.draft.text.isEmpty {
                        ScrollView {
                            Text(viewModel.draft.text)
                                .font(.footnote)
                                .foregroundStyle(.black)
                                .padding(10)
                        }
                        .frame(maxHeight: 90)
                        .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 10))
                    }

                    Spacer()
                    topButton(systemImage: "arrow.counterclockwise") {
                        padController.clear()
                    }
                }
                Spacer()
                HStack(alignment: .bottom) {
                    Text(dateAndCity)
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(10)
                        .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 10))

                    Spacer()

                    Button {
                        submit()
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.submitState == .sending {
                                ProgressView().tint(.white)
                            }
                            Text("Absenden")
                                .font(.title3.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(padController.isEmpty ? Color.gray : Theme.accent, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(padController.isEmpty || viewModel.submitState == .sending)
                }
            }
            .padding()
        }
        .statusBarHidden()
        .alert("Fehler beim Versand", isPresented: isFailurePresented, actions: {
            Button("Erneut versuchen") {
                Task { await viewModel.retrySubmit() }
            }
            Button("Abbrechen", role: .cancel) {}
        }, message: {
            Text(failureMessage)
        })
        .fullScreenCover(isPresented: isSuccessPresented) {
            SubmitSuccessView {
                dismiss()
            }
        }
    }

    private var dateAndCity: String {
        let city = viewModel.draft.customer.city.trimmingCharacters(in: .whitespaces)
        guard !city.isEmpty else { return Date().germanShortDateString }
        return "\(Date().germanShortDateString), \(city)"
    }

    private func topButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.black)
                .padding(12)
                .background(.white.opacity(0.85), in: Circle())
        }
    }

    private func submit() {
        guard let data = padController.exportPNGData() else { return }
        Task { await viewModel.submit(signatureData: data) }
    }

    private var isSuccessPresented: Binding<Bool> {
        Binding(get: { viewModel.submitState == .success }, set: { _ in })
    }

    private var isFailurePresented: Binding<Bool> {
        Binding(
            get: {
                if case .failure = viewModel.submitState { return true }
                return false
            },
            set: { newValue in
                if !newValue { viewModel.submitState = .idle }
            }
        )
    }

    private var failureMessage: String {
        if case .failure(let message) = viewModel.submitState { return message }
        return ""
    }
}

private struct SubmitSuccessView: View {
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: Theme.spacing) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            Text("Auftrag erfolgreich versendet.")
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
            Spacer()
            PrimaryButton(title: "Fertig") {
                onDone()
            }
            .padding(.horizontal, Theme.spacing)
            .padding(.bottom, 24)
        }
        .background(Theme.background)
    }
}
