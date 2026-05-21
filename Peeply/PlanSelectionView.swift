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
    @State private var isFinishingPurchaseFlow = false

    private var currentUser: PeeplyUser? {
        users.first
    }

    /// Ensure the app always has a user row before we update onboarding / purchase flags.
    ///
    /// The rest of the app assumes `users.first` is the current user, so purchase completion
    /// should never depend on a query race or an optional existing user record.
    @MainActor
    private func getOrCreateUser() -> PeeplyUser {
        if let currentUser {
            return currentUser
        }

        let newUser = PeeplyUser(email: "", subscriptionTier: .gettingStarted)
        modelContext.insert(newUser)
        try? modelContext.save()
        return newUser
    }

    /// Finalize local app state after a successful purchase or restore,
    /// then route deterministically to contact import.
    ///
    /// This keeps PlanSelectionView aligned with SplashView routing:
    /// - onboardingCompleted == true
    /// - contactsImported == false
    /// - next destination should be contact import
    @MainActor
    private func completePurchaseFlow() {
        guard !isFinishingPurchaseFlow else { return }
        isFinishingPurchaseFlow = true

        let user = getOrCreateUser()

        // Keep these flags in sync with the routing logic used by SplashView.
        user.onboardingCompleted = true
        user.contactsImported = false

        try? modelContext.save()

        // Reset the stack so we do not leave the user on a stale onboarding/paywall path.
        navigationPath = NavigationPath()
        navigationPath.append(AppRoute.contactImport)

        isFinishingPurchaseFlow = false
    }

    var body: some View {
        VStack(spacing: 0) {
            PaywallView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onPurchaseCompleted { customerInfo in
                    Task {
                        await GoMarketMe.shared.syncAllTransactions()

                        if customerInfo.entitlements["Peeply Pro"]?.isActive == true {
                            await MainActor.run {
                                completePurchaseFlow()
                            }
                        } else {
                            await MainActor.run {
                                purchaseErrorMessage = "Your purchase completed, but Peeply Pro is not showing as active yet. Please try Restore Purchases."
                                showPurchaseError = true
                            }
                        }
                    }
                }
                .onRestoreCompleted { customerInfo in
                    if customerInfo.entitlements["Peeply Pro"]?.isActive == true {
                        Task { @MainActor in
                            completePurchaseFlow()
                        }
                    } else {
                        purchaseErrorMessage = "No active Peeply Pro purchase was found to restore."
                        showPurchaseError = true
                    }
                }
                .onPurchaseFailure { _ in
                    purchaseErrorMessage = "Something went wrong with your purchase. Please try again or contact support@peeplyapp.com if the issue continues."
                    showPurchaseError = true
                }

            #if DEBUG
            Button(action: {
                Task { @MainActor in
                    completePurchaseFlow()
                }
            }) {
                Text("Skip Payment (Beta Only)")
                    .font(.caption)
                    .foregroundStyle(Color.gray)
                    .padding(.vertical, 8)
            }
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
