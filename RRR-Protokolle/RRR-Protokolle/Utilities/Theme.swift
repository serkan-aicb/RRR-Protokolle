import SwiftUI

/// Zentrale Design-Konstanten für ein modernes, helles und großflächiges UI,
/// das auf schnelle Bedienbarkeit durch Monteure vor Ort ausgelegt ist.
enum Theme {
    static let accent = Color.accentColor
    static let background = Color(uiColor: .systemGroupedBackground)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)

    static let cornerRadius: CGFloat = 16
    static let spacing: CGFloat = 20
    static let buttonHeight: CGFloat = 56

    static let titleFont = Font.system(.title2, weight: .bold)
    static let bodyFont = Font.system(.body)
    static let fieldFont = Font.system(.title3)
}
