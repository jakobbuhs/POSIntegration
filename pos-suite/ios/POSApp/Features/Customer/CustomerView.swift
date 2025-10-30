//
//  CustomerView.swift
//  POS-app-shopify
//
//  Enhanced with modern form design and better validation
//

import SwiftUI

struct CustomerView: View {
    @EnvironmentObject var store: AppStore
    var prev: () -> Void
    var next: () -> Void
    @State private var error: String?
    @FocusState private var focusedField: Field?
    
    enum Field {
        case firstName, email, phone
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            Divider()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Customer Icon
                    customerIcon
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        customTextField(
                            title: "First Name",
                            placeholder: "Enter first name",
                            text: $store.customer.firstName,
                            icon: "person.fill",
                            field: .firstName
                        )
                        
                        customTextField(
                            title: "Email",
                            placeholder: "customer@example.com",
                            text: $store.customer.email,
                            icon: "envelope.fill",
                            keyboardType: .emailAddress,
                            field: .email
                        )
                        
                        customTextField(
                            title: "Phone",
                            placeholder: "+47 123 45 678",
                            text: $store.customer.phone,
                            icon: "phone.fill",
                            keyboardType: .phonePad,
                            field: .phone
                        )
                    }
                    
                    // Error Message
                    if let error = error {
                        errorView(message: error)
                    }
                    
                    // Order Summary
                    orderSummary
                }
                .padding()
            }
            
            // Action Buttons
            actionButtons
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            Button(action: prev) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Cart")
                }
                .foregroundColor(.blue)
            }
            
            Spacer()
            
            Text("Customer Info")
                .font(.system(size: 28, weight: .bold))
            
            Spacer()
            
            // Placeholder for alignment
            Button(action: {}) {
                Image(systemName: "chevron.left")
            }
            .opacity(0)
            .disabled(true)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Customer Icon
    private var customerIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
            
            Image(systemName: "person.fill")
                .font(.system(size: 45))
                .foregroundColor(.blue)
        }
    }
    
    // MARK: - Custom Text Field
    private func customTextField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        icon: String,
        keyboardType: UIKeyboardType = .default,
        field: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                    .frame(width: 20)
                
                TextField(placeholder, text: text)
                    .textFieldStyle(.plain)
                    .keyboardType(keyboardType)
                    .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                    .disableAutocorrection(keyboardType == .emailAddress)
                    .focused($focusedField, equals: field)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(focusedField == field ? Color.blue : Color.gray.opacity(0.2), lineWidth: focusedField == field ? 2 : 1)
            )
        }
    }
    
    // MARK: - Error View
    private func errorView(message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.red)
            
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Order Summary
    private var orderSummary: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Order Summary")
                    .font(.headline)
                Spacer()
            }
            
            Divider()
            
            HStack {
                Text("Items")
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(store.cart.reduce(0) { $0 + $1.qty })")
            }
            
            HStack {
                Text("Total")
                    .fontWeight(.semibold)
                Spacer()
                Text(CurrencyFormatter.nok(minor: store.amountMinor))
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: validateAndProceed) {
                HStack {
                    Text("Continue to Payment")
                    Image(systemName: "arrow.right")
                }
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(store.cart.isEmpty ? Color.gray : Color.blue)
                .cornerRadius(12)
            }
            .disabled(store.cart.isEmpty)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Validation
    private func validateAndProceed() {
        // Clear previous error
        error = nil
        
        // Validate first name
        if store.customer.firstName.trimmingCharacters(in: .whitespaces).isEmpty {
            error = "Please enter a first name"
            focusedField = .firstName
            return
        }
        
        // Validate email
        if !Validators.email(store.customer.email) {
            error = "Please enter a valid email address"
            focusedField = .email
            return
        }
        
        // Validate phone
        if !Validators.phone(store.customer.phone) {
            error = "Please enter a valid phone number"
            focusedField = .phone
            return
        }
        
        // All valid, proceed
        next()
    }
}
