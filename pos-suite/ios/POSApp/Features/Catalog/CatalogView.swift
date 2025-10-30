//
//  CatalogView.swift
//  POS-app-shopify
//
//  Created by Jakob Buhs on 28/10/2025.
//  Enhanced with responsive grid layout and modern design
//

import SwiftUI

struct CatalogView: View {
    @EnvironmentObject var store: AppStore
    @State private var query = ""
    @State private var showOverrideFor: CartItem?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var next: () -> Void
    
    var filtered: [Product] {
        if query.trimmingCharacters(in: .whitespaces).isEmpty { return store.products }
        return store.products.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            ($0.sku ?? "").localizedCaseInsensitiveContains(query)
        }
    }
    
    // Responsive columns based on device size
    private var gridColumns: [GridItem] {
        let columnCount: Int
        if horizontalSizeClass == .regular {
            // iPad or larger
            columnCount = 4
        } else {
            // iPhone
            columnCount = 2
        }
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: columnCount)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            headerSection
            
            Divider()
            
            // Product Grid
            if filtered.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        ForEach(filtered) { product in
                            ProductCard(product: product) {
                                store.add(product: product)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(item: $showOverrideFor) { item in
            PriceOverrideSheet(item: item) { newMinor in
                store.setOverride(itemId: item.id, minor: newMinor)
                showOverrideFor = nil
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Products")
                    .font(.system(size: 28, weight: .bold))
                
                Spacer()
                
                // Cart Button
                Button(action: next) {
                    HStack(spacing: 8) {
                        Image(systemName: "cart.fill")
                        Text("\(store.cart.reduce(0) { $0 + $1.qty })")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(store.cart.isEmpty ? Color.gray : Color.blue)
                    )
                }
                .disabled(store.cart.isEmpty)
            }
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search products or SKU", text: $query)
                    .textFieldStyle(.plain)
                
                if !query.isEmpty {
                    Button(action: { query = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No products found")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Try adjusting your search")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Product Card Component
struct ProductCard: View {
    let product: Product
    let onAdd: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Product Image Placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 120)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.3))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.title)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let sku = product.sku, !sku.isEmpty {
                    Text("SKU: \(sku)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(CurrencyFormatter.nok(minor: product.priceMinor))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            // Add Button
            Button(action: onAdd) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add")
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.blue)
                .cornerRadius(10)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Price Override Sheet
struct PriceOverrideSheet: View {
    let item: CartItem
    var onSave: (Int?) -> Void
    @State private var overrideText = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header Icon
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.top, 40)
                
                VStack(spacing: 8) {
                    Text("Override Price")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter custom price in NOK")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Price Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("New Price")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    HStack {
                        Text("kr")
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $overrideText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 24, weight: .semibold))
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        let cents = Int((Double(overrideText.replacingOccurrences(of: ",", with: ".")) ?? 0) * 100)
                        onSave(cents)
                        dismiss()
                    }) {
                        Text("Save Price")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}
