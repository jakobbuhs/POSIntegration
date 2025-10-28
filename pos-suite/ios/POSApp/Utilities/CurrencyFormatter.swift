//
//  CurrencyFormatter.swift
//  POS-app-shopify
//
//  Created by Jakob Buhs on 28/10/2025.
//

import Foundation

enum CurrencyFormatter {
  static func nok(minor: Int) -> String {
    let n = NSNumber(value: Double(minor) / 100.0)
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.currencyCode = "NOK"
    f.maximumFractionDigits = 2
    return f.string(from: n) ?? "NOK \(Double(minor)/100)"
  }
}
