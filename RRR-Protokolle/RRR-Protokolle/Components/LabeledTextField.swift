import SwiftUI

/// Volle-Breite Texteingabe mit Beschriftung, wie im Kundendaten-Schritt gefordert.
struct LabeledTextField: View {
    let title: String
    @Binding var text: String
    var autocapitalization: TextInputAutocapitalization = .words

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            TextField(title, text: $text)
                .font(Theme.fieldFont)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(false)
                .padding()
                .frame(maxWidth: .infinity)
                .frame(height: Theme.buttonHeight)
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        }
    }
}
