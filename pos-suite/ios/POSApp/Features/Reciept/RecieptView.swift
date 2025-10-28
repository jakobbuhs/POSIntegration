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
    VStack(spacing: 16) {
      if let p = store.lastPayment, p.status.uppercased() == "APPROVED" {
        Text("Payment successful").font(.title).foregroundColor(.green)
        if let scheme = p.scheme, let last4 = p.last4 {
          Text("\(scheme.uppercased()) •••• \(last4)").foregroundColor(.secondary)
        }
        if let id = p.transactionId {
          Text("Txn: \(id)").font(.caption).foregroundColor(.secondary)
        }
      } else if let p = store.lastPayment {
        Text("Payment \(p.status)").font(.title2).foregroundColor(.orange)
        if let m = p.message { Text(m).foregroundColor(.secondary) }
      } else {
        Text("No payment info").foregroundColor(.secondary)
      }

      Button("New sale") {
        store.resetSale()
        onNewSale()
      }
      .buttonStyle(.borderedProminent)

      Spacer()
    }
    .padding()
    .navigationBarBackButtonHidden(true)
  }
}
