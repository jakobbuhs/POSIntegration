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

  var next: () -> Void

  var filtered: [Product] {
    if query.trimmingCharacters(in: .whitespaces).isEmpty { return store.products }
    return store.products.filter { $0.title.localizedCaseInsensitiveContains(query) || ($0.sku ?? "").contains(query) }
  }

  var body: some View {
    BottomCTA {
      VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
          Text("Products")
            .font(.largeTitle.bold())

          Text("Search and add items to the customer's cart.")
            .font(.body)
            .foregroundStyle(.secondary)
        }

        VStack(spacing: DesignSystem.Spacing.s) {
          TextField("Search products", text: $query)
            .textFieldStyle(.roundedBorder)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .accessibilityLabel("Search products")
            .accessibilityHint("Filter the list of products by name or SKU.")

          ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: DesignSystem.Spacing.m)], spacing: DesignSystem.Spacing.l) {
              ForEach(filtered) { product in
                ProductCard(product: product) {
                  store.add(product: product)
                }
              }
            }
            .padding(.bottom, DesignSystem.Spacing.l)
          }
        }
      }
      .padding(.horizontal, DesignSystem.Sizing.horizontalPadding)
      .padding(.top, DesignSystem.Spacing.l)
    } actions: {
      Button("View cart (\(store.cart.reduce(0) { $0 + $1.qty }))") {
        next()
      }
      .buttonStyle(PrimaryButtonStyle())
      .disabled(store.cart.isEmpty)
      .accessibilityLabel("View cart")
      .accessibilityHint("Opens the cart to review selected items.")
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

  private struct ProductCard: View {
    let product: Product
    var onAdd: () -> Void

    var body: some View {
      VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
        Text(product.title)
          .font(.title3.weight(.semibold))
          .multilineTextAlignment(.leading)

        Text(CurrencyFormatter.nok(minor: product.priceMinor))
          .font(.title3)
          .foregroundStyle(.secondary)

        Button {
          onAdd()
        } label: {
          Label("Add", systemImage: "plus")
            .labelStyle(.titleAndIcon)
        }
        .buttonStyle(PrimaryButtonStyle())
        .accessibilityLabel("Add \(product.title) to cart")
        .accessibilityHint("Adds the product to the shopping cart.")
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(DesignSystem.Spacing.m)
      .background(
        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.standard, style: .continuous)
          .fill(Color(uiColor: .secondarySystemBackground))
      )
    }
  }

  struct OverrideSheet: View, Identifiable {
    let id = UUID()
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
