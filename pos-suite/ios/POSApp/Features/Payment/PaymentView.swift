//
//  PaymentView.swift
//  POS-app-shopify
//
//  Created by Jakob Buhs on 28/10/2025.
//

import SwiftUI

struct PaymentView: View {
  @EnvironmentObject var store: AppStore
  @StateObject private var vm = PaymentViewModel()
  var onDone: () -> Void

  var body: some View {
    BottomCTA {
      VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
        Text("Payment")
          .font(.largeTitle.bold())

        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
          Text("Terminal")
            .font(.body.weight(.semibold))
          Picker("Terminal", selection: Binding(get: {
            store.session.selectedTerminalId ?? ""
          }, set: { store.session.selectedTerminalId = $0 })) {
            ForEach(store.session.terminals) { terminal in
              Text(terminal.label).tag(terminal.id)
            }
          }
          .pickerStyle(.menu)
        }

        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
          Text("Amount due")
            .font(.body)
            .foregroundStyle(.secondary)
          Text(CurrencyFormatter.nok(minor: store.amountMinor))
            .font(.title2.weight(.semibold))
        }

        statusContent
      }
      .padding(.horizontal, DesignSystem.Sizing.horizontalPadding)
      .padding(.top, DesignSystem.Spacing.l)
    } actions: {
      actionButtons
    }
    .onDisappear { vm.stop() }
  }

  @ViewBuilder
  private var statusContent: some View {
    switch vm.state {
    case .idle:
      Text("Send the total to the selected terminal to begin payment.")
        .font(.body)
        .foregroundStyle(.secondary)

    case .starting:
      HStack(spacing: DesignSystem.Spacing.s) {
        ProgressView()
        Text("Sending payment to the terminal…")
          .font(.body)
      }

    case .pending:
      VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
        HStack(spacing: DesignSystem.Spacing.s) {
          ProgressView()
          Text("Waiting for the customer to tap or insert their card…")
            .font(.body)
        }
        Text("Order \(store.orderRef)")
          .font(.body)
          .foregroundStyle(.secondary)
      }

    case .approved:
      Text("Payment approved ✅")
        .font(.title3.weight(.semibold))
        .foregroundStyle(.green)

    case .declined(let reason):
      Text("Payment declined: \(reason)")
        .font(.body)
        .foregroundStyle(.red)

    case .error(let message):
      Text("Error: \(message)")
        .font(.body)
        .foregroundStyle(.red)
    }
  }

  @ViewBuilder
  private var actionButtons: some View {
    switch vm.state {
    case .idle:
      Button("Send to terminal") {
        Task { await vm.startCheckout(store: store) }
      }
      .buttonStyle(PrimaryButtonStyle())
      .disabled(store.session.selectedTerminalId == nil || store.amountMinor <= 0)
      .accessibilityLabel("Send total to payment terminal")
      .accessibilityHint("Initiates checkout on the selected terminal.")

    case .starting:
      Button {
      } label: {
        HStack(spacing: DesignSystem.Spacing.s) {
          ProgressView()
          Text("Sending…")
        }
      }
      .buttonStyle(PrimaryButtonStyle())
      .disabled(true)

    case .pending:
      Button("Cancel payment") {
        vm.stop()
      }
      .buttonStyle(SecondaryButtonStyle())
      .accessibilityLabel("Cancel payment")
      .accessibilityHint("Stops the current checkout on the terminal.")

    case .approved:
      Button("Continue") {
        store.lastPayment = vm.info
        vm.stop()
        onDone()
      }
      .buttonStyle(PrimaryButtonStyle())
      .accessibilityLabel("Continue to receipt")
      .accessibilityHint("Moves on to the receipt screen.")

    case .declined:
      retryButtons

    case .error:
      retryButtons
    }
  }

  @ViewBuilder
  private var retryButtons: some View {
    Button("Retry payment") {
      vm.state = .idle
    }
    .buttonStyle(PrimaryButtonStyle())
    .accessibilityLabel("Retry payment")
    .accessibilityHint("Attempts to send the payment to the terminal again.")

    Button("Cancel payment") {
      vm.stop()
    }
    .buttonStyle(SecondaryButtonStyle())
    .accessibilityLabel("Cancel payment")
    .accessibilityHint("Stops the current checkout and keeps the cart open.")
  }
}
