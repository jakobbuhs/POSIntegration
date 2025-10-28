//
//  CartItem.swift
//  POS-app-shopify
//
//  Created by Jakob Buhs on 28/10/2025.
//

import Foundation

struct CartItem: Identifiable, Codable, Hashable {
  let id: UUID
  let productId: String
  var qty: Int
  var overrideMinor: Int? // per-item override
}
