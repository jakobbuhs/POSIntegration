//
//  CatalogView.swift
//  POS-app-shopify
//
//  Enhanced with product loading and pull-to-refresh
//

import SwiftUI

struct CatalogView: View {
  @EnvironmentObject var store: AppStore
  @State private var query = ""
  @State private var showOverrideFor: CartItem?
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  var next: () -> Void

  var filtered: [Product] {
    if query.trimmingCharacters(in: .whitespaces).isEmpty {
      return store.products
    }
    return store.products.filter {
      $0.title.localizedCaseInsensitiveContains(query) ||
      ($0.sku ?? "").localizedCaseInsensitiveContains(query)
    }
  }
  
  // Responsive columns based on device size
  private var gridColumns: [GridItem] {
    let columnCount: Int
    if horizontalSizeClass == .regular {
      columnCount = 4 // iPad
    } else {
      columnCount = 2 // iPhone
    }
    return Array(repeating: GridItem(.flexible(), spacing: 16), count: columnCount)
  }

  var body: some View {
    VStack(spacing: 0) {
      // Header
      headerSection
      
      Divider()
      
      // Content
      if store.isLoadingProducts && store.products.isEmpty {
        loadingView
      } else if let error = store.productsError, store.products.isEmpty {
        errorView(error)
      } else if filtered.isEmpty && !query.isEmpty {
        searchEmptyView
      } else if store.products.isEmpty {
        emptyProductsView
      } else {
        productGrid
      }
    }
    .background(Color(.systemGroupedBackground))
    .task {
      // Load products when view appears
      if store.products.isEmpty {
        await store.loadProducts()
      }
    }
    .sheet(item: $showOverrideFor) { item in
      PriceOverrideSheet(item: item) { newMinor in
        store.setOverride(itemId: item.id, minor: newMinor)
        showOverrideFor = nil
      }
    }
  }
  
  // MARK: - Header Section
  private var headerSection: some View {
    VStack(spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Products")
            .font(.system(size: 28, weight: .bold))
          
          if store.isLoadingProducts {
            HStack(spacing: 8) {
              ProgressView()
                .controlSize(.small)
              Text("Loading...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
          } else {
            Text("\(store.products.count) items available")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
        }
        
        Spacer()
        
        // Refresh Button
        Button(action: {
          Task { await store.refreshProducts() }
        }) {
          Image(systemName: "arrow.clockwise")
            .font(.title3)
            .foregroundColor(.blue)
        }
        .disabled(store.isLoadingProducts)
        
        // Cart Button
        Button(action: next) {
          HStack(spacing: 8) {
            Image(systemName: "cart.fill")
            Text("\(store.cart.reduce(0) { $0 + $1.qty })")
              .fontWeight(.semibold)
          }
          .foregroundColor(.white)
          .padding(.horizontal, 20)
          .padding(.vertical, 12)
          .background(
            Capsule()
              .fill(store.cart.isEmpty ? Color.gray : Color.blue)
          )
        }
        .disabled(store.cart.isEmpty)
      }
      
      // Search Bar
      HStack {
        Image(systemName: "magnifyingglass")
          .foregroundColor(.gray)
        
        TextField("Search products or SKU", text: $query)
          .textFieldStyle(.plain)
          .autocapitalization(.none)
        
        if !query.isEmpty {
          Button(action: { query = "" }) {
            Image(systemName: "xmark.circle.fill")
              .foregroundColor(.gray)
          }
        }
      }
      .padding(12)
      .background(Color(.systemBackground))
      .cornerRadius(12)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(Color.gray.opacity(0.2), lineWidth: 1)
      )
    }
    .padding()
    .background(Color(.systemBackground))
  }
  
  // MARK: - Product Grid
  private var productGrid: some View {
    ScrollView {
      LazyVGrid(columns: gridColumns, spacing: 16) {
        ForEach(filtered) { product in
          ProductCard(product: product) {
            store.add(product: product)
          }
        }
      }
      .padding()
    }
    .refreshable {
      await store.refreshProducts()
    }
  }
  
  // MARK: - Loading View
  private var loadingView: some View {
    VStack(spacing: 16) {
      ProgressView()
        .controlSize(.large)
      
      Text("Loading products...")
        .font(.title3)
        .fontWeight(.medium)
      
      Text("Fetching from Shopify")
        .font(.subheadline)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
  
  // MARK: - Error View
  private func errorView(_ error: String) -> some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 60))
        .foregroundColor(.orange)
      
