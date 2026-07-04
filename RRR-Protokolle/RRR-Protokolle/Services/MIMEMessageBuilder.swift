import Foundation

/// Baut eine MIME-Nachricht (multipart/mixed) mit Klartext-Body und
/// beliebig vielen Binär-Anhängen (PDF, Fotos) für den direkten SMTP-Versand.
enum MIMEMessageBuilder {
    static func build(from: String, fromName: String, to: String, subject: String, textBody: String, attachments: [SMTPAttachment]) -> String {
        let boundary = "RRRProtokolle-\(UUID().uuidString)"
        var lines: [String] = []

        lines.append("From: \(fromName) <\(from)>")
        lines.append("To: <\(to)>")
        lines.append("Subject: \(encodedHeaderValue(subject))")
        lines.append("Date: \(rfc2822Date())")
        lines.append("MIME-Version: 1.0")
        lines.append("Content-Type: multipart/mixed; boundary=\"\(boundary)\"")
        lines.append("")

        lines.append("--\(boundary)")
        lines.append("Content-Type: text/plain; charset=\"UTF-8\"")
        lines.append("Content-Transfer-Encoding: 8bit")
        lines.append("")
        lines.append(textBody)
        lines.append("")

        for attachment in attachments {
            lines.append("--\(boundary)")
            lines.append("Content-Type: \(attachment.mimeType); name=\"\(attachment.fileName)\"")
            lines.append("Content-Transfer-Encoding: base64")
            lines.append("Content-Disposition: attachment; filename=\"\(attachment.fileName)\"")
            lines.append("")
            lines.append(base64Wrapped(attachment.data))
            lines.append("")
        }

        lines.append("--\(boundary)--")

        return lines.joined(separator: "\r\n")
    }

    private static func base64Wrapped(_ data: Data) -> String {
        let base64 = data.base64EncodedString()
        var result = ""
        var index = base64.startIndex
        while index < base64.endIndex {
            let end = base64.index(index, offsetBy: 76, limitedBy: base64.endIndex) ?? base64.endIndex
            result += base64[index..<end] + "\r\n"
            index = end
        }
        return result
    }

    private static func encodedHeaderValue(_ value: String) -> String {
        guard value.rangeOfCharacter(from: CharacterSet(charactersIn: "\u{80}"..."\u{10FFFF}")) != nil else {
            return value
        }
        let base64 = Data(value.utf8).base64EncodedString()
        return "=?UTF-8?B?\(base64)?="
    }

    private static func rfc2822Date() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: Date())
    }
}
