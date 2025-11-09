import SwiftUI

enum Route: Hashable {
  case auth, catalog, cart, customer, payment, receipt, settings
}

struct AppRouter: View {
  @EnvironmentObject var store: AppStore
  @State private var path: [Route] = []
  @State private var showSettings = false

  var body: some View {
    NavigationStack(path: $path) {
      startView
        .navigationDestination(for: Route.self) { route in
          switch route {
          case .auth:
            AuthView(onSuccess: { path.append(.catalog) })
          case .catalog:
            CatalogView(next: { path.append(.cart) })
              .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                  Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape.fill")
                  }
                }
              }
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
            ReceiptView(onNewSale: {
              path = []
              store.cart.removeAll()
            })
          case .settings:
            SettingsView()
          }
        }
        .sheet(isPresented: $showSettings) {
          SettingsView()
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
