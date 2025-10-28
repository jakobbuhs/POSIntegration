//
//  TerminalRef.swift
//  POS-app-shopify
//
//  Created by Jakob Buhs on 28/10/2025.
//

import Foundation

struct TerminalRef: Identifiable, Codable, Hashable {
  let id: String       // SumUp reader id, e.g. rdr_...
  let label: String    // "Solo Oslo 1"
}
