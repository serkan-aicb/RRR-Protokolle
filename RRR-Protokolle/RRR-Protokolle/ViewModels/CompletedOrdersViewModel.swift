import Foundation
import Combine

@MainActor
final class CompletedOrdersViewModel: ObservableObject {
    @Published private(set) var orders: [Order] = []

    private let user: User
    private let storage = LocalStorageService.shared

    init(user: User) {
        self.user = user
        reload()
    }

    /// Lädt ausschließlich die Aufträge des angemeldeten Benutzers – jeder
    /// Monteur sieht nur seine eigenen Aufträge.
    func reload() {
        orders = storage.loadOrders(for: user.username)
    }
}
