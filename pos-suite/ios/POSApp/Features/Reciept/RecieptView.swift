//
//  ReceiptView.swift
//  POS-app-shopify
//
//  Enhanced receipt view with modern design
//

import SwiftUI

struct ReceiptView: View {
    @EnvironmentObject var store: AppStore
    var onNewSale: () -> Void
    @State private var showShareSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            Divider()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Success Icon
                    successIcon
                    
                    // Receipt Card
                    receiptCard
                    
                    // Actions
                    actionButtons
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            Spacer()
            Text("Receipt")
                .font(.system(size: 28, weight: .bold))
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Success Icon
    private var successIcon: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.2), Color.green.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 4) {
                Text("Payment Complete!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Transaction successful")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Receipt Card
    private var receiptCard: some View {
        VStack(spacing: 20) {
            // Store Info
            VStack(spacing: 4) {
                Text("Your Store")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("Thank you for your purchase")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Order Details
            VStack(alignment: .leading, spacing: 12) {
                if let orderId = store.orderRef {
                    DetailRow(label: "Order Number", value: "#\(orderId)")
                }
                
                DetailRow(label: "Date", value: formatDate(Date()))
                
                if !store.customer.firstName.isEmpty {
                    DetailRow(label: "Customer", value: store.customer.firstName)
                }
                
                if !store.customer.email.isEmpty {
                    DetailRow(label: "Email", value: store.customer.email)
                }
            }
            
            Divider()
            
            // Items
            VStack(alignment: .leading, spacing: 12) {
                Text("Items")
                    .font(.headline)
                
                ForEach(store.cart) { item in
                    if let product = store.products.first(where: { $0.id == item.productId }) {
                        ItemRow(item: item, product: product)
                    }
                }
            }
            
            Divider()
            
            // Totals
            VStack(spacing: 8) {
                HStack {
                    Text("Subtotal")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(CurrencyFormatter.nok(minor: store.amountMinor))
                }
                
                HStack {
                    Text("Total")
                        .font(.headline)
                    Spacer()
                    Text(CurrencyFormatter.nok(minor: store.amountMinor))
                        .font(.headline)
                }
            }
            
            // Payment Info
            if let payment = store.lastPayment {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Payment Method")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "creditcard.fill")
                            .foregroundColor(.blue)
                        
                        if let scheme = payment.scheme, let last4 = payment.last4 {
                            Text("\(scheme) •••• \(last4)")
                        } else {
                            Text("Card payment")
                        }
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    if let approvalCode = payment.approvalCode {
                        Text("Authorization: \(approvalCode)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: { showShareSheet = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Send Receipt")
                }
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            
            Button(action: {
                // Reset store for new sale
                store.cart.removeAll()
                store.customer = Customer()
                store.orderRef = nil
                store.lastPayment = nil
                onNewSale()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("New Sale")
                }
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

struct ItemRow: View {
    let item: CartItem
    let product: Product
    
    private var itemTotal: Int {
        let price = item.overrideMinor ?? product.priceMinor
        return price * item.qty
    }
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.title)
                    .font(.subheadline)
                
                Text("Qty: \(item.qty)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(CurrencyFormatter.nok(minor: itemTotal))
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}
