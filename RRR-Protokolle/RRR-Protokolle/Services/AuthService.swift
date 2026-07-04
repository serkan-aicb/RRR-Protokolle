import Foundation

/// Fest im Code hinterlegte Benutzer. Vorname, Nachname und Position werden
/// vom Administrator vorgegeben und sind nicht editierbar.
/// TODO: Platzhalter-Benutzer durch die echten Monteure ersetzen.
enum AuthService {
    static let users: [User] = [
        User(id: "monteur1", username: "monteur1", password: "monteur1", firstName: "Max", lastName: "Mustermann", position: "Monteur"),
        User(id: "monteur2", username: "monteur2", password: "monteur2", firstName: "Erika", lastName: "Musterfrau", position: "Monteurin"),
        User(id: "admin", username: "admin", password: "admin", firstName: "Peter", lastName: "Ritter", position: "Geschäftsführer"),
        User(id: "serkansah", username: "serkansah", password: "serkanRRR", firstName: "Serkan", lastName: "Sahin", position: "Projektleiter")
    ]

    static func login(username: String, password: String) -> User? {
        users.first { $0.username.caseInsensitiveCompare(username) == .orderedSame && $0.password == password }
    }
}
