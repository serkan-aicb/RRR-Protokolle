import Foundation

/// Firmendaten der Rohr-Reinigungsdienst Ritter GmbH für PDF-Kopf, Footer und E-Mail.
enum CompanyConfig {
    static let name = "Rohr-Reinigungsdienst Ritter GmbH"
    static let addressLine1 = "Tannenweg 17"
    static let addressLine2 = "96117 Weichendorf"
    static let phone = "Telefon: 0951 – 70042900"
    static let fax = "Telefax: 0951 – 70042901"
    static let email = "info@rohr-reinigung-ritter.de"
    static let website = "https://rohrreinigung-ritter.de"
    static let managingDirector = "Vertreten durch: Jan Ritter"
    static let register = "Handelsregister Bamberg · HRB 7193"
    static let privacyPolicyURL = "https://rohrreinigung-ritter.de/datenschutz/"

    /// Impressum-Text für den PDF-Footer (Angaben gemäß § 5 TMG).
    static let impressum = "\(name) · \(addressLine1) · \(addressLine2) · \(managingDirector) · \(register) · \(email)"

    /// Name der Logo-Bilddatei im Asset-Katalog.
    static let logoImageName = "CompanyLogo"

    /// Empfänger-Adresse für den automatischen Versand.
    static let recipientEmail = "info@rohr-reinigung-ritter.de"
}
