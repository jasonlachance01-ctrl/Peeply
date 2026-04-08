//
//  ContactListView.swift
//  Peeply
//
//  Created by Jason LaChance on 1/18/26.
//

import SwiftUI
import SwiftData
import UIKit

struct ContactListView: View {
    @Binding var navigationPath: NavigationPath
    @Query private var contacts: [Contact]
    @Query private var users: [PeeplyUser]
    @Environment(\.modelContext) private var modelContext
    @State private var selectedContact: Contact?
    @State private var showDatePicker = false
    @State private var selectedDate = Date()
    @State private var showRandomizer = false
    @State private var randomContacts: [Contact] = []
    @State private var hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
    @State private var showStreakDetails = false
    @State private var showStreakCelebration = false
    @State private var showSearch = false
    @State private var searchText = ""
    @FocusState private var isSearchFieldFocused: Bool
    @State private var showSupport = false
    @State private var showNewContactsSheet = false
    @State private var contactToOpenAfterSheetDismiss: Contact?
    
    private var sortedContacts: [Contact] {
        // Debug: Check for duplicates before sorting
        let uniqueContactIds = Set(contacts.map { $0.id })
        print("DEBUG: Total contacts from @Query: \(contacts.count)")
        print("DEBUG: Unique contact IDs: \(uniqueContactIds.count)")
        
        if contacts.count != uniqueContactIds.count {
            print("WARNING: Duplicate contacts detected in database!")
            // Remove duplicates by keeping first occurrence of each ID
            var seenIds = Set<UUID>()
            let deduplicated = contacts.filter { contact in
                if seenIds.contains(contact.id) {
                    print("DEBUG: Found duplicate contact: \(contact.firstName) \(contact.lastName ?? "") (ID: \(contact.id))")
                    return false
                } else {
                    seenIds.insert(contact.id)
                    return true
                }
            }
            
            return deduplicated.sorted { contact1, contact2 in
                let lastName1 = contact1.lastName?.lowercased().isEmpty == false ? contact1.lastName!.lowercased() : contact1.firstName.lowercased()
                let lastName2 = contact2.lastName?.lowercased().isEmpty == false ? contact2.lastName!.lowercased() : contact2.firstName.lowercased()
                let firstName1 = contact1.firstName.lowercased()
                let firstName2 = contact2.firstName.lowercased()
                
                // Sort by lastName first, then firstName
                if lastName1 != lastName2 {
                    return lastName1 < lastName2
                } else {
                    return firstName1 < firstName2
                }
            }
        }
        
        // Normal sorting if no duplicates
        return contacts.sorted { contact1, contact2 in
            let lastName1 = contact1.lastName?.lowercased().isEmpty == false ? contact1.lastName!.lowercased() : contact1.firstName.lowercased()
            let lastName2 = contact2.lastName?.lowercased().isEmpty == false ? contact2.lastName!.lowercased() : contact2.firstName.lowercased()
            let firstName1 = contact1.firstName.lowercased()
            let firstName2 = contact2.firstName.lowercased()
            
            // Sort by lastName first, then firstName
            if lastName1 != lastName2 {
                return lastName1 < lastName2
            } else {
                return firstName1 < firstName2
            }
        }
    }
    
