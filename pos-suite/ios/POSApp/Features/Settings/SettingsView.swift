//
//  SettingsView.swift
//  POS-app-shopify
//
//  Enhanced settings view with modern design
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showingLogoutAlert = false
    @State private var showingClearDataAlert = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Account Section
                Section {
                    accountInfoRow
                } header: {
                    Text("Account")
                }
                
                // Terminal Section
                Section {
                    terminalSelectionRow
                    
                    if !store.session.terminals.isEmpty {
                        ForEach(store.session.terminals) { terminal in
                            terminalRow(terminal: terminal)
                        }
                    }
                } header: {
                    Text("Terminals")
                } footer: {
                    Text("Select the default terminal for processing payments")
                }
                
                // Location Section
                Section {
                    infoRow(
                        icon: "location.fill",
                        title: "Location ID",
                        value: store.session.locationId ?? "Not set",
                        color: .orange
                    )
                    
                    infoRow(
                        icon: "iphone",
                        title: "Device Code",
                        value: store.session.deviceCode ?? "Not set",
                        color: .purple
                    )
                } header: {
                    Text("Location")
                }
                
                // App Info Section
                Section {
                    infoRow(
                        icon: "info.circle.fill",
                        title: "Version",
                        value: "1.0.0",
                        color: .blue
                    )
                    
                    NavigationLink(destination: Text("About")) {
                        Label("About", systemImage: "doc.text.fill")
                    }
                    
                    NavigationLink(destination: Text("Help & Support")) {
                        Label("Help & Support", systemImage: "questionmark.circle.fill")
                    }
                } header: {
                    Text("App Info")
                }
                
                // Data Section
                Section {
                    Button(action: { showingClearDataAlert = true }) {
                        HStack {
                            Label("Clear Cache", systemImage: "trash.fill")
                                .foregroundColor(.orange)
                            Spacer()
                        }
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text("Clear cached products and local data")
                }
                
                // Logout Section
                Section {
                    Button(action: { showingLogoutAlert = true }) {
                        HStack {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Sign Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    store.session.authed = false
                    store.cart.removeAll()
                    store.customer = Customer()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Clear Data", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    store.products.removeAll()
                    // Clear other cached data
                }
            } message: {
                Text("This will clear all cached data. You'll need to reload products.")
            }
        }
    }
    
    // MARK: - Account Info Row
    private var accountInfoRow: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(store.customer.firstName.isEmpty ? "User" : store.customer.firstName)
                    .font(.headline)
                
                if !store.customer.email.isEmpty {
                    Text(store.customer.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Terminal Selection Row
    private var terminalSelectionRow: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(store.session.selectedTerminalId != nil ? .green : .gray)
            
            Text("Selected Terminal")
                .font(.subheadline)
            
            Spacer()
            
            if let selectedId = store.session.selectedTerminalId,
               let terminal = store.session.terminals.first(where: { $0.id == selectedId }) {
                Text(terminal.label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("None")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Terminal Row
    private func terminalRow(terminal: TerminalRef) -> some View {
        Button(action: {
            store.session.selectedTerminalId = terminal.id
        }) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(.blue)
                
                Text(terminal.label)
                
                Spacer()
                
                if store.session.selectedTerminalId == terminal.id {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Info Row
    private func infoRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}
