//
//  Product.swift
//  POS-app-shopify
//
//  Created by Jakob Buhs on 28/10/2025.
//

import Foundation

struct Product: Identifiable, Codable, Hashable {
  let id: String
  let title: String
  let priceMinor: Int
  let currency: String
  let sku: String?
}
