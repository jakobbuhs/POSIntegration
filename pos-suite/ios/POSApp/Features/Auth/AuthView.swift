//
//  AuthView.swift
//  POS-app-shopify
//
//  Created by Jakob Buhs on 28/10/2025.
//

import SwiftUI

struct AuthView: View {
  @EnvironmentObject var store: AppStore
  @State private var passcode: String = ""
  var onSuccess: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      Text("Enter POS passcode").font(.title2)
      SecureField("Passcode", text: $passcode)
        .keyboardType(.numberPad)
        .textFieldStyle(.roundedBorder)
        .frame(maxWidth: 320)
      Button("Unlock") {
        store.login(passcode: passcode)
        if store.session.authed { onSuccess() }
      }
      .buttonStyle(.borderedProminent)
      .disabled(passcode.isEmpty)
      Spacer()
    }
    .padding()
  }
}
