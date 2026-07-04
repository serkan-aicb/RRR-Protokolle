import Foundation

/// SMTP-Zugangsdaten für den automatischen Hintergrundversand.
enum SMTPConfig {
    static let host = "w01abc9a.kasserver.com"
    static let port: UInt16 = 465
    static let username = "technik@neos-media.de"
    static let password = "Money#2026!!!"
    static let senderEmail = "technik@neos-media.de"
    static let senderName = "RRR-Protokolle"

    /// Ob die Verbindung per STARTTLS (nach Klartext-Verbindungsaufbau) abgesichert wird.
    /// Bei Port 465 (implizites TLS) auf false setzen.
    static let useStartTLS = false
}
