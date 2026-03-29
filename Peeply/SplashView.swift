//
//  SplashView.swift
//  Peeply
//
//  Created by Jason LaChance on 1/18/26.
//

import SwiftUI
import SwiftData

struct SplashView: View {
    @Binding var navigationPath: NavigationPath
    @Query private var users: [PeeplyUser]
    @Query private var contacts: [Contact]
    @Environment(\.modelContext) private var modelContext
    @State private var showPersonOfTheDay = false
    @State private var personOfTheDayContact: Contact?
    @State private var didRouteReturningUser = false
    
    private var currentUser: PeeplyUser? {
        users.first
    }
    
    private var isReturningUser: Bool {
        currentUser?.contactsImported == true
    }
    
    private func runReturningUserRouting() {
        if currentUser == nil { return }
        if currentUser?.contactsImported == true {
            if isReturningUser {
                // Update Person of the Day
                if let user = currentUser {
                    PersonOfTheDayManager.updatePersonOfTheDay(for: user, contacts: contacts, in: modelContext)
                    
                    // If the user already handled Person of the Day today, go straight to contact list
                    if user.hasContactedPersonOfTheDay {
                        guard !didRouteReturningUser else { return }
                        didRouteReturningUser = true
                        navigationPath.append(AppRoute.contactList)
                        return
                    }
                    
                    // Otherwise, find and show Person of the Day
                    if let contactId = user.personOfTheDayContactId,
                       let contact = contacts.first(where: { $0.id == contactId }) {
                        personOfTheDayContact = contact
                        showPersonOfTheDay = true
                    }
                }
            }
        } else if currentUser?.onboardingCompleted == true {
            navigationPath.append(AppRoute.planSelection)
        } else if currentUser?.onboardingCompleted == false && currentUser?.contactsImported == false {
            navigationPath = NavigationPath()
            navigationPath.append(AppRoute.onboarding)
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
            runReturningUserRouting()
        }
        .onChange(of: users) { _, _ in
            runReturningUserRouting()
        }
        .sheet(isPresented: $showPersonOfTheDay) {
            if let contact = personOfTheDayContact {
                PersonOfTheDayView(contact: contact) {
                    showPersonOfTheDay = false
                    
                    // Mark as contacted/dismissed for today and persist
                    if let user = currentUser {
                        user.hasContactedPersonOfTheDay = true
                        try? modelContext.save()
                    }
                    
                    // Navigate to ContactListView after dismissal
                    navigationPath.append(AppRoute.contactList)
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
