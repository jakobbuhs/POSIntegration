//
//  PaymentView.swift
//  POS-app-shopify
//
//  Enhanced with modern design and better status visualization
//

import SwiftUI

struct PaymentView: View {
    @EnvironmentObject var store: AppStore
    @StateObject private var vm = PaymentViewModel()
    var onDone: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            Divider()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Amount Display
                    amountCard
                    
                    // Terminal Selection
                    terminalSelector
                    
                    // Payment Status
                    paymentStatusSection
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .onDisappear { vm.stop() }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            Text("Payment")
                .font(.system(size: 28, weight: .bold))
            
            Spacer()
            
            if case .pending = vm.state {
                Button(action: { vm.stop() }) {
                    Text("Cancel")
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Amount Card
    private var amountCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            VStack(spacing: 4) {
                Text("Amount to charge")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(CurrencyFormatter.nok(minor: store.amountMinor))
                    .font(.system(size: 40, weight: .bold))
            }
            
            if let orderId = store.orderRef {
                Text("Order #\(orderId)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Terminal Selector
    private var terminalSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Select Terminal", systemImage: "square.grid.2x2")
                .font(.headline)
                .foregroundColor(.primary)
            
            if store.session.terminals.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("No terminals available")
                        .font(.subheadline)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            } else {
                Picker("Terminal", selection: Binding(
                    get: { store.session.selectedTerminalId ?? "" },
                    set: { store.session.selectedTerminalId = $0 }
                )) {
                    ForEach(store.session.terminals) { terminal in
                        HStack {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                            Text(terminal.label)
                        }
                        .tag(terminal.id)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Payment Status Section
    @ViewBuilder
    private var paymentStatusSection: some View {
        VStack(spacing: 20) {
            switch vm.state {
            case .idle:
                idleState
                
            case .starting:
                loadingState(message: "Initializing payment...")
                
            case .pending:
                pendingState
                
            case .approved:
                successState
                
            case .declined(let reason):
                errorState(title: "Payment Declined", message: reason, icon: "xmark.circle.fill", color: .orange)
                
            case .error(let msg):
                errorState(title: "Payment Error", message: msg, icon: "exclamationmark.triangle.fill", color: .red)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - State Views
    
    private var idleState: some View {
        VStack(spacing: 16) {
            Image(systemName: "wave.3.right")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.3))
            
            Button(action: {
                Task { await vm.startCheckout(store: store) }
            }) {
                HStack {
                    Image(systemName: "creditcard")
                    Text("Send to Terminal")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    (store.session.selectedTerminalId == nil || store.amountMinor <= 0)
                    ? Color.gray
                    : Color.blue
                )
                .cornerRadius(12)
            }
            .disabled(store.session.selectedTerminalId == nil || store.amountMinor <= 0)
            
            if store.session.selectedTerminalId == nil {
                Text("Please select a terminal first")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private func loadingState(message: String) -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.blue)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var pendingState: some View {
        VStack(spacing: 20) {
            // Animated Card Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "creditcard")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                Text("Waiting for Card")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Please present card to terminal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Pulsing indicator
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .opacity(0.3)
                }
            }
            .padding(.top, 8)
            
            Button(action: { vm.stop() }) {
                Text("Cancel Payment")
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var successState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 8) {
                Text("Payment Approved!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(CurrencyFormatter.nok(minor: store.amountMinor))
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            if let info = vm.info {
                VStack(spacing: 6) {
                    if let last4 = info.last4, let scheme = info.scheme {
                        HStack {
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(.secondary)
                            Text("\(scheme) •••• \(last4)")
                                .font(.subheadline)
                        }
                    }
                    
                    if let approvalCode = info.approvalCode {
                        Text("Auth: \(approvalCode)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Button(action: {
                store.lastPayment = vm.info
                vm.stop()
                onDone()
            }) {
                HStack {
                    Text("Continue to Receipt")
                    Image(systemName: "arrow.right")
                }
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private func errorState(title: String, message: String, icon: String, color: Color) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { vm.state = .idle }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}
