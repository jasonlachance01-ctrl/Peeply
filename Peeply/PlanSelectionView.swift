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
    }
}

#Preview {
    NavigationStack {
        PlanSelectionView(navigationPath: .constant(NavigationPath()))
    }
}
