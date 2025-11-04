//
//  CatalogView.swift
//  POS-app-shopify
//
//  Created by Jakob Buhs on 28/10/2025.
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
    .sheet(item: $showOverrideFor) { item in
      OverrideSheet(item: item) { newMinor in
        store.setOverride(itemId: item.id, minor: newMinor)
      }
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

    var body: some View {
      NavigationView {
        Form {
          Section("Override price (NOK)") {
            TextField("e.g. 99.00", text: $overrideText).keyboardType(.decimalPad)
          }
        }
        .navigationTitle("Override Price")
        .toolbar {
          ToolbarItem(placement: .cancellationAction) { Button("Cancel") { onSave(nil) } }
          ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
              let cents = Int((Double(overrideText.replacingOccurrences(of: ",", with: ".")) ?? 0) * 100)
              onSave(cents)
            }
          }
        }
      }
    }
  }
}
