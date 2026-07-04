import Foundation

struct Order: Identifiable, Codable, Equatable {
    let id: UUID
    let ownerUsername: String
    let createdAt: Date
    var customer: CustomerData
    var imageFileNames: [String]
    var text: String
    var signatureFileName: String
    var monteurFirstName: String
    var monteurLastName: String
    var monteurPosition: String

    var monteurFullName: String {
        "\(monteurFirstName) \(monteurLastName)"
    }
}
