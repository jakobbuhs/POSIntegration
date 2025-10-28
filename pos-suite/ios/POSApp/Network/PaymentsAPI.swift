//
//  PaymentsAPI.swift
//  POS-app-shopify
//
//  Created by Jakob Buhs on 28/10/2025.
//

import Foundation

struct CheckoutStartDTO: Codable {
  let status: String
  let client_transaction_id: String?
}

final class PaymentsAPI {
  static let shared = PaymentsAPI()
  private init() {}

  struct CheckoutBody: Encodable {
    let terminalId: String
    let amountMinor: Int
    let currency: String
    let orderRef: String
    let cart: [CartItem]
    let customer: Customer
  }

  func checkout(terminalId: String, amountMinor: Int, currency: String, orderRef: String, cart: [CartItem], customer: Customer) async throws -> CheckoutStartDTO {
    let body = CheckoutBody(terminalId: terminalId, amountMinor: amountMinor, currency: currency, orderRef: orderRef, cart: cart, customer: customer)
    return try await APIClient.shared.post("/payments/checkout", body: body)
  }

  func status(orderRef: String) async throws -> PaymentAttemptDTO {
    try await APIClient.shared.get("/payments/status?orderRef=\(orderRef)")
  }
}
