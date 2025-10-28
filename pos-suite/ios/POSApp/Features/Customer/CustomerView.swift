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
    Form {
      Section("Customer") {
        TextField("First name", text: $store.customer.firstName)
        TextField("Email", text: $store.customer.email).keyboardType(.emailAddress)
        TextField("Phone", text: $store.customer.phone).keyboardType(.phonePad)
        if let e = error { Text(e).foregroundColor(.red) }
      }
    }
    .navigationTitle("Customer")
    .toolbar {
      ToolbarItem(placement: .cancellationAction) { Button("Back") { prev() } }
      ToolbarItem(placement: .confirmationAction) {
        Button("Next") {
          if store.customer.firstName.isEmpty {
            error = "First name required"; return
          }
          if !Validators.email(store.customer.email) {
            error = "Email invalid"; return
          }
          if !Validators.phone(store.customer.phone) {
            error = "Phone invalid"; return
          }
          error = nil
          next()
        }.disabled(store.cart.isEmpty)
      }
    }
  }
}
