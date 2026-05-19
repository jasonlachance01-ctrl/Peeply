//
//  SplashView.swift
//  Peeply
//
//  Created by Jason LaChance on 1/18/26.
//

import SwiftUI
import SwiftData
import RevenueCat

struct SplashView: View {
    @Binding var navigationPath: NavigationPath
    @Query private var users: [PeeplyUser]
    @Query private var contacts: [Contact]
    @Environment(\.modelContext) private var modelContext
    @State private var showPersonOfTheDay = false //Is the sheet currently being presented
    @State private var personOfTheDayContact: Contact?
    @State private var didRouteReturningUser = false
    //@State private var hasCompletedInitialRouting = false
    @State private var didInitialRoute = false //same as hasCompletedInitialRouting
    @State private var didPresentPersonOfTheDay = false //Has this sheet already been presented
    @State private var didRunDisplaySortKeyMigration = false //Has the one-time displaySortKey backfill been run this launch

    private var currentUser: PeeplyUser? {
        users.first
    }

    private var isReturningUser: Bool {
        currentUser?.contactsImported == true
    }

    private func routeToContactListIfNeeded() {
        guard !didRouteReturningUser else { return }
        didRouteReturningUser = true
        didInitialRoute = true
        navigationPath.append(AppRoute.contactList)
    }

    private func handlePersonOfTheDayDismiss() {
        guard didPresentPersonOfTheDay else { return }

        if let user = currentUser, !user.hasContactedPersonOfTheDay {
            user.hasContactedPersonOfTheDay = true
            try? modelContext.save()
        }

        showPersonOfTheDay = false
        routeToContactListIfNeeded()
    }

    private func runDisplaySortKeyMigrationIfNeeded() {
        guard !didRunDisplaySortKeyMigration else { return }
        didRunDisplaySortKeyMigration = true
        ContactSortKeyMigration.backfillDisplaySortKeysIfNeeded(in: modelContext)
    }

    private func runReturningUserRouting() {
        // Must have a user or we can't route
        guard let user = currentUser else {
            return
        }
        // Once Splash has made its startup decision, later changes to users or contacts stop re-running routing logic
        // This prevents splash from behaving like a long-lived global router after launch
        guard !didInitialRoute else { return }

        // Ensure older contacts have a persisted displaySortKey before routing depends on contact ordering.
        // This is a one-time backfill for records created before displaySortKey existed.
        runDisplaySortKeyMigrationIfNeeded()

        // Case 1: User has imported contacts - returning user path
        if user.contactsImported {
            // Update Person of the Day
            PersonOfTheDayManager.updatePersonOfTheDay(for: user, contacts: contacts, in: modelContext)
            // If the user already handled Person of the Day today, go straight to contact list
            if user.hasContactedPersonOfTheDay {
                routeToContactListIfNeeded()
                return
            }
            // Otherwise, try to show Person of the Day
            if !didPresentPersonOfTheDay,
               let contactId = user.personOfTheDayContactId,
               let contact = contacts.first(where: { $0.id == contactId }) {
                personOfTheDayContact = contact
                didPresentPersonOfTheDay = true
                showPersonOfTheDay = true
                return
            }
            // If we did not show Person of the Day for any reason, go to contact list once
            routeToContactListIfNeeded()
            return
        }

        // From here on, user.contactsImported == false
        // Case 2: User finished onboarding but didn't import contacts yet
        if user.onboardingCompleted {
            didInitialRoute = true
            navigationPath = NavigationPath()
            Task {
                do {
                    let customerInfo = try await Purchases.shared.customerInfo()
                    let peeplyProActive = customerInfo.entitlements["Peeply Pro"]?.isActive == true

                    await MainActor.run {
                        // Re-read user on the main actor in case it changed
                        guard let latestUser = currentUser else {
                            navigationPath.append(AppRoute.planSelection)
                            return
                        }
                        // If onboarding is complete and contacts are still not imported
                        guard latestUser.onboardingCompleted, latestUser.contactsImported ==
                                false else {
                            navigationPath.append(AppRoute.planSelection)
                            return
                        }

                        if peeplyProActive {
                            navigationPath.append(AppRoute.contactImport)
                        } else {
                            navigationPath.append(AppRoute.planSelection)
                        }
                    }
                } catch {
                    await MainActor.run {
                        navigationPath.append(AppRoute.planSelection)
                    }
                }
            }
            return
        }
        // Case 3: User has NOT completed onboarding and has NOT imported contacts
        if user.onboardingCompleted == false && user.contactsImported == false {
            didInitialRoute = true
            navigationPath = NavigationPath()
            navigationPath.append(AppRoute.onboarding)
            return
        }
    }

    var body: some View {
        ZStack {
            // Background
            Color.peeplyBackground
                .ignoresSafeArea()

            if isReturningUser {
                // Returning user view
                returningUserView
            } else {
                // First-time user view
                firstTimeUserView
            }
        }
        .onAppear {
            guard !didInitialRoute else { return }
            didRouteReturningUser = false
            didInitialRoute = false
            didPresentPersonOfTheDay = false
            didRunDisplaySortKeyMigration = false
            runReturningUserRouting()
        }
        .onChange(of: users) { _, _ in
            guard !didInitialRoute else { return }
            runReturningUserRouting()
        }
        .onChange(of: contacts) { _, _ in
            guard !didInitialRoute else { return }
            //guard !didRouteReturningUser else { return }
            runReturningUserRouting()
        }
        .sheet(isPresented: $showPersonOfTheDay, onDismiss: {
            handlePersonOfTheDayDismiss()
        }) {
            if let contact = personOfTheDayContact {
                PersonOfTheDayView(contact: contact) {
                    showPersonOfTheDay = false
                }
            }
        }
    }

    private var returningUserView: some View {
        VStack(spacing: 0) {
            Spacer()

            // Headline
            VStack(spacing: 16) {
                Text("Welcome to Peeply!")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(Color.peeplyCharcoal)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)

                Text("Your Personal Relationship Command Center!")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.peeplyCharcoal.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)

            // Person of the Day will be shown in sheet
            Spacer()
        }
    }

    private var firstTimeUserView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    Text("Welcome to Peeply!")
                        .font(.system(size: 36, weight: .bold, design: .default))
                        .foregroundStyle(Color.peeplyWhite)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

                    Text("Your Personal Relationship Command Center!")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.peeplyWhite.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

                    Text("Peeply is a micro-CRM that brings your contacts list to life and helps you focus on developing stronger personal relationships.")
                        .font(.subheadline)
                        .foregroundStyle(Color.peeplyWhite.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 48)

                Button(action: {
                    navigationPath.append(AppRoute.onboarding)
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundStyle(Color.peeplyCharcoal)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.peeplyWhite)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
        }
        .background {
            ZStack {
                Image("SplashBackground")
                    .resizable()
                    .aspectRatio(contentMode: .fill)

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.1),
                        Color.black.opacity(0.3),
                        Color.black.opacity(0.55)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    NavigationStack {
        SplashView(navigationPath: .constant(NavigationPath()))
    }
}
