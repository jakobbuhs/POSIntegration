//
//  CurrencyFormatter.swift
//  POS-app-shopify
//
//  Created by Jakob Buhs on 28/10/2025.
//

import Foundation

struct CurrencyFormatter {
    static func nok(minor: Int) -> String {
        let major = Double(minor) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "NOK"
        formatter.locale = Locale(identifier: "nb_NO")
        return formatter.string(from: NSNumber(value: major)) ?? "kr 0.00"
    }
}
