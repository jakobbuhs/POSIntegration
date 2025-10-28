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
    VStack {
      HStack {
        TextField("Search products", text: $query).textFieldStyle(.roundedBorder)
        Button("Cart (\(store.cart.reduce(0) { $0 + $1.qty }))") { next() }
          .buttonStyle(.bordered)
      }.padding()

      List(filtered) { p in
        HStack {
          VStack(alignment: .leading) {
            Text(p.title).font(.headline)
            Text(CurrencyFormatter.nok(minor: p.priceMinor)).foregroundColor(.secondary)
          }
          Spacer()
          Button("+") { store.add(product: p) }
            .buttonStyle(.borderedProminent)
        }
      }
    }
    .sheet(item: $showOverrideFor) { item in
      OverrideSheet(item: item) { newMinor in
        store.setOverride(itemId: item.id, minor: newMinor)
      }
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
