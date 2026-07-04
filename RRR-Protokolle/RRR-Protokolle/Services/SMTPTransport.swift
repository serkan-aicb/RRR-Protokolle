import Foundation

/// Blockierender SMTP-Transport auf Basis von Foundation `Stream`s. Erlaubt
/// im Gegensatz zu `Network.framework` das nachträgliche Upgraden einer
/// bestehenden Klartext-Verbindung auf TLS (STARTTLS), ohne eine neue
/// Verbindung aufbauen zu müssen.
final class SMTPTransport {
    private let host: String
    private let port: UInt16
    private var inputStream: InputStream?
    private var outputStream: OutputStream?
    private let timeout: TimeInterval = 15
    private var readBuffer = Data()

    init(host: String, port: UInt16) {
        self.host = host
        self.port = port
    }

    func connect(useImmediateTLS: Bool) throws {
        var input: InputStream?
        var output: OutputStream?
        Stream.getStreamsToHost(withName: host, port: Int(port), inputStream: &input, outputStream: &output)

        guard let input, let output else {
            throw SMTPError.connectionFailed
        }

        if useImmediateTLS {
            input.setProperty(StreamSocketSecurityLevel.negotiatedSSL.rawValue, forKey: .socketSecurityLevelKey)
            output.setProperty(StreamSocketSecurityLevel.negotiatedSSL.rawValue, forKey: .socketSecurityLevelKey)
        }

        input.schedule(in: .current, forMode: .default)
        output.schedule(in: .current, forMode: .default)
        input.open()
        output.open()

        inputStream = input
        outputStream = output

        try waitUntil(timeout: timeout) { [weak self] in
            (self?.inputStream?.streamStatus == .open || self?.inputStream?.streamStatus == .reading) &&
            (self?.outputStream?.streamStatus == .open || self?.outputStream?.streamStatus == .writing)
        }
    }

    func upgradeToTLS() throws {
        inputStream?.setProperty(StreamSocketSecurityLevel.negotiatedSSL.rawValue, forKey: .socketSecurityLevelKey)
        outputStream?.setProperty(StreamSocketSecurityLevel.negotiatedSSL.rawValue, forKey: .socketSecurityLevelKey)
    }

    func close() {
        inputStream?.close()
        outputStream?.close()
        inputStream?.remove(from: .current, forMode: .default)
        outputStream?.remove(from: .current, forMode: .default)
    }

    // MARK: - Schreiben

    func writeLine(_ line: String) throws {
        try writeRaw(line + "\r\n")
    }

    func writeDataTerminated(_ content: String) throws {
        // Byte-Stuffing: führende Punkte am Zeilenanfang verdoppeln (RFC 5321).
        let stuffed = content
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.hasPrefix(".") ? "." + $0 : String($0) }
            .joined(separator: "\n")
        try writeRaw(stuffed + "\r\n.\r\n")
    }

    private func writeRaw(_ string: String) throws {
        guard let outputStream else { throw SMTPError.connectionFailed }
        let bytes = Array(string.utf8)
        var totalWritten = 0

        while totalWritten < bytes.count {
            try waitUntil(timeout: timeout) { outputStream.hasSpaceAvailable || outputStream.streamStatus == .error }
            if outputStream.streamStatus == .error { throw SMTPError.connectionFailed }

            let written = bytes.withUnsafeBufferPointer { ptr -> Int in
                guard let base = ptr.baseAddress else { return 0 }
                return outputStream.write(base.advanced(by: totalWritten), maxLength: bytes.count - totalWritten)
            }
            if written <= 0 { throw SMTPError.connectionFailed }
            totalWritten += written
        }
    }

    // MARK: - Lesen

    @discardableResult
    func readResponse(expecting codes: [String]) throws -> String {
        let line = try readLine()
        guard let code = line.prefix(3).nonEmptyString, codes.contains(String(code)) else {
            throw SMTPError.unexpectedResponse(line)
        }
        return line
    }

    /// Liest so lange weitere Zeilen, wie eine Mehrzeilenantwort ("250-...")
    /// signalisiert wird, und prüft den finalen Code.
    @discardableResult
    func readMultilineResponse(expecting codes: [String]) throws -> [String] {
        var lines: [String] = []
        while true {
            let line = try readLine()
            lines.append(line)
            let isContinuation = line.count > 3 && line[line.index(line.startIndex, offsetBy: 3)] == "-"
            if !isContinuation {
                guard let code = line.prefix(3).nonEmptyString, codes.contains(String(code)) else {
                    throw SMTPError.unexpectedResponse(line)
                }
                break
            }
        }
        return lines
    }

    private func readLine() throws -> String {
        while true {
            if let range = readBuffer.range(of: Data([0x0D, 0x0A])) {
                let lineData = readBuffer.subdata(in: readBuffer.startIndex..<range.lowerBound)
                readBuffer.removeSubrange(readBuffer.startIndex..<range.upperBound)
                return String(data: lineData, encoding: .utf8) ?? ""
            }
            try readMoreIntoBuffer()
        }
    }

    private func readMoreIntoBuffer() throws {
        guard let inputStream else { throw SMTPError.connectionFailed }

        try waitUntil(timeout: timeout) { inputStream.hasBytesAvailable || inputStream.streamStatus == .error }
        if inputStream.streamStatus == .error { throw SMTPError.connectionFailed }

        var chunk = [UInt8](repeating: 0, count: 4096)
        let bytesRead = inputStream.read(&chunk, maxLength: chunk.count)
        if bytesRead < 0 { throw SMTPError.connectionFailed }
        if bytesRead == 0 { throw SMTPError.connectionFailed }
        readBuffer.append(contentsOf: chunk[0..<bytesRead])
    }

    // MARK: - Hilfsfunktion

    private func waitUntil(timeout: TimeInterval, condition: () -> Bool) throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            if Date() > deadline { throw SMTPError.timeout }
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
        }
    }
}

private extension Substring {
    var nonEmptyString: Substring? { isEmpty ? nil : self }
}
