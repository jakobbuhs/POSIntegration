//
//  AuthView.swift
//  POS-app-shopify
//
//  Enhanced authentication view with modern design
//

import SwiftUI
import UIKit

struct AuthView: View {
    @EnvironmentObject var store: AppStore
    var onSuccess: () -> Void
    
    @State private var deviceCode = ""
    @State private var locationId = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?
    
    enum Field {
        case deviceCode, locationId
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Top Section with branding
                    topSection
                        .frame(height: geometry.size.height * 0.4)
                    
                    // Form Section
                    formSection
                        .frame(minHeight: geometry.size.height * 0.6)
                }
            }
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Top Section
    private var topSection: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // App Icon/Logo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "cart.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 8) {
                Text("POS System")
                    .font(.system(size: 32, weight: .bold))
                
                Text("Sign in to get started")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                // Device Code Field
                customTextField(
                    title: "Device Code",
                    placeholder: "Enter device code",
                    text: $deviceCode,
                    icon: "iphone",
                    field: .deviceCode
                )
                
                // Location ID Field
                customTextField(
                    title: "Location ID",
                    placeholder: "Enter location ID",
                    text: $locationId,
                    icon: "location.fill",
                    field: .locationId
                )
            }
            
            // Error Message
            if let error = errorMessage {
                errorView(message: error)
            }
            
            // Sign In Button
            Button(action: handleSignIn) {
                Group {
                    if isLoading {
                        HStack(spacing: 12) {
                            ProgressView()
                                .tint(.white)
                            Text("Signing in...")
                        }
                    } else {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Sign In")
                        }
                        .fontWeight(.semibold)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(isLoading || deviceCode.isEmpty || locationId.isEmpty)
            .opacity((deviceCode.isEmpty || locationId.isEmpty) ? 0.6 : 1.0)
            
            // Help Text
            VStack(spacing: 8) {
                Text("Need help?")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    // Show help or contact support
                }) {
                    Text("Contact Support")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(30, corners: [.topLeft, .topRight])
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: -5)
    }
    
    // MARK: - Custom Text Field
    private func customTextField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        icon: String,
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
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($focusedField, equals: field)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(focusedField == field ? Color.blue : Color.clear, lineWidth: 2)
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
    
    // MARK: - Sign In Handler
    private func handleSignIn() {
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                // Simulate authentication
                try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                
                // TODO: Replace with actual authentication logic
                // For now, just mark as authenticated
                await MainActor.run {
                    store.session.authed = true
                    store.session.deviceCode = deviceCode
                    store.session.locationId = locationId
                    isLoading = false
                    onSuccess()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Authentication failed. Please try again."
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Rounded Corner Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
