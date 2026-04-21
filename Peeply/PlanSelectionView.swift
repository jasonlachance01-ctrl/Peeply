//
//  PlanSelectionView.swift
//  Peeply
//
//  Created by Jason LaChance on 1/18/26.
//

import SwiftUI
import SwiftData
import RevenueCat
import RevenueCatUI
import GoMarketMe

struct PlanSelectionView: View {
    @Binding var navigationPath: NavigationPath
    @Query private var users: [PeeplyUser]
    @Environment(\.modelContext) private var modelContext
    @State private var showPurchaseError = false
    @State private var purchaseErrorMessage = ""
    
    private var currentUser: PeeplyUser? {
        users.first
    }
    
    var body: some View {
        VStack(spacing: 0) {
            PaywallView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onPurchaseCompleted { customerInfo in
                    currentUser?.contactsImported = false
                    try? modelContext.save()
                    Task { await GoMarketMe.shared.syncAllTransactions() }
                    if customerInfo.entitlements["Peeply Pro"]?.isActive == true {
                        navigationPath.append(AppRoute.contactImport)
                    }
                }
                .onRestoreCompleted { customerInfo in
                    if customerInfo.entitlements["Peeply Pro"]?.isActive == true {
                        navigationPath.append(AppRoute.contactImport)
                    }
                }
                .onPurchaseFailure { _ in
                    purchaseErrorMessage = "Something went wrong with your purchase. Please try again or contact support@peeplyapp.com if the issue continues."
                    showPurchaseError = true
                }
            
            #if DEBUG
            Button(action: {
                navigationPath.append(AppRoute.contactImport)
            }) {
                Text("Skip Payment (Beta Only)")
                    .font(.caption)
                    .foregroundStyle(Color.gray)
            }
            .padding(.vertical, 8)
            #endif
        }
        .navigationBarBackButtonHidden(true)
        .alert("Purchase Failed", isPresented: $showPurchaseError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(purchaseErrorMessage)
        }
    }
}

#Preview {
    NavigationStack {
        PlanSelectionView(navigationPath: .constant(NavigationPath()))
    }
}
