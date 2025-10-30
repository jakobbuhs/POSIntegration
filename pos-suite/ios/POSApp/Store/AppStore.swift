//
//  AppStore.swift
//  POS-app-shopify
//
//  Created by Jakob Buhs on 28/10/2025.
//

import Foundation
import SwiftUI

@MainActor
class AppStore: ObservableObject {
    // Existing properties
    @Published var products: [Product] = []
    @Published var cart: [CartItem] = []
    @Published var customer = Customer()
    @Published var session = Session()
    @Published var orderRef: String?
    @Published var lastPayment: PaymentAttemptDTO?
    
    // Cart computed property
    var amountMinor: Int {
        cart.reduce(0) { total, item in
            if let product = products.first(where: { $0.id == item.productId }) {
                let price = item.overrideMinor ?? product.priceMinor
                return total + (price * item.qty)
            }
            return total
        }
    }
    
    // Cart methods
    func add(product: Product) {
        if let index = cart.firstIndex(where: { $0.productId == product.id }) {
            cart[index].qty += 1
        } else {
            cart.append(CartItem(
                id: UUID(),
                productId: product.id,
                qty: 1,
                overrideMinor: nil
            ))
        }
    }
    
    func remove(itemId: UUID) {
        if let index = cart.firstIndex(where: { $0.id == itemId }) {
            if cart[index].qty > 1 {
                cart[index].qty -= 1
            } else {
                cart.remove(at: index)
            }
        }
    }
    
    func removeAll(itemId: UUID) {
        cart.removeAll(where: { $0.id == itemId })
    }
    
    func setOverride(itemId: UUID, minor: Int?) {
        if let index = cart.firstIndex(where: { $0.id == itemId }) {
            cart[index].overrideMinor = minor
        }
    }
}

struct Session: Codable {
    var authed = false
    var deviceCode: String?
    var locationId: String?
    var selectedTerminalId: String?
    var terminals: [TerminalRef] = []
}
