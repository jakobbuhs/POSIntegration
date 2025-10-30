//
//  CartView.swift
//  POS-app-shopify
//
//  Enhanced with modern layout and better UX
//

import SwiftUI

struct CartView: View {
    @EnvironmentObject var store: AppStore
    var prev: () -> Void
    var next: () -> Void
    @State private var showingClearAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            Divider()
            
            if store.cart.isEmpty {
                emptyCartView
            } else {
                // Cart Items List
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(store.cart) { item in
                            if let product = store.products.first(where: { $0.id == item.productId }) {
                                CartItemRow(
                                    item: item,
                                    product: product,
                                    onIncrement: { store.add(product: product) },
                                    onDecrement: { store.remove(itemId: item.id) },
                                    onDelete: { store.removeAll(itemId: item.id) }
                                )
                            }
                        }
                    }
                    .padding()
                }
                
                // Summary Section
                Divider()
                summarySection
                
                // Action Buttons
                actionButtons
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .alert("Clear Cart", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                store.cart.removeAll()
            }
        } message: {
            Text("Are you sure you want to remove all items from the cart?")
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            Button(action: prev) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Products")
                }
                .foregroundColor(.blue)
            }
            
            Spacer()
            
            Text("Cart")
                .font(.system(size: 28, weight: .bold))
            
            Spacer()
            
            Button(action: { showingClearAlert = true }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .opacity(store.cart.isEmpty ? 0 : 1)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Empty Cart View
    private var emptyCartView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart")
                .font(.system(size: 70))
                .foregroundColor(.gray)
            
            Text("Your cart is empty")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add products to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: prev) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Browse Products")
                }
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Summary Section
    private var summarySection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Subtotal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(CurrencyFormatter.nok(minor: store.amountMinor))
                    .font(.subheadline)
            }
            
            HStack {
                Text("Items")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(store.cart.reduce(0) { $0 + $1.qty })")
                    .font(.subheadline)
            }
            
            Divider()
            
            HStack {
                Text("Total")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Text(CurrencyFormatter.nok(minor: store.amountMinor))
                    .font(.title3)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: next) {
                HStack {
                    Text("Continue to Customer")
                    Image(systemName: "arrow.right")
                }
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .disabled(store.cart.isEmpty)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Cart Item Row
struct CartItemRow: View {
    let item: CartItem
    let product: Product
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onDelete: () -> Void
    
    private var itemTotal: Int {
        let price = item.overrideMinor ?? product.priceMinor
        return price * item.qty
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Product Image Placeholder
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(.gray.opacity(0.3))
                )
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.title)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    Text(CurrencyFormatter.nok(minor: item.overrideMinor ?? product.priceMinor))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if item.overrideMinor != nil {
                        Text("(Custom)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            // Quantity Controls
            VStack(alignment: .trailing, spacing: 8) {
                Text(CurrencyFormatter.nok(minor: itemTotal))
                    .font(.system(size: 16, weight: .bold))
                
                HStack(spacing: 12) {
                    Button(action: onDecrement) {
                        Image(systemName: item.qty > 1 ? "minus" : "trash")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(item.qty > 1 ? .blue : .red)
                            .frame(width: 32, height: 32)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    Text("\(item.qty)")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(minWidth: 24)
                    
                    Button(action: onIncrement) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(width: 32, height: 32)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
