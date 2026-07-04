import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published private(set) var currentUser: User?
    @Published var usernameInput: String = ""
    @Published var passwordInput: String = ""
    @Published var errorMessage: String?

    private let storage = LocalStorageService.shared

    var isLoggedIn: Bool { currentUser != nil }

    init() {
        currentUser = storage.loadLoggedInUser()
    }

    func login() {
        errorMessage = nil
        guard let user = AuthService.login(username: usernameInput, password: passwordInput) else {
            errorMessage = "Benutzername oder Passwort ist falsch."
            return
        }
        currentUser = user
        storage.persistLoggedInUser(user)
        usernameInput = ""
        passwordInput = ""
    }

    func logout() {
        currentUser = nil
        storage.persistLoggedInUser(nil)
    }
}
