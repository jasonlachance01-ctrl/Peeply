//
//  ContactImportView.swift
//  Peeply
//
//  Created by Jason LaChance on 1/18/26.
//

import SwiftUI
import SwiftData
import Contacts
import UserNotifications

struct ContactImportView: View {
    @Binding var navigationPath: NavigationPath
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [PeeplyUser]
    @State private var showPermissionDeniedAlert = false
    @State private var showImportErrorAlert = false
    @State private var showSuccessMessage = false
    @State private var isImporting = false
    @State private var showNotificationPrePromptAlert = false
    
    private let contactStore = CNContactStore()
    
    private var currentUser: PeeplyUser? {
        users.first
    }
    
    private func requestContactsPermission() {
        contactStore.requestAccess(for: .contacts) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    importContacts()
                } else {
                    showPermissionDeniedAlert = true
                }
            }
        }
    }
    
    private func importContacts() {
        isImporting = true
        
        let keys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey,
            CNContactOrganizationNameKey,
            CNContactJobTitleKey,
            CNContactBirthdayKey,
            CNContactPostalAddressesKey,
            CNContactImageDataKey
        ] as [CNKeyDescriptor]
        
        do {
            var allContacts: [CNContact] = []
            
            // Get all container identifiers
            let containers = try contactStore.containers(matching: nil)
            
            // Fetch contacts from each container
            for container in containers {
                let predicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
                let contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: keys)
                allContacts.append(contentsOf: contacts)
            }
            
            // Fetch existing contacts to avoid duplicates (same first + last name)
            let existingDescriptor = FetchDescriptor<Contact>()
            let existingContacts = try modelContext.fetch(existingDescriptor)
            var existingKeys = Set(existingContacts.map { "\($0.firstName)|\($0.lastName ?? "")" })
            
            // Loop through all contacts and create Contact models
            var contactsWithPhotos = 0
            var totalContacts = 0
            var skippedDuplicates = 0
            
            for cnContact in allContacts {
                let firstName = cnContact.givenName
                let lastName = cnContact.familyName
                
                // Only import contacts that have at least a first name
                if !firstName.isEmpty {
                    let duplicateKey = "\(firstName)|\(lastName)"
                    if existingKeys.contains(duplicateKey) {
                        skippedDuplicates += 1
                        continue
                    }
                    existingKeys.insert(duplicateKey)
                    totalContacts += 1
                    
                    // Extract phone numbers
                    let phoneNumbers = cnContact.phoneNumbers.map { $0.value.stringValue }
                    
                    // Extract email addresses
                    let emails = cnContact.emailAddresses.map { $0.value as String }
                    
                    // Extract company
                    let company = cnContact.organizationName.isEmpty ? nil : cnContact.organizationName
                    
                    // Extract job title
                    let jobTitle = cnContact.jobTitle.isEmpty ? nil : cnContact.jobTitle
                    
                    // Extract birthday (convert DateComponents to Date)
                    var birthday: Date? = nil
                    if let birthdayComponents = cnContact.birthday {
                        var components = DateComponents()
                        components.year = birthdayComponents.year
                        components.month = birthdayComponents.month
                        components.day = birthdayComponents.day
                        birthday = Calendar.current.date(from: components)
                    }
                    
                    // Extract and format addresses
                    let addresses = cnContact.postalAddresses.map { labeledValue -> String in
                        let address = labeledValue.value
                        var addressParts: [String] = []
                        
                        if !address.street.isEmpty {
                            addressParts.append(address.street)
                        }
                        if !address.city.isEmpty {
                            addressParts.append(address.city)
                        }
                        if !address.state.isEmpty {
                            addressParts.append(address.state)
                        }
                        if !address.postalCode.isEmpty {
                            addressParts.append(address.postalCode)
                        }
                        if !address.country.isEmpty {
                            addressParts.append(address.country)
                        }
                        
                        return addressParts.joined(separator: ", ")
                    }
                    
                    // Extract photo data
                    let photoData = cnContact.imageData
                    let hasPhoto = photoData != nil
                    let photoSize = photoData?.count ?? 0
                    
                    // Debug: Print photo information
                    let contactName = lastName.isEmpty ? firstName : "\(firstName) \(lastName)"
                    print("Contact \(contactName): has photo = \(hasPhoto), photo size = \(photoSize) bytes")
                    
                    if hasPhoto {
                        contactsWithPhotos += 1
                    }
                    
                    let newContact = Contact(
                        firstName: firstName,
                        lastName: lastName.isEmpty ? nil : lastName,
                        phoneNumbers: phoneNumbers,
                        emails: emails,
                        company: company,
                        jobTitle: jobTitle,
                        notes: nil, // Notes not imported - requires special permissions
                        birthday: birthday,
                        addresses: addresses,
                        photoData: photoData
                    )
                    modelContext.insert(newContact)
                }
            }
            
            // Debug: Print summary
            print("=== Contact Import Summary ===")
            print("Total contacts imported: \(totalContacts)")
            print("Skipped duplicates (same first + last name): \(skippedDuplicates)")
            print("Contacts with photos: \(contactsWithPhotos)")
            print("Contacts without photos: \(totalContacts - contactsWithPhotos)")
            
            // Save all contacts
            try modelContext.save()
            
            // Ensure PeeplyUser exists and mark contacts as imported
            if let user = currentUser {
                user.contactsImported = true
                user.hasContactedPersonOfTheDay = true
                user.personOfTheDayDate = Date()
            } else {
                let newUser = PeeplyUser(email: "", subscriptionTier: .gettingStarted)
                newUser.contactsImported = true
                newUser.hasContactedPersonOfTheDay = true
                newUser.personOfTheDayDate = Date()
                modelContext.insert(newUser)
            }
            try modelContext.save()
            
            isImporting = false
            showSuccessMessage = true
            showNotificationPrePromptAlert = true
        } catch {
            isImporting = false
            showImportErrorAlert = true
            print("Error importing contacts: \(error)")
        }
    }
    
    private func continueToContactList() {
        navigationPath.append(AppRoute.contactList)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if showSuccessMessage {
                successView
            } else {
                importView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.peeplyBackground)
        .ignoresSafeArea()
        .navigationTitle("Contact Import")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Contacts Permission Required", isPresented: $showPermissionDeniedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Peeply needs access to your contacts to help you build stronger relationships. Please enable contacts access in Settings.")
        }
        .alert("Import Error", isPresented: $showImportErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Failed to import contacts. Please try again.")
        }
        .alert("Enable Notifications", isPresented: $showNotificationPrePromptAlert) {
            Button("Continue") {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    if granted {
                        PersonOfTheDayManager.schedulePersonOfTheDayNotification()
                    }
                }
            }
            Button("Skip", role: .cancel) { }
        } message: {
            Text("Peeply selects a Person of the Day for you each morning to help you stay consistent in your connections. Tap Continue to enable your notifications and never miss a Person of the Day!")
        }
    }
    
    private var importView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Headline
            Text("Onboarding complete! Now let's import your contacts so Peeply can begin to help you build strong relationships!")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            
            // Import Contacts button
            Button(action: requestContactsPermission) {
                if isImporting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                } else {
                    Text("Import Contacts")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isImporting)
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
    
    private var successView: some View {
        ZStack {
            Color.peeplyBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Success confirmation message
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.peeplyRose, Color.peeplyLavender],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Your contacts successfully uploaded to Peeply!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.peeplyCharcoal)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 40)
                .padding(.bottom, 32)
                
                // Feature cards - swipeable
                VStack(spacing: 16) {
                    Text("What Peeply Does")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.peeplyCharcoal)
                        .padding(.bottom, 8)
                    
                    TabView {
                        featureCard(
                            icon: "calendar",
                            title: "Last One-to-One",
                            description: "Track your last meaningful conversation"
                        )
                        featureCard(
                            icon: "person.badge.plus",
                            title: "Quick Entry",
                            description: "Add contacts in seconds with name and number"
                        )
                        featureCard(
                            icon: "star.fill",
                            title: "Person of the Day",
                            description: "Discover who to connect with today"
                        )
                        featureCard(
                            icon: "shuffle",
                            title: "Randomizer",
                            description: "Shake for 5 connection suggestions"
                        )
                        featureCard(
                            icon: "flame.fill",
                            title: "Streaks",
                            description: "Stay consistent! Update daily to keep your streak alive"
                        )
                    }
                    .tabViewStyle(.page)
                    .frame(height: 200)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Continue button
                Button(action: continueToContactList) {
                    Text("Go to your Contacts and Start using Peeply!")
                        .font(.headline)
                        .foregroundStyle(Color.peeplyWhite)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.peeplyCharcoal)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }
    
    @ViewBuilder
    private func featureCard(icon: String, title: String, description: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.peeplyRose, Color.peeplyLavender],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.peeplyCharcoal)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(Color.peeplyCharcoal.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color.peeplyCream, Color.peeplyRose.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 8)
    }
}

#Preview {
    NavigationStack {
        ContactImportView(navigationPath: .constant(NavigationPath()))
    }
}
