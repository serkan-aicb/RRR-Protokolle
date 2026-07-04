import SwiftUI

/// Zentrale Design-Konstanten für ein modernes, helles und großflächiges UI,
/// das auf schnelle Bedienbarkeit durch Monteure vor Ort ausgelegt ist.
/// Farbwelt der Rohr-Reinigungsdienst Ritter GmbH: Weiß, Schwarz/Grau, Rot als Akzent.
enum Theme {
    static let accent = Color.accentColor
    static let background = Color.white
    static let cardBackground = Color(red: 0.95, green: 0.95, blue: 0.96)
    static let textPrimary = Color(red: 0.13, green: 0.13, blue: 0.13)
    static let textSecondary = Color(red: 0.42, green: 0.42, blue: 0.44)

    static let cornerRadius: CGFloat = 16
    static let spacing: CGFloat = 20
    static let buttonHeight: CGFloat = 56

    static let titleFont = Font.system(.title2, weight: .bold)
    static let bodyFont = Font.system(.body)
    static let fieldFont = Font.system(.title3)
}