    private var filteredContacts: [Contact] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return sortedContacts }
        return sortedContacts.filter { contact in
            contact.firstName.lowercased().contains(query)
                || (contact.lastName?.lowercased() ?? "").contains(query)
        }
    }
    
    private func fullName(for contact: Contact) -> String {
        if let lastName = contact.lastName, !lastName.isEmpty {
            return "\(contact.firstName) \(lastName)"
        } else {
            return contact.firstName
        }
    }
    
    private func formattedDateString(for contact: Contact) -> String {
        if let date = contact.lastOneToOne {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = .none
            return formatter.string(from: date)
        } else {
            return "Not set"
        }
    }

    private func formatPhoneNumber(_ phone: String) -> String {
        let digits = phone.filter(\.isNumber)

        if digits.count == 10 {
            let area = digits.prefix(3)
            let mid = digits.dropFirst(3).prefix(3)
            let last = digits.suffix(4)
            return "(\(area)) \(mid)-\(last)"
        }

        if digits.count == 11, digits.first == "1" {
            let rest = String(digits.dropFirst())
            let area = rest.prefix(3)
            let mid = rest.dropFirst(3).prefix(3)
            let last = rest.suffix(4)
            return "+1 (\(area)) \(mid)-\(last)"
        }

        return phone
    }
    
    private func initials(for contact: Contact) -> String {
        let firstInitial = contact.firstName.prefix(1).uppercased()
        let lastInitial = contact.lastName?.prefix(1).uppercased() ?? ""
        return "\(firstInitial)\(lastInitial)"
    }
    
    private func contactPhoto(for contact: Contact) -> UIImage? {
        guard let photoData = contact.photoData else { return nil }
        return UIImage(data: photoData)
    }
    
    private func openDatePicker(for contact: Contact) {
        selectedContact = contact
        selectedDate = contact.lastOneToOne ?? Date()
        showDatePicker = true
    }
    
    private var currentUser: PeeplyUser? {
        users.first
    }
    
    private var newContactsThisMonth: Int {
        contactsCreatedThisMonth.count
    }
    
    private var contactsCreatedThisMonth: [Contact] {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        
        return sortedContacts.filter { contact in
            guard let createdAt = contact.createdAt else { return false }
            return createdAt >= startOfMonth
        }
    }
    
    private func saveDate() {
        guard let contact = selectedContact else { return }
        
        let wasToday = StreakManager.isToday(selectedDate)
        contact.lastOneToOne = selectedDate
        try? modelContext.save()
        
        // Update streak if date is today
        if wasToday, let user = currentUser {
            let streakContinued = StreakManager.updateStreak(for: user, in: modelContext)
            if streakContinued {
                // Show celebration
                showStreakCelebration = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showStreakCelebration = false
                }
            }
        }
        
        showDatePicker = false
        selectedContact = nil
    }
    
    private func selectRandomContacts() {
        let availableContacts = sortedContacts
        let count = min(5, availableContacts.count)
        
        if count == 0 {
            return
        }
        
        // Select random contacts
        var selected: [Contact] = []
        var indices = Set<Int>()
        
        while selected.count < count && indices.count < availableContacts.count {
            let randomIndex = Int.random(in: 0..<availableContacts.count)
            if !indices.contains(randomIndex) {
                indices.insert(randomIndex)
                selected.append(availableContacts[randomIndex])
            }
        }
        
        // Update contacts first
        randomContacts = selected
        
        // Trigger haptic feedback
        hapticGenerator.prepare()
        hapticGenerator.impactOccurred()
        
        // Show sheet - use DispatchQueue to ensure state update completes first
        // This ensures randomContacts is set before the sheet is created
        DispatchQueue.main.async {
            // Double-check contacts are populated before showing
            if !randomContacts.isEmpty {
                showRandomizer = true
            }
        }
    }
    
    private func openContactDetail(_ contact: Contact) {
        showRandomizer = false
        navigationPath.append(AppRoute.contactDetail(contact))
    }
    
    private func addNewContact() {
        let newContact = Contact(firstName: "New Contact")
        modelContext.insert(newContact)
        try? modelContext.save()
        navigationPath.append(AppRoute.contactDetail(newContact))
    }
    
    @ViewBuilder
    private func streakCard(user: PeeplyUser?) -> some View {
        Button(action: {
            showStreakDetails = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Top row with icon and arrow
                HStack {
                    // Icon square
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.peeplyCream)
                        .frame(width: 52, height: 52)
                        .overlay(
                            Text("🔥")
                                .font(.system(size: 24))
                        )
                    
                    Spacer()
                    
                    // Arrow icon
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.peeplyCharcoal.opacity(0.5))
                }
                
                // Number
                if let user = user, user.currentStreak > 0 {
                    Text("\(user.currentStreak)")
                        .font(.system(size: 20, weight: .bold, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                } else {
                    Text("0")
                        .font(.system(size: 20, weight: .bold, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                }
                
                // Descriptive text
                Text("Daily one-to-one Streak")
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundStyle(Color.peeplyCharcoal.opacity(0.6))
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color.peeplyWhite)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
    
    private var growthTrackingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row with icon and arrow
            HStack {
                // Icon square
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.peeplyCream)
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: "arrow.up")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(Color.peeplyCharcoal)
                    )
                
                Spacer()
                
                // Arrow icon
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.peeplyCharcoal.opacity(0.5))
            }
            
            // Number
            Text("\(newContactsThisMonth)")
                .font(.system(size: 20, weight: .bold, design: .default))
                .foregroundStyle(Color.peeplyCharcoal)
            
            // Descriptive text
            Text("New Contacts Added this Month")
                .font(.system(size: 12, weight: .regular, design: .default))
                .foregroundStyle(Color.peeplyCharcoal.opacity(0.6))
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.peeplyWhite)
        .cornerRadius(20)
    }
    
    private var celebrationView: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text("🔥")
                    .font(.system(size: 60))
                    .scaleEffect(showStreakCelebration ? 1.3 : 1.0)
                
                if let user = currentUser {
                    Text("\(user.currentStreak) Day Streak!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.peeplyCharcoal)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.peeplyWhite)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .padding(.horizontal, 40)
            .scaleEffect(showStreakCelebration ? 1.0 : 0.8)
            .opacity(showStreakCelebration ? 1.0 : 0.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showStreakCelebration)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom navigation bar
            HStack {
                Spacer()
                
                // Title
                Text("Contacts")
                    .font(.system(size: 20, weight: .medium, design: .default))
                    .foregroundStyle(Color.peeplyCharcoal)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.peeplyWhite)
            
            // Search bar (shown when Search tab or nav icon is tapped)
            if showSearch {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.peeplyCharcoal.opacity(0.6))
                    TextField("Search contacts", text: $searchText)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color.peeplyCharcoal)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($isSearchFieldFocused)
                        .overlay(alignment: .trailing) {
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(Color.peeplyCharcoal.opacity(0.6))
                                }
                                .padding(.trailing, 4)
                            }
                        }
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                }
                            }
                        }
                }
                .padding(12)
                .background(Color.peeplyBackground)
                .padding(.horizontal, 16)
                .onAppear { isSearchFieldFocused = true }
            }
            
            // Content
            ScrollView {
                VStack(spacing: 12) {
                    // Streak and Growth cards side-by-side
                    HStack(spacing: 12) {
                        streakCard(user: currentUser)
                        Button(action: { showNewContactsSheet = true }) {
                            growthTrackingCard
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    
                    // Contact list
                    ForEach(filteredContacts, id: \.id) { contact in
                        HStack(spacing: 20) {
                            // Contact photo or initials
                            if let photo = contactPhoto(for: contact) {
                                Image(uiImage: photo)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 52, height: 52)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 232/255, green: 180/255, blue: 184/255), // #E8B4B8 deeper rose/pink
                                                Color.peeplyCream // #F5E6C8 cream
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 52, height: 52)
                                    .overlay(
                                        Text(initials(for: contact))
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(Color.peeplyWhite)
                                    )
                            }
                            
                            // Contact info
                            VStack(alignment: .leading, spacing: 4) {
                                Button(action: {
                                    navigationPath.append(AppRoute.contactDetail(contact))
                                }) {
                                    Text(fullName(for: contact))
                                        .font(.system(size: 16, weight: .medium, design: .default))
                                        .foregroundStyle(Color.peeplyCharcoal)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: {
                                    openDatePicker(for: contact)
                                }) {
                                    Text("Last one-to-one: \(formattedDateString(for: contact))")
                                        .font(.system(size: 12, weight: .regular, design: .default))
                                        .foregroundStyle(Color.peeplyCharcoal.opacity(0.7))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            // Chevron
                            Button(action: {
                                navigationPath.append(AppRoute.contactDetail(contact))
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.peeplyCharcoal.opacity(0.5))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(12)
                        .background(Color.peeplyWhite)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 0)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)
                    }
                }
            }
            .background(Color.peeplyBackground)
        }
        .navigationBarHidden(true)
        .safeAreaInset(edge: .bottom) {
            // Bottom tab bar
            HStack(spacing: 0) {
                // Search - left
                Button(action: {
                    showSearch = true
                    isSearchFieldFocused = true
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 22, weight: .regular))
                        Text("Search")
                            .font(.system(size: 14, weight: .regular, design: .default))
                    }
                    .foregroundStyle(Color.peeplyCharcoal)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                
                // Add - center
                Button(action: addNewContact) {
                    VStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                        Text("Add")
                            .font(.system(size: 14, weight: .regular, design: .default))
                    }
                    .foregroundStyle(Color.peeplyCharcoal)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                
                // Support - right
                Button(action: {
                    showSupport = true
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "headphones")
                            .font(.system(size: 22, weight: .regular))
                        Text("Support")
                            .font(.system(size: 14, weight: .regular, design: .default))
                    }
                    .foregroundStyle(Color.peeplyCharcoal)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 30)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .overlay {
            // Celebration overlay
            if showStreakCelebration {
                celebrationView
            }
        }
        .alert("Connection Streak", isPresented: $showStreakDetails) {
            Button("OK", role: .cancel) { }
        } message: {
            if let user = currentUser, user.currentStreak > 0 {
                Text("You've had a meaningful connection \(user.currentStreak) days in a row. Keep it going!")
            } else {
                Text("Start a new streak today!")
            }
        }
        .onAppear {
            hapticGenerator.prepare()
        }
        .onShake {
            selectRandomContacts()
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(
                selectedDate: $selectedDate,
                onSave: saveDate,
                onCancel: {
                    showDatePicker = false
                    selectedContact = nil
                }
            )
        }
        .sheet(isPresented: $showRandomizer) {
            ContactRandomizerSheet(
                contacts: $randomContacts,
                onContactTap: openContactDetail,
                onShake: selectRandomContacts,
                onClose: {
                    showRandomizer = false
                }
            )
        }
        .sheet(isPresented: $showSupport) {
            SupportView()
        }
        .sheet(isPresented: $showNewContactsSheet, onDismiss: {
            if let c = contactToOpenAfterSheetDismiss {
                navigationPath.append(AppRoute.contactDetail(c))
                contactToOpenAfterSheetDismiss = nil
            }
        }) {
            NavigationStack {
                List(contactsCreatedThisMonth, id: \.id) { contact in
                    Button(action: {
                        contactToOpenAfterSheetDismiss = contact
                        showNewContactsSheet = false
                    }) {
                        Text(fullName(for: contact))
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .foregroundStyle(Color.peeplyCharcoal)
                    }
                }
                .navigationTitle("New Contacts This Month")
                .navigationBarTitleDisplayMode(.inline)
                .scrollContentBackground(.hidden)
                .background(Color.peeplyBackground)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showNewContactsSheet = false
                        }
                        .fontWeight(.medium)
                        .foregroundStyle(Color.peeplyCharcoal)
                    }
                }
            }
        }
    }
}

