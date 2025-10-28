//
//  PaymentAttemptDT0.swift
//  POS-app-shopify
//
//  Created by Jakob Buhs on 28/10/2025.
//

import Foundation

struct PaymentAttemptDTO: Codable {
  let status: String            // PENDING | APPROVED | DECLINED | ERROR | CANCELLED
  let transactionId: String?
  let approvalCode: String?
  let scheme: String?
  let last4: String?
  let shopifyOrderId: String?
  let message: String?
}
