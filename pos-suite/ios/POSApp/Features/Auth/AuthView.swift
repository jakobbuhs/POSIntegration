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
    BottomCTA {
      VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
        Text("Enter POS passcode")
          .font(.title2.weight(.semibold))

        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
          Text("Enter the 4-digit passcode provided for this register.")
            .font(.body)
            .foregroundStyle(.secondary)

          SecureField("Passcode", text: $passcode)
            .keyboardType(.numberPad)
            .textFieldStyle(.roundedBorder)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .accessibilityLabel("POS passcode")
            .accessibilityHint("Enter the four digit code to unlock the app.")
        }
      }
      .padding(.horizontal, DesignSystem.Sizing.horizontalPadding)
      .padding(.top, DesignSystem.Spacing.l)
    } actions: {
      Button("Unlock") {
        store.login(passcode: passcode)
        if store.session.authed { onSuccess() }
      }
      .buttonStyle(PrimaryButtonStyle())
      .disabled(passcode.isEmpty)
      .accessibilityLabel("Unlock point of sale")
      .accessibilityHint("Unlocks the register when the passcode is correct.")
    }
  }
}
