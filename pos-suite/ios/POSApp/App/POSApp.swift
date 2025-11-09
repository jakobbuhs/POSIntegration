//
//  POSApp.swift
//  POS-app-shopify
//
//  Created by Jakob Buhs on 27/10/2025.
//

import SwiftUI

@main
struct POSApp: App {
  @StateObject private var store = AppStore()

  var body: some Scene {
    WindowGroup {
      AppRouter()
        .environmentObject(store)
        .task {
        
        }
    }
  }
}
