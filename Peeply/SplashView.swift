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
            
            // Circular face arrangement
            ZStack {
                // Outer circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.peeplyRose.opacity(0.3), Color.peeplyLavender.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 280, height: 280)
                
                // Diverse face placeholders arranged in a circle
                ForEach(0..<10, id: \.self) { index in
                    let angle = Double(index) * 2 * .pi / 10
                    let radius: CGFloat = 110
                    let x = cos(angle) * radius
                    let y = sin(angle) * radius
                    
                    // Vary face styles for diversity
                    let faceData = faceVariations[index % faceVariations.count]
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: faceData.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: faceData.size, height: faceData.size)
                        .overlay(
                            Image(systemName: faceData.icon)
                                .font(.system(size: faceData.iconSize))
                                .foregroundStyle(Color.peeplyWhite)
                        )
                        .offset(x: x, y: y)
                }
            }
            .padding(.bottom, 48)
            
            Spacer()
            
            // Get Started button
            Button(action: {
                navigationPath.append(AppRoute.planSelection)
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundStyle(Color.peeplyWhite)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.peeplyCharcoal)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
    
    // Diverse face variations for different ages and styles
    private var faceVariations: [(icon: String, size: CGFloat, iconSize: CGFloat, gradient: [Color])] {
        [
            // 20s-30s variations
            (icon: "person.fill", size: 48, iconSize: 22, gradient: [Color.peeplyRose, Color.peeplyLavender]),
            (icon: "person.circle.fill", size: 52, iconSize: 24, gradient: [Color.peeplyLavender, Color.peeplyRose]),
            (icon: "person.2.fill", size: 50, iconSize: 23, gradient: [Color.peeplyRose.opacity(0.9), Color.peeplyLavender.opacity(0.9)]),
            (icon: "person.fill", size: 49, iconSize: 22, gradient: [Color.peeplyLavender.opacity(0.8), Color.peeplyRose.opacity(0.8)]),
            
            // 30s-40s variations
            (icon: "person.crop.circle.fill", size: 51, iconSize: 24, gradient: [Color.peeplyRose, Color.peeplyLavender]),
            (icon: "person.fill", size: 48, iconSize: 22, gradient: [Color.peeplyLavender, Color.peeplyRose]),
            
            // 40s-50s variations
            (icon: "person.circle.fill", size: 50, iconSize: 23, gradient: [Color.peeplyRose.opacity(0.85), Color.peeplyLavender.opacity(0.85)]),
            (icon: "person.fill", size: 49, iconSize: 22, gradient: [Color.peeplyLavender.opacity(0.9), Color.peeplyRose.opacity(0.9)]),
            
            // 50s-60s variations
            (icon: "person.crop.circle.fill", size: 52, iconSize: 24, gradient: [Color.peeplyRose, Color.peeplyLavender]),
            (icon: "person.fill", size: 48, iconSize: 22, gradient: [Color.peeplyLavender, Color.peeplyRose])
        ]
    }
}

#Preview {
    NavigationStack {
        SplashView(navigationPath: .constant(NavigationPath()))
    }
}
