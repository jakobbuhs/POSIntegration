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
    VStack(alignment: .leading, spacing: 16) {
      Text("Payment").font(.largeTitle).bold()

      Picker("Terminal", selection: Binding(get: {
        store.session.selectedTerminalId ?? ""
      }, set: { store.session.selectedTerminalId = $0 })) {
        ForEach(store.session.terminals) { t in
          Text(t.label).tag(t.id)
        }
      }
      .pickerStyle(.menu)

      Text("Amount: \(CurrencyFormatter.nok(minor: store.amountMinor))").font(.title3)

      switch vm.state {
      case .idle:
        Button("Send to terminal") {
          Task { await vm.startCheckout(store: store) }
        }
        .buttonStyle(.borderedProminent)
        .disabled(store.session.selectedTerminalId == nil || store.amountMinor <= 0)

      case .starting:
        HStack { ProgressView(); Text("Starting…") }

      case .pending:
        VStack(alignment: .leading, spacing: 8) {
          HStack { ProgressView(); Text("Waiting for card on terminal…") }
          Text("Order \(store.orderRef)").font(.caption).foregroundColor(.secondary)
          Button("Cancel") { vm.stop() }.buttonStyle(.bordered)
        }

      case .approved:
        Text("Payment approved ✅").font(.title3).foregroundColor(.green)
        Button("Continue") {
          store.lastPayment = vm.info
          vm.stop()
          onDone()
        }.buttonStyle(.borderedProminent)

      case .declined(let reason):
        Text("Declined: \(reason)").foregroundColor(.red)
        Button("Retry") { vm.state = .idle }.buttonStyle(.borderedProminent)

      case .error(let msg):
        Text("Error: \(msg)").foregroundColor(.red)
        Button("Retry") { vm.state = .idle }.buttonStyle(.borderedProminent)
      }

      Spacer()
    }
    .padding()
    .onDisappear { vm.stop() }
  }
}
