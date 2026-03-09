//
//  SupportView.swift
//  Peeply
//
//  Created by Jason LaChance on 1/18/26.
//

import SwiftUI
import SwiftData

struct SupportView: View {
    @Query private var users: [PeeplyUser]
    @Query private var contacts: [Contact]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var navigationPath = NavigationPath()
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
            // Contact Support
            Button(action: {
                if let url = URL(string: "mailto:support@peeplyapp.com") {
                    openURL(url)
                }
            }) {
                HStack {
                    Text("Contact Support")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.peeplyCharcoal.opacity(0.3))
                }
            }
            .buttonStyle(.plain)
            
            // About Peeply
            Button(action: {
                navigationPath.append(AppRoute.about)
            }) {
                HStack {
                    Text("About Peeply")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.peeplyCharcoal.opacity(0.3))
                }
            }
            .buttonStyle(.plain)
            
            // Privacy Policy
            Button(action: {
                navigationPath.append(AppRoute.privacyPolicy)
            }) {
                HStack {
                    Text("Privacy Policy")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.peeplyCharcoal.opacity(0.3))
                }
            }
            .buttonStyle(.plain)
            
            // Terms of Service
            Button(action: {
                navigationPath.append(AppRoute.termsOfService)
            }) {
                HStack {
                    Text("Terms of Service")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.peeplyCharcoal.opacity(0.3))
                }
            }
            .buttonStyle(.plain)
            
            // App Version
            HStack {
                Text("App Version")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundStyle(Color.peeplyCharcoal)
                Spacer()
                Text(appVersion)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundStyle(Color.peeplyCharcoal.opacity(0.6))
            }
            
            // Delete Account
            Button(action: {
                showDeleteConfirmation = true
            }) {
                HStack {
                    Text("Delete Account")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(.red)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.peeplyCharcoal.opacity(0.3))
                }
            }
            .buttonStyle(.plain)
            }
            .background(Color.peeplyBackground)
            .scrollContentBackground(.hidden)
            .navigationTitle("Support")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.peeplyCharcoal)
                    }
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                destinationView(for: route)
            }
            .alert("Delete Account", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("Are you sure you want to delete your account? This will permanently delete all your data and cannot be undone.")
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .about:
            AboutView()
        case .privacyPolicy:
            PrivacyPolicyView()
        case .termsOfService:
            TermsOfServiceView()
        default:
            EmptyView()
        }
    }
    
    private func deleteAccount() {
        // Delete all contacts
        for contact in contacts {
            modelContext.delete(contact)
        }
        
        // Delete user
        for user in users {
            modelContext.delete(user)
        }
        
        // Save changes
        try? modelContext.save()
        
        // Dismiss the sheet
        dismiss()
    }
}

#Preview {
    NavigationStack {
        SupportView()
            .modelContainer(for: [Contact.self, PeeplyUser.self], inMemory: true)
    }
}
