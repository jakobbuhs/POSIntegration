//
//  AppStore.swift
//  POS-app-shopify
//
//  Created by Jakob Buhs on 28/10/2025.
//

import Foundation
import SwiftUI

@MainActor
final class AppStore: ObservableObject {
  struct Session {
    var authed: Bool = false
    var locationName: String = "Oslo"
    var terminals: [TerminalRef] = []
    var selectedTerminalId: String? = nil
  }

  @Published var session = Session()
  @Published var products: [Product] = []
  @Published var cart: [CartItem] = []
  @Published var customer = Customer()
  @Published var orderRef: String = UUID().uuidString.lowercased()
  @Published var lastPayment: PaymentAttemptDTO?

  // computed amount after overrides
  var amountMinor: Int {
    cart.reduce(0) { acc, item in
      let price = item.overrideMinor ?? (products.first { $0.id == item.productId }?.priceMinor ?? 0)
      return acc + price * item.qty
    }
  }

  func bootstrap() async {
    // mock products & terminals for now (replace with server pull later)
    if products.isEmpty {
      products = [
        Product(id: "p1", title: "Helmet", priceMinor: 49900, currency: "NOK", sku: "HELM-001"),
        Product(id: "p2", title: "Bottle", priceMinor: 9900, currency: "NOK", sku: "BOT-001"),
        Product(id: "p3", title: "Gloves", priceMinor: 19900, currency: "NOK", sku: "GLOV-001"),
      ]
    }
    if session.terminals.isEmpty {
      session.terminals = [
        TerminalRef(id: "rdr_1682VS3C3A912S7N707WCW37YY", label: "Solo Oslo 1")
      ]
      session.selectedTerminalId = session.terminals.first?.id
    }
  }

  func resetSale() {
    cart = []
    customer = Customer()
    orderRef = UUID().uuidString.lowercased()
    lastPayment = nil
  }

  func add(product: Product, qty: Int = 1) {
    if let idx = cart.firstIndex(where: { $0.productId == product.id }) {
      cart[idx].qty += qty
    } else {
      cart.append(CartItem(id: UUID(), productId: product.id, qty: qty, overrideMinor: nil))
    }
  }

  func remove(item: CartItem) {
    cart.removeAll { $0.id == item.id }
  }

  func setOverride(itemId: UUID, minor: Int?) {
    guard let idx = cart.firstIndex(where: { $0.id == itemId }) else { return }
    cart[idx].overrideMinor = minor
  }

  func login(passcode: String) {
    // MVP local check; replace with server call if needed
    session.authed = !passcode.isEmpty
  }
}
