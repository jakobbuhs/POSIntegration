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

  var body: some View {
    BottomCTA {
      VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
        Text("Cart")
          .font(.largeTitle.bold())

        if store.cart.isEmpty {
          VStack(spacing: DesignSystem.Spacing.s) {
            Image(systemName: "cart")
              .font(.largeTitle)
              .foregroundStyle(.secondary)
            Text("Your cart is empty")
              .font(.title2.weight(.semibold))
            Text("Add items from the catalog to get started.")
              .font(.body)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity)
          .padding(DesignSystem.Spacing.l)
        } else {
          ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.m) {
              ForEach(store.cart) { item in
                if let product = store.products.first(where: { $0.id == item.productId }) {
                  CartItemCard(
                    product: product,
                    item: item,
                    quantity: Binding(
                      get: { item.qty },
                      set: { newValue in
                        if let index = store.cart.firstIndex(where: { $0.id == item.id }) {
                          store.cart[index].qty = max(1, newValue)
                        }
                      }
                    ),
                    onRemove: { store.remove(item: item) }
                  )
                }
              }
            }
            .padding(.bottom, DesignSystem.Spacing.l)
          }

          VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Total")
              .font(.body)
              .foregroundStyle(.secondary)
            Text(CurrencyFormatter.nok(minor: store.amountMinor))
              .font(.title2.weight(.semibold))
          }
        }
      }
      .padding(.horizontal, DesignSystem.Sizing.horizontalPadding)
      .padding(.top, DesignSystem.Spacing.l)
    } actions: {
      if !store.cart.isEmpty {
        Button("Review customer details") {
          next()
        }
        .buttonStyle(PrimaryButtonStyle())
        .accessibilityLabel("Review customer details")
        .accessibilityHint("Continue to add customer information before taking payment.")
      }

      Button("Back to catalog") {
        prev()
      }
      .buttonStyle(SecondaryButtonStyle())
      .accessibilityLabel("Back to catalog")
      .accessibilityHint("Returns to the product catalog to add more items.")
    }
}

private struct CartItemCard: View {
  let product: Product
  let item: CartItem
  var quantity: Binding<Int>
  var onRemove: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
      VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
        Text(product.title)
          .font(.title3.weight(.semibold))
          .multilineTextAlignment(.leading)

        if let overrideMinor = item.overrideMinor {
          HStack(spacing: DesignSystem.Spacing.s) {
            Text(CurrencyFormatter.nok(minor: product.priceMinor))
              .font(.body)
              .foregroundStyle(.secondary)
              .strikethrough()
            Text(CurrencyFormatter.nok(minor: overrideMinor))
              .font(.body.weight(.semibold))
              .foregroundStyle(.tint)
          }
        } else {
          Text(CurrencyFormatter.nok(minor: product.priceMinor))
            .font(.body)
            .foregroundStyle(.secondary)
        }
      }

      Stepper(value: quantity, in: 1...99) {
        Text("Quantity: \(quantity.wrappedValue)")
          .font(.body)
      }
      .controlSize(.large)

      Button("Remove") {
        onRemove()
      }
      .buttonStyle(SecondaryButtonStyle())
      .accessibilityLabel("Remove \(product.title) from cart")
      .accessibilityHint("Removes the item and its quantity from the order.")
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(DesignSystem.Spacing.m)
    .background(
      RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.standard, style: .continuous)
        .fill(Color(uiColor: .secondarySystemBackground))
    )
    .accessibilityElement(children: .contain)
  }
}
