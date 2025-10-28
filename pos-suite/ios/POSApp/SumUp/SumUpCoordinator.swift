
//
//  SumUpCoordinator.swift
//  POS-app-shopify
//
//  Created by Jakob Buhs on 27/10/2025.
//
import UIKit
import SumUpSDK

enum SumUpFlowError: Error { case notLoggedIn, failed }

final class SumUpCoordinator {
  static let shared = SumUpCoordinator()

  func setup() {
    // Load Affiliate Key from Secrets.plist
    guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
          let dict = NSDictionary(contentsOfFile: path),
          let key = dict["SUMUP_AFFILIATE_KEY"] as? String else { return }
    SumUpSDK.setup(withAPIKey: key)
  }

  func ensureLogin(presenting: UIViewController) async throws {
    if SumUpSDK.isLoggedIn { return }
    try await withCheckedThrowingContinuation { cont in
      SumUpSDK.presentLogin(from: presenting) { success, error in
        if success { cont.resume() } else { cont.resume(throwing: error ?? SumUpFlowError.notLoggedIn) }
      }
    }
  }

  func checkout(amount: NSDecimalNumber, title: String, currency: String, presenting: UIViewController)
  async throws -> (txCode: String, cardType: String?) {
    let request = CheckoutRequest(total: amount, title: title, currencyCode: currency)
    return try await withCheckedThrowingContinuation { cont in
      SumUpSDK.checkout(with: request, from: presenting) { result, error in
        guard error == nil, let r = result, r.success == true else {
          cont.resume(throwing: error ?? SumUpFlowError.failed); return
        }
        cont.resume(returning: (r.transactionCode ?? "", r.cardType))
      }
    }
  }
}
