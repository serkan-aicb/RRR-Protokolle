import Foundation

/// Zwischenspeicher für einen laufenden Auftrags-Wizard.
/// Wird nach jeder Änderung auf die Festplatte geschrieben, damit beim
/// Zurückgehen oder einem Neustart der App keine Eingaben verloren gehen.
struct OrderDraft: Codable, Equatable {
    var customer: CustomerData = CustomerData()
    var imageFileNames: [String] = []
    var text: String = ""
    var signatureFileName: String? = nil

    var isEmpty: Bool {
        customer == CustomerData() && imageFileNames.isEmpty && text.isEmpty && signatureFileName == nil
    }
}