      Text("Failed to load products")
        .font(.title3)
        .fontWeight(.medium)
      
      Text(error)
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
      
      Button("Retry") {
        Task { await store.loadProducts() }
      }
      .buttonStyle(PrimaryButtonStyle())
      .frame(maxWidth: 200)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }
  
  // MARK: - Empty Search View
  private var searchEmptyView: some View {
    VStack(spacing: 16) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 60))
        .foregroundColor(.gray)
      
      Text("No products found")
        .font(.title3)
        .fontWeight(.medium)
      
      Text("Try adjusting your search")
        .font(.subheadline)
        .foregroundColor(.secondary)
      
      Button("Clear search") {
        query = ""
      }
      .buttonStyle(SecondaryButtonStyle())
      .frame(maxWidth: 200)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
  
  // MARK: - Empty Products View
  private var emptyProductsView: some View {
    VStack(spacing: 16) {
      Image(systemName: "shippingbox")
        .font(.system(size: 60))
        .foregroundColor(.gray)
      
      Text("No products available")
        .font(.title3)
        .fontWeight(.medium)
      
      Text("Add products to your Shopify store")
        .font(.subheadline)
        .foregroundColor(.secondary)
      
      Button("Refresh") {
        Task { await store.refreshProducts() }
      }
      .buttonStyle(PrimaryButtonStyle())
      .frame(maxWidth: 200)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

// MARK: - Product Card
private struct ProductCard: View {
  let product: Product
  var onAdd: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Product image placeholder
      RoundedRectangle(cornerRadius: 8)
        .fill(Color.gray.opacity(0.1))
        .aspectRatio(1, contentMode: .fit)
        .overlay(
          Image(systemName: "photo")
            .font(.largeTitle)
            .foregroundColor(.gray.opacity(0.3))
        )
      
      VStack(alignment: .leading, spacing: 4) {
        Text(product.title)
          .font(.subheadline)
          .fontWeight(.semibold)
          .lineLimit(2)
          .multilineTextAlignment(.leading)
        
        if let sku = product.sku, !sku.isEmpty {
          Text("SKU: \(sku)")
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        
        Text(CurrencyFormatter.nok(minor: product.priceMinor))
          .font(.headline)
          .foregroundColor(.blue)
      }
      
      Button {
        onAdd()
      } label: {
        HStack {
          Image(systemName: "plus")
          Text("Add")
        }
        .font(.subheadline.weight(.medium))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(8)
      }
    }
    .padding(12)
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
  }
}

// MARK: - Price Override Sheet
struct PriceOverrideSheet: View {
  let item: CartItem
  var onSave: (Int?) -> Void
  @State private var overrideText = ""
  @Environment(\.dismiss) var dismiss
  
  var body: some View {
    NavigationView {
      VStack(spacing: 24) {
        Image(systemName: "dollarsign.circle.fill")
          .font(.system(size: 60))
          .foregroundColor(.blue)
          .padding(.top, 40)
        
        VStack(spacing: 8) {
          Text("Override Price")
            .font(.title2)
            .fontWeight(.bold)
          
          Text("Enter custom price in NOK")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        
        VStack(alignment: .leading, spacing: 8) {
          Text("New Price")
            .font(.caption)
            .foregroundColor(.secondary)
            .textCase(.uppercase)
          
          HStack {
            Text("kr")
              .foregroundColor(.secondary)
            TextField("0.00", text: $overrideText)
              .keyboardType(.decimalPad)
              .font(.system(size: 24, weight: .semibold))
          }
          .padding()
          .background(Color(.systemGray6))
          .cornerRadius(12)
        }
        .padding(.horizontal)
        
        Spacer()
        
        VStack(spacing: 12) {
          Button(action: {
            let cents = Int((Double(overrideText.replacingOccurrences(of: ",", with: ".")) ?? 0) * 100)
            onSave(cents)
            dismiss()
          }) {
            Text("Save Price")
              .fontWeight(.semibold)
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color.blue)
              .cornerRadius(12)
          }
          
          Button(action: { dismiss() }) {
            Text("Cancel")
              .fontWeight(.medium)
              .foregroundColor(.blue)
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color(.systemGray6))
              .cornerRadius(12)
          }
        }
        .padding()
      }
      .navigationBarHidden(true)
    }
  }
}
