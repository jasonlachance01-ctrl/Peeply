//
//  RootView.swift
//  Peeply
//
//  Created by Jason LaChance on 1/18/26.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @State private var navigationPath = NavigationPath()
    @Query private var users: [PeeplyUser]
    @Query private var contacts: [Contact]
    @Environment(\.modelContext) private var modelContext
    
    private var currentUser: PeeplyUser? {
        users.first
    }
    
    private var rootView: AppRoute {
        guard let user = currentUser else {
            // First-time user - start at splash
            return .splash
        }
        
        if user.contactsImported {
            // Returning user who completed setup - SplashView will handle Person of the Day and routing
            return .splash
        } else if user.onboardingCompleted {
            // User completed onboarding but hasn't imported contacts
            return .contactImport
        } else {
            // User started but didn't complete onboarding - resume at plan selection
            return .planSelection
        }
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            rootContentView
                .navigationDestination(for: AppRoute.self) { route in
                    destinationView(for: route)
                }
        }
        .onAppear {
            // Update Person of the Day when app opens
            if let user = currentUser {
                PersonOfTheDayManager.updatePersonOfTheDay(for: user, contacts: contacts, in: modelContext)
            }
        }
    }
    
    @ViewBuilder
    private var rootContentView: some View {
        switch rootView {
        case .splash:
            SplashView(navigationPath: $navigationPath)
        case .contactList:
            ContactListView(navigationPath: $navigationPath)
        case .contactImport:
            ContactImportView(navigationPath: $navigationPath)
        case .planSelection:
            PlanSelectionView(navigationPath: $navigationPath)
        default:
            SplashView(navigationPath: $navigationPath)
        }
    }
    
    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .splash:
            SplashView(navigationPath: $navigationPath)
        case .planSelection:
            PlanSelectionView(navigationPath: $navigationPath)
        case .onboarding:
            OnboardingView(navigationPath: $navigationPath)
        case .contactImport:
            ContactImportView(navigationPath: $navigationPath)
        case .contactList:
            ContactListView(navigationPath: $navigationPath)
        case .contactDetail(let contact):
            ContactDetailView(navigationPath: $navigationPath, contact: contact)
        case .support:
            SupportView()
        case .about:
            AboutView()
        case .privacyPolicy:
            PrivacyPolicyView()
        case .termsOfService:
            TermsOfServiceView()
        }
    }
}

#Preview {
    RootView()
}
