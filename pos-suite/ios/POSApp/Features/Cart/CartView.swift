//
//  CartView.swift
//  POS-app-shopify
//
//  Created by Jakob Buhs on 28/10/2025.
//

import SwiftUI

struct CartView: View {
  @EnvironmentObject var store: AppStore
  var prev: () -> Void
  var next: () -> Void

  var body: some View {
    VStack {
      List {
        ForEach(store.cart) { item in
          if let p = store.products.first(where: { $0.id == item.productId }) {
            HStack {
              VStack(alignment: .leading, spacing: 6) {
                Text(p.title).font(.headline)
                if let o = item.overrideMinor {
                  HStack(spacing: 8) {
                    Text(CurrencyFormatter.nok(minor: p.priceMinor)).strikethrough().foregroundColor(.secondary)
                    Text(CurrencyFormatter.nok(minor: o)).foregroundColor(.blue)
                  }
                } else {
                  Text(CurrencyFormatter.nok(minor: p.priceMinor)).foregroundColor(.secondary)
                }
              }
              Spacer()
              Stepper(value: Binding(get: { item.qty },
                                     set: { newValue in
                                       if let idx = store.cart.firstIndex(where: { $0.id == item.id }) {
                                         store.cart[idx].qty = max(1, newValue)
                                       }
                                     }), in: 1...99) { Text("Qty \(item.qty)") }
              Button(role: .destructive) { store.remove(item: item) } label: { Image(systemName: "trash") }
            }
          }
        }
      }

      HStack {
        Text("Total: \(CurrencyFormatter.nok(minor: store.amountMinor))")
          .font(.title3).bold()
        Spacer()
        Button("Back") { prev() }
        Button("Next") { next() }.buttonStyle(.borderedProminent).disabled(store.cart.isEmpty)
      }
      .padding()
    }
    .navigationTitle("Cart")
  }
}
