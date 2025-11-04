//
//  RecieptView.swift
//  POS-app-shopify
//
//  Created by Jakob Buhs on 28/10/2025.
//

import SwiftUI

struct ReceiptView: View {
  @EnvironmentObject var store: AppStore
  var onNewSale: () -> Void

  var body: some View {
    BottomCTA {
      VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
        Text("Receipt")
          .font(.largeTitle.bold())

        receiptDetails
      }
      .padding(.horizontal, DesignSystem.Sizing.horizontalPadding)
      .padding(.top, DesignSystem.Spacing.l)
    } actions: {
      Button("Start new sale") {
        store.resetSale()
        onNewSale()
      }
      .buttonStyle(PrimaryButtonStyle())
      .accessibilityLabel("Start a new sale")
      .accessibilityHint("Resets the cart and returns to the product catalog.")
    }
    .navigationBarBackButtonHidden(true)
  }

  @ViewBuilder
  private var receiptDetails: some View {
    if let payment = store.lastPayment, payment.status.uppercased() == "APPROVED" {
      VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
        Text("Payment successful")
          .font(.title2.weight(.semibold))
          .foregroundStyle(.green)

        if let scheme = payment.scheme, let last4 = payment.last4 {
          Text("\(scheme.uppercased()) •••• \(last4)")
            .font(.body)
            .foregroundStyle(.secondary)
        }

        if let transactionId = payment.transactionId {
          Text("Transaction ID: \(transactionId)")
            .font(.body)
            .foregroundStyle(.secondary)
        }
      }
    } else if let payment = store.lastPayment {
      VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
        Text("Payment \(payment.status)")
          .font(.title2.weight(.semibold))
          .foregroundStyle(.orange)

        if let message = payment.message {
          Text(message)
            .font(.body)
            .foregroundStyle(.secondary)
        }
      }
    } else {
      Text("No payment info")
        .font(.body)
        .foregroundStyle(.secondary)
    }
  }
}
