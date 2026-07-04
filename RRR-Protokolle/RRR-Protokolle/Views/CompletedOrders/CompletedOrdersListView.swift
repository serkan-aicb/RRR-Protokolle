import SwiftUI

struct CompletedOrdersListView: View {
    @StateObject private var viewModel: CompletedOrdersViewModel

    init(user: User) {
        _viewModel = StateObject(wrappedValue: CompletedOrdersViewModel(user: user))
    }

    var body: some View {
        Group {
            if viewModel.orders.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                    Text("Noch keine abgeschlossenen Aufträge.")
                        .foregroundStyle(.secondary)
                }
            } else {
                List {
                    ForEach(viewModel.orders) { order in
                        NavigationLink {
                            OrderDetailView(order: order)
                        } label: {
                            OrderRow(order: order)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.delete(order)
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: viewModel.deleteOrders)
                }
                .listStyle(.plain)
            }
        }
        .background(Theme.background)
        .navigationTitle("Abgeschlossene Aufträge")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.reload() }
    }
}

private struct OrderRow: View {
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(order.customer.company.isEmpty ? order.customer.lastName : order.customer.company)
                .font(.headline)
            Text("\(order.customer.firstName) \(order.customer.lastName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(order.customer.address), \(order.customer.city)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(order.createdAt.germanDateString)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
