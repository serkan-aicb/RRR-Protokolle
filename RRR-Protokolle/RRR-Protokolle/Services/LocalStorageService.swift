import Foundation
import UIKit

/// Verwaltet alle lokal auf dem Gerät gespeicherten Daten:
/// angemeldeter Benutzer, laufende Auftrags-Entwürfe (Drafts) und
/// abgeschlossene, benutzerbezogene Aufträge. Es wird bewusst keine
/// Cloud, Online-Datenbank oder externer Speicher verwendet.
final class LocalStorageService {
    static let shared = LocalStorageService()

    private let defaults = UserDefaults.standard
    private let loggedInUsernameKey = "RRR.loggedInUsername"

    private let fileManager = FileManager.default

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var ordersRootURL: URL {
        documentsURL.appendingPathComponent("Orders", isDirectory: true)
    }

    private var draftsRootURL: URL {
        documentsURL.appendingPathComponent("Drafts", isDirectory: true)
    }

    // MARK: - Angemeldeter Benutzer

    func persistLoggedInUser(_ user: User?) {
        defaults.set(user?.username, forKey: loggedInUsernameKey)
    }

    func loadLoggedInUser() -> User? {
        guard let username = defaults.string(forKey: loggedInUsernameKey) else { return nil }
        return AuthService.users.first { $0.username == username }
    }

    // MARK: - Ordner-Helfer

    private func ordersDirectory(for username: String) -> URL {
        ordersRootURL.appendingPathComponent(username, isDirectory: true)
    }

    private func orderDirectory(for order: Order) -> URL {
        ordersDirectory(for: order.ownerUsername).appendingPathComponent(order.id.uuidString, isDirectory: true)
    }

    private func draftDirectory(for username: String) -> URL {
        draftsRootURL.appendingPathComponent(username, isDirectory: true)
    }

    private func ensureDirectoryExists(_ url: URL) {
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    // MARK: - Draft (laufender Wizard)

    func loadDraft(for username: String) -> OrderDraft {
        let url = draftDirectory(for: username).appendingPathComponent("draft.json")
        guard let data = try? Data(contentsOf: url),
              let draft = try? JSONDecoder().decode(OrderDraft.self, from: data) else {
            return OrderDraft()
        }
        return draft
    }

    func saveDraft(_ draft: OrderDraft, for username: String) {
        let dir = draftDirectory(for: username)
        ensureDirectoryExists(dir)
        let url = dir.appendingPathComponent("draft.json")
        guard let data = try? JSONEncoder().encode(draft) else { return }
        try? data.write(to: url, options: .atomic)
    }

    func clearDraft(for username: String) {
        let dir = draftDirectory(for: username)
        try? fileManager.removeItem(at: dir)
    }

    /// Speichert ein während des Wizards aufgenommenes Foto im Draft-Ordner
    /// des Benutzers und liefert den Dateinamen zurück.
    @discardableResult
    func saveDraftImage(_ data: Data, for username: String) -> String {
        let dir = draftDirectory(for: username)
        ensureDirectoryExists(dir)
        let fileName = "\(UUID().uuidString).jpg"
        let url = dir.appendingPathComponent(fileName)
        try? data.write(to: url, options: .atomic)
        return fileName
    }

    func draftImageURL(fileName: String, for username: String) -> URL {
        draftDirectory(for: username).appendingPathComponent(fileName)
    }

    func deleteDraftImage(fileName: String, for username: String) {
        try? fileManager.removeItem(at: draftImageURL(fileName: fileName, for: username))
    }

    @discardableResult
    func saveDraftSignature(_ data: Data, for username: String) -> String {
        let dir = draftDirectory(for: username)
        ensureDirectoryExists(dir)
        let fileName = "signature.png"
        let url = dir.appendingPathComponent(fileName)
        try? data.write(to: url, options: .atomic)
        return fileName
    }

    // MARK: - Abgeschlossene Aufträge

    /// Übernimmt einen fertigen Draft in den dauerhaften, benutzerbezogenen
    /// Auftragsordner und liefert den gespeicherten Auftrag zurück.
    func finalizeOrder(draft: OrderDraft, monteur: User) -> Order? {
        guard let signatureFileName = draft.signatureFileName else { return nil }

        let order = Order(
            id: UUID(),
            ownerUsername: monteur.username,
            createdAt: Date(),
            customer: draft.customer,
            imageFileNames: draft.imageFileNames,
            text: draft.text,
            signatureFileName: signatureFileName,
            monteurFirstName: monteur.firstName,
            monteurLastName: monteur.lastName,
            monteurPosition: monteur.position
        )

        let orderDir = orderDirectory(for: order)
        let imagesDir = orderDir.appendingPathComponent("images", isDirectory: true)
        ensureDirectoryExists(imagesDir)

        let draftDir = draftDirectory(for: monteur.username)

        for imageFileName in draft.imageFileNames {
            let source = draftDir.appendingPathComponent(imageFileName)
            let destination = imagesDir.appendingPathComponent(imageFileName)
            try? fileManager.copyItem(at: source, to: destination)
        }

        let signatureSource = draftDir.appendingPathComponent(signatureFileName)
        let signatureDestination = orderDir.appendingPathComponent(signatureFileName)
        try? fileManager.copyItem(at: signatureSource, to: signatureDestination)

        guard let orderData = try? JSONEncoder().encode(order) else { return nil }
        try? orderData.write(to: orderDir.appendingPathComponent("order.json"), options: .atomic)

        return order
    }

    func savePDF(_ data: Data, for order: Order) -> URL {
        let url = orderDirectory(for: order).appendingPathComponent("protokoll.pdf")
        try? data.write(to: url, options: .atomic)
        return url
    }

    func pdfURL(for order: Order) -> URL {
        orderDirectory(for: order).appendingPathComponent("protokoll.pdf")
    }

    func loadPDFData(for order: Order) -> Data? {
        try? Data(contentsOf: pdfURL(for: order))
    }

    /// Lädt ausschließlich die Aufträge des angegebenen Benutzers. Andere
    /// Monteure dürfen fremde Aufträge nicht sehen.
    func loadOrders(for username: String) -> [Order] {
        let dir = ordersDirectory(for: username)
        guard let orderFolders = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
            return []
        }

        let orders: [Order] = orderFolders.compactMap { folder in
            let jsonURL = folder.appendingPathComponent("order.json")
            guard let data = try? Data(contentsOf: jsonURL),
                  let order = try? JSONDecoder().decode(Order.self, from: data) else {
                return nil
            }
            return order
        }

        return orders.sorted { $0.createdAt > $1.createdAt }
    }

    func imageURL(fileName: String, for order: Order) -> URL {
        orderDirectory(for: order).appendingPathComponent("images").appendingPathComponent(fileName)
    }

    func signatureURL(for order: Order) -> URL {
        orderDirectory(for: order).appendingPathComponent(order.signatureFileName)
    }

    /// Löscht einen abgeschlossenen Auftrag inklusive aller Fotos, der
    /// Unterschrift und des PDFs unwiderruflich vom Gerät.
    func deleteOrder(_ order: Order) {
        try? fileManager.removeItem(at: orderDirectory(for: order))
    }
}
