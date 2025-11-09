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
    // Products
    @Published var products: [Product] = []
    @Published var isLoadingProducts = false
    @Published var productsError: String?
    
    // Cart
    @Published var cart: [CartItem] = []
    @Published var customer = Customer()
    
    // Session
    @Published var session = Session()
    
    // Payment
    @Published var orderRef: String?
    @Published var lastPayment: PaymentAttemptDTO?
    
    // Computed properties
    var amountMinor: Int {
        cart.reduce(0) { total, item in
            if let product = products.first(where: { $0.id == item.productId }) {
                let price = item.overrideMinor ?? product.priceMinor
                return total + (price * item.qty)
            }
            return total
        }
    }
    
    // MARK: - Product Methods
    
    /// Load products from API
    func loadProducts() async {
        guard !isLoadingProducts else { return }
        
        isLoadingProducts = true
        productsError = nil
        
        do {
            let fetchedProducts = try await ProductRepository.shared.fetchProducts()
            products = fetchedProducts
            print("✅ Loaded \(products.count) products")
        } catch {
            productsError = "Failed to load products: \(error.localizedDescription)"
            print("❌ Product load error: \(error)")
        }
        
        isLoadingProducts = false
    }
    
    /// Refresh products (force sync on server)
    func refreshProducts() async {
        guard !isLoadingProducts else { return }
        
        isLoadingProducts = true
        productsError = nil
        
        do {
            try await ProductRepository.shared.syncProducts()
            try await Task.sleep(nanoseconds: 1_000_000_000) // Wait 1 second for sync
            let fetchedProducts = try await ProductRepository.shared.fetchProducts()
            products = fetchedProducts
            print("✅ Synced and loaded \(products.count) products")
        } catch {
            productsError = "Failed to refresh products: \(error.localizedDescription)"
            print("❌ Product refresh error: \(error)")
        }
        
        isLoadingProducts = false
    }
    
    // MARK: - Cart Methods
    
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
    
    func remove(item: CartItem) {
        if let index = cart.firstIndex(where: { $0.id == item.id }) {
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
    
    func clearCart() {
        cart.removeAll()
    }
    
    // MARK: - Session Methods
    
    func login(passcode: String) {
        // Simple passcode validation
        // TODO: Implement proper device authentication
        if passcode.count == 4 {
            session.authed = true
        }
    }
    
    func logout() {
        session.authed = false
        clearCart()
        customer = Customer()
    }
    
    // MARK: - Sale Methods
    
    func resetSale() {
        clearCart()
        customer = Customer()
        orderRef = nil
        lastPayment = nil
    }
}

struct Session: Codable {
    var authed = false
    var deviceCode: String?
    var locationId: String?
    var selectedTerminalId: String?
    var terminals: [TerminalRef] = []
}
