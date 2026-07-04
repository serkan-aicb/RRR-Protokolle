import Foundation

struct SMTPAttachment {
    let fileName: String
    let mimeType: String
    let data: Data
}

enum SMTPError: LocalizedError {
    case connectionFailed
    case unexpectedResponse(String)
    case timeout

    var errorDescription: String? {
        switch self {
        case .connectionFailed: return "Verbindung zum Mailserver fehlgeschlagen."
        case .unexpectedResponse(let response): return "Unerwartete Antwort des Mailservers: \(response)"
        case .timeout: return "Zeitüberschreitung bei der Kommunikation mit dem Mailserver."
        }
    }
}

/// Versendet E-Mails direkt per SMTP im Hintergrund, ohne ein Mailprogramm zu
/// öffnen (kein Apple Mail, kein Outlook, kein Mail-Compose-Sheet). Nutzt
/// ausschließlich Apples Foundation-Streams inklusive STARTTLS-Unterstützung,
/// keine Drittanbieter-Bibliothek.
final class SMTPService {
    static let shared = SMTPService()

    func sendOrderMail(order: Order, pdfData: Data, imageAttachments: [SMTPAttachment]) async throws {
        let subject = "\(order.customer.address), \(order.customer.city)"

        let bodyLines = [
            "Kunde: \(order.customer.company) \(order.customer.firstName) \(order.customer.lastName)",
            "Adresse: \(order.customer.address), \(order.customer.city)",
            "Erstellungsdatum: \(order.createdAt.germanDateString)",
            "Monteur: \(order.monteurFullName)",
            "",
            "Auftragstext:",
            order.text
        ]
        let body = bodyLines.joined(separator: "\r\n")

        var attachments: [SMTPAttachment] = [SMTPAttachment(fileName: "Protokoll.pdf", mimeType: "application/pdf", data: pdfData)]
        attachments.append(contentsOf: imageAttachments)

        try await send(to: CompanyConfig.recipientEmail, subject: subject, textBody: body, attachments: attachments)
    }

    func send(to recipient: String, subject: String, textBody: String, attachments: [SMTPAttachment]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try self.sendSynchronously(to: recipient, subject: subject, textBody: textBody, attachments: attachments)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func sendSynchronously(to recipient: String, subject: String, textBody: String, attachments: [SMTPAttachment]) throws {
        let transport = SMTPTransport(host: SMTPConfig.host, port: SMTPConfig.port)
        try transport.connect(useImmediateTLS: !SMTPConfig.useStartTLS)
        defer { transport.close() }

        _ = try transport.readResponse(expecting: ["220"])

        try transport.writeLine("EHLO rrr-protokolle.local")
        _ = try transport.readMultilineResponse(expecting: ["250"])

        if SMTPConfig.useStartTLS {
            try transport.writeLine("STARTTLS")
            _ = try transport.readResponse(expecting: ["220"])
            try transport.upgradeToTLS()

            try transport.writeLine("EHLO rrr-protokolle.local")
            _ = try transport.readMultilineResponse(expecting: ["250"])
        }

        try transport.writeLine("AUTH LOGIN")
        _ = try transport.readResponse(expecting: ["334"])
        try transport.writeLine(Data(SMTPConfig.username.utf8).base64EncodedString())
        _ = try transport.readResponse(expecting: ["334"])
        try transport.writeLine(Data(SMTPConfig.password.utf8).base64EncodedString())
        _ = try transport.readResponse(expecting: ["235"])

        try transport.writeLine("MAIL FROM:<\(SMTPConfig.senderEmail)>")
        _ = try transport.readResponse(expecting: ["250"])

        try transport.writeLine("RCPT TO:<\(recipient)>")
        _ = try transport.readResponse(expecting: ["250", "251"])

        try transport.writeLine("DATA")
        _ = try transport.readResponse(expecting: ["354"])

        let message = MIMEMessageBuilder.build(
            from: SMTPConfig.senderEmail,
            fromName: SMTPConfig.senderName,
            to: recipient,
            subject: subject,
            textBody: textBody,
            attachments: attachments
        )
        try transport.writeDataTerminated(message)
        _ = try transport.readResponse(expecting: ["250"])

        try transport.writeLine("QUIT")
        _ = try? transport.readResponse(expecting: ["221"])
    }
}
