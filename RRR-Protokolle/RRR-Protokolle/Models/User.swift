import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: String
    let username: String
    let password: String
    let firstName: String
    let lastName: String
    let position: String

    var fullName: String {
        "\(firstName) \(lastName)"
    }
}
