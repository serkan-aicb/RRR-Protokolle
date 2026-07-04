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

    func deleteOrders(at offsets: IndexSet) {
        for index in offsets {
            storage.deleteOrder(orders[index])
        }
        orders = orders.enumerated().filter { !offsets.contains($0.offset) }.map(\.element)
    }

    func delete(_ order: Order) {
        storage.deleteOrder(order)
        orders.removeAll { $0.id == order.id }
    }
}
