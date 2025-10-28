//
//  Debounce.swift
//  POS-app-shopify
//
//  Created by Jakob Buhs on 28/10/2025.
//

import Foundation

actor Debouncer {
  private var task: Task<Void, Never>?
  func run(after seconds: Double, _ block: @escaping () -> Void) {
    task?.cancel()
    task = Task { [seconds] in
      try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
      if !Task.isCancelled { block() }
    }
  }
}
