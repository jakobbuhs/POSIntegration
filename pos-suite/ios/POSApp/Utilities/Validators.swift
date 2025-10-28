//
//  Validators.swift
//  POS-app-shopify
//
//  Created by Jakob Buhs on 28/10/2025.
//

import Foundation

enum Validators {
  static func email(_ s: String) -> Bool {
    s.contains("@") && s.contains(".")
  }
  static func phone(_ s: String) -> Bool {
    let digits = s.filter(\.isNumber)
    return digits.count >= 8
  }
}
