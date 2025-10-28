import SwiftUI

enum Route: Hashable {
  case auth, catalog, cart, customer, payment, receipt
}

struct AppRouter: View {
  @EnvironmentObject var store: AppStore
  @State private var path: [Route] = []   // ← typed path

  var body: some View {
    NavigationStack(path: $path) {
      startView
        .navigationDestination(for: Route.self) { route in
          switch route {
          case .auth:
            AuthView(onSuccess: { path.append(.catalog) })
          case .catalog:
            CatalogView(next: { path.append(.cart) })
          case .cart:
            CartView(
              prev: { if !path.isEmpty { path.removeLast() } },
              next: { path.append(.customer) }
            )
          case .customer:
            CustomerView(
              prev: { if !path.isEmpty { path.removeLast() } },
              next: { path.append(.payment) }
            )
          case .payment:
            PaymentView(onDone: { path.append(.receipt) })
          case .receipt:
            ReceiptView(onNewSale: { path = [] })
          }
        }
    }
  }

  @ViewBuilder
  private var startView: some View {
    if store.session.authed {
      CatalogView(next: { path.append(.cart) })
    } else {
      AuthView(onSuccess: { path.append(.catalog) })
    }
  }
}
