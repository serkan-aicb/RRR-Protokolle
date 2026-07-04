import Foundation

struct CustomerData: Codable, Equatable {
    var company: String = ""
    var firstName: String = ""
    var lastName: String = ""
    var address: String = ""
    var city: String = ""

    var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !address.trimmingCharacters(in: .whitespaces).isEmpty &&
        !city.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
