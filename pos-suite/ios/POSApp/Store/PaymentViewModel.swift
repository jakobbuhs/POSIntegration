//
//  PaymentViewModel.swift
//  POS-app-shopify
//
//  Created by Jakob Buhs on 28/10/2025.
//

import Foundation

@MainActor
final class PaymentViewModel: ObservableObject {
  enum State: Equatable { case idle, starting, pending, approved, declined(String), error(String) }

  @Published var state: State = .idle
  @Published var info: PaymentAttemptDTO?
  private var pollTask: Task<Void, Never>?

  func startCheckout(store: AppStore) async {
    guard let terminal = store.session.selectedTerminalId else {
      state = .error("No terminal selected")
      return
    }
    state = .starting
    do {
      _ = try await PaymentsAPI.shared.checkout(
        terminalId: terminal,
        amountMinor: store.amountMinor,
        currency: "NOK",
        orderRef: store.orderRef,
        cart: store.cart,
        customer: store.customer
      )
      state = .pending
      beginPolling(orderRef: store.orderRef)
    } catch {
      state = .error(error.localizedDescription)
    }
  }

  private func beginPolling(orderRef: String) {
    pollTask?.cancel()
    pollTask = Task.detached { [weak self] in
      guard let self else { return }
      while !Task.isCancelled {
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        do {
          let s = try await PaymentsAPI.shared.status(orderRef: orderRef)
          await self.update(with: s)
          if s.status != "PENDING" { break }
        } catch {
          // keep polling on transient errors
        }
      }
    }
  }

  @MainActor
  private func update(with dto: PaymentAttemptDTO) {
    self.info = dto
    switch dto.status.uppercased() {
    case "APPROVED": state = .approved
    case "DECLINED": state = .declined(dto.message ?? "Declined")
    case "CANCELLED": state = .declined("Cancelled")
    case "ERROR": state = .error(dto.message ?? "Error")
    default: state = .pending
    }
  }

  func stop() {
    pollTask?.cancel()
    pollTask = nil
  }
}
