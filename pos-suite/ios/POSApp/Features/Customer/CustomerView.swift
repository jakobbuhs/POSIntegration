//
//  CustomerView.swift
//  POS-app-shopify
//
//  Created by Jakob Buhs on 28/10/2025.
//

import SwiftUI

struct CustomerView: View {
  @EnvironmentObject var store: AppStore
  var prev: () -> Void
  var next: () -> Void
  @State private var error: String?

  var body: some View {
    BottomCTA {
      Form {
        Section("Customer") {
          TextField("First name", text: $store.customer.firstName)
            .textContentType(.givenName)
          TextField("Email", text: $store.customer.email)
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
          TextField("Phone", text: $store.customer.phone)
            .keyboardType(.phonePad)
            .textContentType(.telephoneNumber)
          if let errorMessage = error {
            Text(errorMessage)
              .font(.body)
              .foregroundStyle(.red)
          }
        }
      }
    } actions: {
      Button("Continue to payment") {
        guard validate() else { return }
        next()
      }
      .buttonStyle(PrimaryButtonStyle())
      .disabled(store.cart.isEmpty)
      .accessibilityLabel("Continue to payment")
      .accessibilityHint("Opens the payment screen when all customer details are valid.")

      Button("Back to cart") {
        prev()
      }
      .buttonStyle(SecondaryButtonStyle())
      .accessibilityLabel("Back to cart")
      .accessibilityHint("Returns to the cart without saving changes.")
    }
    .navigationTitle("Customer")
  }

  private func validate() -> Bool {
    if store.customer.firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      error = "First name required"
      return false
    }
    if !Validators.email(store.customer.email) {
      error = "Email invalid"
      return false
    }
    if !Validators.phone(store.customer.phone) {
      error = "Phone invalid"
      return false
    }
    error = nil
    return true
  }
}