// Shake gesture detection
struct ShakeDetector: UIViewControllerRepresentable {
    let onShake: () -> Void
    
    func makeUIViewController(context: Context) -> ShakeViewController {
        let controller = ShakeViewController()
        controller.onShake = onShake
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ShakeViewController, context: Context) {
        uiViewController.onShake = onShake
    }
}

class ShakeViewController: UIViewController {
    var onShake: (() -> Void)?
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            onShake?()
        }
    }
}

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.background(ShakeDetector(onShake: action))
    }
}

struct ContactRandomizerSheet: View {
    @Binding var contacts: [Contact]
    let onContactTap: (Contact) -> Void
    let onShake: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Headline
                VStack(spacing: 16) {
                    Text("You have activated the Peeply Randomizer! Here are the lucky people who get to hear from you today!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.peeplyPink)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 32)
                .padding(.bottom, 24)
                
                // Contact list
                if contacts.isEmpty {
                    Spacer()
                    Text("No contacts available")
                        .foregroundStyle(.secondary)
                    Spacer()
                } else {
                    List(contacts, id: \.id) { contact in
                        Button(action: {
                            onContactTap(contact)
                        }) {
                            HStack(spacing: 12) {
                                // Contact photo or initials
                                if let photo = contactPhoto(for: contact) {
                                    Image(uiImage: photo)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.peeplyRose, Color.peeplyLavender],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Text(initials(for: contact))
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundStyle(Color.peeplyWhite)
                                        )
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(fullName(for: contact))
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    
                                    if let company = contact.company, !company.isEmpty {
                                        Text(company)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Text("📸 Take a screenshot! Once you close or navigate away from this unique Randomizer list you will not be able to return to it.")
                    .font(.caption)
                    .foregroundStyle(Color.peeplyCharcoal.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }
            .navigationTitle("Contact Randomizer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close", action: onClose)
                        .fontWeight(.semibold)
                }
            }
            .onShake {
                onShake()
            }
        }
    }
    
    private func fullName(for contact: Contact) -> String {
        if let lastName = contact.lastName, !lastName.isEmpty {
            return "\(contact.firstName) \(lastName)"
        } else {
            return contact.firstName
        }
    }
    
    private func initials(for contact: Contact) -> String {
        let firstInitial = contact.firstName.prefix(1).uppercased()
        let lastInitial = contact.lastName?.prefix(1).uppercased() ?? ""
        return "\(firstInitial)\(lastInitial)"
    }
    
    private func contactPhoto(for contact: Contact) -> UIImage? {
        guard let photoData = contact.photoData else { return nil }
        return UIImage(data: photoData)
    }
}

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    let onSave: () -> Void
    let onCancel: () -> Void
    @State private var hapticGenerator = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()
                .onChange(of: selectedDate) { _, _ in
                    hapticGenerator.prepare()
                    hapticGenerator.impactOccurred()
                }
                .onAppear {
                    hapticGenerator.prepare()
                }
                
                Spacer()
            }
            .navigationTitle("Last One-to-One")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    NavigationStack {
        ContactListView(navigationPath: .constant(NavigationPath()))
            .modelContainer(for: Contact.self, inMemory: true)
    }
}
