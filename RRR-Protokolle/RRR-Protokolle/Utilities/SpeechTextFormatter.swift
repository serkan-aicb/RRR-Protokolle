import Foundation

/// Rein lokale Nachbearbeitung des erkannten Diktats: fasst Mehrfach-
/// Leerzeichen zusammen, entfernt Leerzeichen vor Satzzeichen, schreibt
/// Satzanfänge groß und ergänzt ein Satzzeichen am Ende. Keine externe KI –
/// nur Textnormalisierung, damit das Diktat wie "schöne Sätze" wirkt.
enum SpeechTextFormatter {
    static func beautify(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return "" }

        while text.contains("  ") {
            text = text.replacingOccurrences(of: "  ", with: " ")
        }

        for punctuation in [".", ",", "!", "?", ":", ";"] {
            text = text.replacingOccurrences(of: " \(punctuation)", with: punctuation)
        }

        var result = ""
        var capitalizeNext = true
        for character in text {
            if capitalizeNext, character.isLetter {
                result.append(Character(character.uppercased()))
                capitalizeNext = false
            } else {
                result.append(character)
                if character == "." || character == "!" || character == "?" {
                    capitalizeNext = true
                }
            }
        }
        text = result

        if let last = text.last, !".!?".contains(last) {
            text.append(".")
        }

        return text
    }
}
