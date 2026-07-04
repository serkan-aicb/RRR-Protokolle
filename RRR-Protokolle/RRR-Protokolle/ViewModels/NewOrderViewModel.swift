import Foundation
import UIKit
import Combine

enum WizardStep: Int, CaseIterable {
    case customerData
    case camera
    case text
    case signature
}

enum SubmitState: Equatable {
    case idle
    case sending
    case success
    case failure(String)
}

/// Zentrales ViewModel für den Neuer-Auftrag-Wizard. Hält den Entwurf über
/// alle Schritte hinweg im Speicher und schreibt ihn nach jeder Änderung auf
/// die Festplatte, damit beim Zurückgehen niemals Daten verloren gehen.
@MainActor
final class NewOrderViewModel: ObservableObject {
    @Published var step: WizardStep = .customerData
    @Published var draft: OrderDraft {
        didSet { persistDraft() }
    }
    @Published private(set) var images: [UIImage] = []
    @Published var submitState: SubmitState = .idle

    private let user: User
    private let storage = LocalStorageService.shared
    private var finalizedOrder: Order?

    init(user: User) {
        self.user = user
        let loadedDraft = LocalStorageService.shared.loadDraft(for: user.username)
        self.draft = loadedDraft
        self.images = loadedDraft.imageFileNames.compactMap { fileName in
            UIImage(contentsOfFile: LocalStorageService.shared.draftImageURL(fileName: fileName, for: user.username).path)
        }
    }

    private func persistDraft() {
        storage.saveDraft(draft, for: user.username)
    }

    // MARK: - Schritt 1: Kundendaten

    func goToCamera() {
        persistDraft()
        step = .camera
    }

    // MARK: - Schritt 2: Kamera

    func addCapturedImage(_ image: UIImage) {
        let optimizedData = ImageCompressionService.optimizedJPEGData(from: image)
        let fileName = storage.saveDraftImage(optimizedData, for: user.username)
        draft.imageFileNames.append(fileName)
        if let optimizedImage = UIImage(data: optimizedData) {
            images.append(optimizedImage)
        }
        persistDraft()
    }

    func removeImage(at index: Int) {
        guard draft.imageFileNames.indices.contains(index) else { return }
        let fileName = draft.imageFileNames[index]
        storage.deleteDraftImage(fileName: fileName, for: user.username)
        draft.imageFileNames.remove(at: index)
        images.remove(at: index)
        persistDraft()
    }

    func goToText() {
        persistDraft()
        step = .text
    }

    func backToCustomerData() {
        step = .customerData
    }

    // MARK: - Schritt 3: Text

    func updateText(_ text: String) {
        draft.text = text
        persistDraft()
    }

    func goToSignature() {
        persistDraft()
        step = .signature
    }

    func backToCamera() {
        step = .camera
    }

    // MARK: - Schritt 4: Unterschrift + Versand

    func backToText() {
        step = .text
    }

    /// Speichert den Auftrag lokal, erzeugt das PDF und versendet die E-Mail
    /// automatisch im Hintergrund per SMTP – ohne ein Mailprogramm zu öffnen.
    func submit(signatureData: Data) async {
        submitState = .sending

        let signatureFileName = storage.saveDraftSignature(signatureData, for: user.username)
        draft.signatureFileName = signatureFileName
        persistDraft()

        guard let order = storage.finalizeOrder(draft: draft, monteur: user) else {
            submitState = .failure("Der Auftrag konnte nicht lokal gespeichert werden.")
            return
        }
        finalizedOrder = order

        let pdfData = PDFService.generate(order: order)
        _ = storage.savePDF(pdfData, for: order)

        let imageAttachments: [SMTPAttachment] = order.imageFileNames.enumerated().map { index, fileName in
            let url = storage.imageURL(fileName: fileName, for: order)
            let data = (try? Data(contentsOf: url)) ?? Data()
            return SMTPAttachment(fileName: "Foto\(index + 1).jpg", mimeType: "image/jpeg", data: data)
        }

        do {
            try await SMTPService.shared.sendOrderMail(order: order, pdfData: pdfData, imageAttachments: imageAttachments)
            storage.clearDraft(for: user.username)
            submitState = .success
        } catch {
            submitState = .failure(error.localizedDescription)
        }
    }

    /// Erneuter Versandversuch, falls der vorherige Versand fehlgeschlagen ist.
    func retrySubmit() async {
        guard let order = finalizedOrder else { return }
        submitState = .sending

        let pdfData = storage.loadPDFData(for: order) ?? PDFService.generate(order: order)
        let imageAttachments: [SMTPAttachment] = order.imageFileNames.enumerated().map { index, fileName in
            let url = storage.imageURL(fileName: fileName, for: order)
            let data = (try? Data(contentsOf: url)) ?? Data()
            return SMTPAttachment(fileName: "Foto\(index + 1).jpg", mimeType: "image/jpeg", data: data)
        }

        do {
            try await SMTPService.shared.sendOrderMail(order: order, pdfData: pdfData, imageAttachments: imageAttachments)
            storage.clearDraft(for: user.username)
            submitState = .success
        } catch {
            submitState = .failure(error.localizedDescription)
        }
    }
}
