//
//  ContactDetailView.swift
//  Peeply
//
//  Created by Jason LaChance on 1/18/26.
//

import SwiftUI
import SwiftData
import UIKit
import MapKit
import CoreLocation

// Helper struct for stable ForEach identification
private struct IndexedItem: Identifiable {
    let id: String
    let index: Int
    let value: String
}


struct ContactDetailView: View {
    @Binding var navigationPath: NavigationPath
    let contact: Contact
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query private var users: [PeeplyUser]
    @State private var showDatePicker = false
    @State private var selectedDate = Date()
    @State private var showSocialMediaInput = false
    @State private var selectedPlatform = ""
    @State private var socialMediaInput = ""
    @State private var showEditSheet = false
    @State private var showStreakCelebration = false
    
    // Cache arrays to prevent re-observation issues
    // These computed properties ensure we only observe the arrays once per view evaluation
    private var phoneNumbers: [String] {
        contact.phoneNumbers
    }
    
    private var emails: [String] {
        contact.emails
    }
    
    private var addresses: [String] {
        contact.addresses
    }
    
    // Create indexed items with stable IDs for ForEach
    // Uses contact ID + index + value hash to ensure uniqueness and stability
    private func indexedItems(from array: [String]) -> [IndexedItem] {
        array.enumerated().map { index, value in
            IndexedItem(
                id: "\(contact.id.uuidString)-\(index)-\(value.hashValue)",
                index: index,
                value: value
            )
        }
    }
    
    private var fullName: String {
        if let lastName = contact.lastName, !lastName.isEmpty {
            return "\(contact.firstName) \(lastName)"
        } else {
            return contact.firstName
        }
    }
    
    private var initials: String {
        let firstInitial = contact.firstName.prefix(1).uppercased()
        let lastInitial = contact.lastName?.prefix(1).uppercased() ?? ""
        return "\(firstInitial)\(lastInitial)"
    }
    
    private var contactPhoto: UIImage? {
        guard let photoData = contact.photoData else { return nil }
        return UIImage(data: photoData)
    }
    
    private func formattedDateString() -> String {
        if let date = contact.lastOneToOne {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = .none
            return formatter.string(from: date)
        } else {
            return "Not set"
        }
    }
    
    private func formattedBirthdayString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func openDatePicker() {
        selectedDate = contact.lastOneToOne ?? Date()
        showDatePicker = true
    }
    
    private var currentUser: PeeplyUser? {
        users.first
    }
    
    private func saveDate() {
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
    }
    
    private func phoneLabel(for index: Int) -> String {
        let labels = ["mobile", "home", "work"]
        return labels[index % labels.count]
    }
    
    private func cleanPhoneNumber(_ phoneNumber: String) -> String {
        // Remove all characters except digits and + sign
        // This preserves country codes (e.g., +1 for US) while removing formatting
        return phoneNumber.replacingOccurrences(
            of: "[^0-9+]",
            with: "",
            options: .regularExpression
        )
    }
    
    private func callPhone(_ phoneNumber: String) {
        let cleaned = cleanPhoneNumber(phoneNumber)
        if let url = URL(string: "tel://\(cleaned)") {
            openURL(url)
        }
    }
    
    private func sendMessage(_ phoneNumber: String) {
        let cleaned = cleanPhoneNumber(phoneNumber)
        
        // Debug: Print the original and cleaned phone numbers, and the URL
        print("DEBUG sendMessage:")
        print("  Original: \(phoneNumber)")
        print("  Cleaned: \(cleaned)")
        
        // Construct the SMS URL
        // Format: sms:+15555551212 or sms:5555551212
        // Note: The + sign should work without encoding in sms: URLs, but we'll try both approaches
        let smsURLString = "sms:\(cleaned)"
        print("  SMS URL (before encoding): \(smsURLString)")
        
        // Try creating URL directly first (works for most cases)
        if let url = URL(string: smsURLString) {
            print("  Opening URL: \(url.absoluteString)")
            openURL(url)
        } else {
            // If direct creation fails, try URL encoding
            if let encoded = cleaned.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let url = URL(string: "sms:\(encoded)") {
                print("  Opening URL (encoded): \(url.absoluteString)")
                openURL(url)
            } else {
                print("  ERROR: Failed to create URL from string: \(smsURLString)")
            }
        }
    }
    
    private func sendEmail(_ email: String) {
        // Construct the mailto URL
        // Format: mailto:user@example.com
        let mailtoURLString = "mailto:\(email)"
        
        if let url = URL(string: mailtoURLString) {
            openURL(url)
        }
    }
    
    private func startFaceTimeAudio(_ phoneNumber: String) {
        let cleaned = cleanPhoneNumber(phoneNumber)
        let facetimeURLString = "facetime-audio://\(cleaned)"
        
        if let url = URL(string: facetimeURLString) {
            openURL(url)
        }
    }
    
    private func startFaceTimeVideo(_ phoneNumber: String) {
        let cleaned = cleanPhoneNumber(phoneNumber)
        let facetimeURLString = "facetime://\(cleaned)"
        
        if let url = URL(string: facetimeURLString) {
            openURL(url)
        }
    }
    
    private func openMaps(with address: String) {
        // URL-encode the address for use in the Apple Maps URL
        guard let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("ERROR: Failed to encode address: \(address)")
            return
        }
        
        // Construct the Apple Maps URL
        // Format: http://maps.apple.com/?address=[encoded address]
        let mapsURLString = "http://maps.apple.com/?address=\(encodedAddress)"
        
        if let url = URL(string: mapsURLString) {
            openURL(url)
        } else {
            print("ERROR: Failed to create URL from string: \(mapsURLString)")
        }
    }
    
    private func openSocialMediaInput(for platform: String) {
        selectedPlatform = platform
        socialMediaInput = contact.socialMediaLinks[platform] ?? ""
        showSocialMediaInput = true
    }
    
    private func saveSocialMediaLink() {
        guard !socialMediaInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        // Normalize the input - if it doesn't start with http:// or https://, add https://
        var link = socialMediaInput.trimmingCharacters(in: .whitespaces)
        if !link.hasPrefix("http://") && !link.hasPrefix("https://") {
            link = "https://\(link)"
        }
        
        contact.socialMediaLinks[selectedPlatform] = link
        try? modelContext.save()
        
        showSocialMediaInput = false
        socialMediaInput = ""
        selectedPlatform = ""
    }
    
    private func openSocialMediaLink(_ link: String) {
        guard let url = URL(string: link) else { return }
        openURL(url)
    }
    
    private func getSocialMediaLink(for platform: String) -> String? {
        return contact.socialMediaLinks[platform]
    }
    
    var body: some View {
        Form {
            Section {
                // Contact header
                VStack(spacing: 16) {
                    // Contact photo or initials placeholder
                    if let photo = contactPhoto {
                        Image(uiImage: photo)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(initials)
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                            )
                    }
                    
                    // Name
                    Text(fullName)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Company and job title
                    if let company = contact.company, !company.isEmpty {
                        Text(company)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let jobTitle = contact.jobTitle, !jobTitle.isEmpty {
                        Text(jobTitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            
            Section {
                Button(action: openDatePicker) {
                    HStack {
                        Text("Last one-to-one")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(formattedDateString())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Phone Numbers Section
            Section("Phone") {
                if phoneNumbers.isEmpty {
                    Text("Add phone")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(indexedItems(from: phoneNumbers)) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(phoneLabel(for: item.index).capitalized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(item.value)
                                    .foregroundStyle(.primary)
                            }
                            Spacer()
                            Button(action: {
                                callPhone(item.value)
                            }) {
                                Image(systemName: "phone.fill")
                                    .foregroundStyle(.blue)
                            }
                            .buttonStyle(.plain)
                            Button(action: {
                                sendMessage(item.value)
                            }) {
                                Image(systemName: "message.fill")
                                    .foregroundStyle(.blue)
                            }
                            .buttonStyle(.plain)
                            Button(action: {
                                startFaceTimeAudio(item.value)
                            }) {
                                Image(systemName: "phone.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                            .buttonStyle(.plain)
                            Button(action: {
                                startFaceTimeVideo(item.value)
                            }) {
                                Image(systemName: "video.fill")
                                    .foregroundStyle(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            // Email Addresses Section
            Section("Email") {
                if emails.isEmpty {
                    Text("Add email")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(indexedItems(from: emails)) { item in
                        HStack {
                            Text(item.value)
                                .foregroundStyle(.primary)
                            Spacer()
                            Button(action: {
                                sendEmail(item.value)
                            }) {
                                Image(systemName: "envelope.fill")
                                    .foregroundStyle(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            // Addresses Section
            Section("Address") {
                if addresses.isEmpty {
                    Text("Add address")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(indexedItems(from: addresses)) { item in
                        HStack {
                            Text(item.value)
                                .foregroundStyle(.primary)
                            Spacer()
                            Button(action: {
                                openMaps(with: item.value)
                            }) {
                                Image(systemName: "map.fill")
                                    .foregroundStyle(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            // Birthday Section
            Section("Birthday") {
                if let birthday = contact.birthday {
                    Text(formattedBirthdayString(for: birthday))
                        .foregroundStyle(.primary)
                } else {
                    Text("Add birthday")
                        .foregroundStyle(.secondary)
                }
            }
            
            // Notes Section
            Section("Notes") {
                if let notes = contact.notes, !notes.isEmpty {
                    Text(notes)
                        .foregroundStyle(.primary)
                } else {
                    Text("Add notes")
                        .foregroundStyle(.secondary)
                }
            }
            
            // Social Media Section
            Section("Social Media") {
                socialMediaRow(platform: "Instagram")
                socialMediaRow(platform: "LinkedIn")
                socialMediaRow(platform: "Facebook")
                socialMediaRow(platform: "Twitter/X")
            }
        }
        .navigationTitle(fullName)
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            // Celebration overlay
            if showStreakCelebration {
                celebrationView
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(
                selectedDate: $selectedDate,
                onSave: saveDate,
                onCancel: {
                    showDatePicker = false
                }
            )
        }
        .sheet(isPresented: $showSocialMediaInput) {
            SocialMediaInputSheet(
                platform: selectedPlatform,
                input: $socialMediaInput,
                onSave: saveSocialMediaLink,
                onCancel: {
                    showSocialMediaInput = false
                    socialMediaInput = ""
                    selectedPlatform = ""
                }
            )
        }
        .sheet(isPresented: $showEditSheet) {
            EditContactSheet(
                contact: contact,
                onSave: {
                    try? modelContext.save()
                    showEditSheet = false
                },
                onCancel: {
                    showEditSheet = false
                }
            )
        }
    }
    
    @ViewBuilder
    private func socialMediaRow(platform: String) -> some View {
        if let link = getSocialMediaLink(for: platform) {
            HStack {
                Text(platform)
                    .foregroundStyle(.primary)
                Spacer()
                Button(action: {
                    openSocialMediaLink(link)
                }) {
                    Image(systemName: "link")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                openSocialMediaInput(for: platform)
            }
        } else {
            Button(action: {
                openSocialMediaInput(for: platform)
            }) {
                HStack {
                    Text("Add \(platform)")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
            .buttonStyle(.plain)
        }
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
}

struct SocialMediaInputSheet: View {
    let platform: String
    @Binding var input: String
    let onSave: () -> Void
    let onCancel: () -> Void
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("URL or username", text: $input)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($isInputFocused)
                } header: {
                    Text("Enter \(platform) link")
                } footer: {
                    Text("Enter a full URL (e.g., https://instagram.com/username) or just the username")
                }
            }
            .navigationTitle("\(platform) Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                        .fontWeight(.semibold)
                        .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                isInputFocused = true
            }
        }
    }
}

struct EditContactSheet: View {
    let contact: Contact
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var company: String
    @State private var jobTitle: String
    @State private var birthday: Date?
    @State private var showBirthdayPicker = false
    @State private var phoneNumbers: [String] = []
    @State private var showPhoneNumberEditor = false
    @State private var editingPhoneIndex: Int?
    @State private var editingPhoneNumber = ""
    @State private var emails: [String] = []
    @State private var showEmailEditor = false
    @State private var editingEmailIndex: Int?
    @State private var editingEmail = ""
    @State private var notes: String = ""
    
    init(contact: Contact, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.contact = contact
        self.onSave = onSave
        self.onCancel = onCancel
        
        _firstName = State(initialValue: contact.firstName)
        _lastName = State(initialValue: contact.lastName ?? "")
        _company = State(initialValue: contact.company ?? "")
        _jobTitle = State(initialValue: contact.jobTitle ?? "")
        _birthday = State(initialValue: contact.birthday)
        _phoneNumbers = State(initialValue: contact.phoneNumbers)
        _emails = State(initialValue: contact.emails)
        _notes = State(initialValue: contact.notes ?? "")
    }
    
    private var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func saveChanges() {
        contact.firstName = firstName.trimmingCharacters(in: .whitespaces)
        contact.lastName = lastName.trimmingCharacters(in: .whitespaces).isEmpty ? nil : lastName.trimmingCharacters(in: .whitespaces)
        contact.company = company.trimmingCharacters(in: .whitespaces).isEmpty ? nil : company.trimmingCharacters(in: .whitespaces)
        contact.jobTitle = jobTitle.trimmingCharacters(in: .whitespaces).isEmpty ? nil : jobTitle.trimmingCharacters(in: .whitespaces)
        contact.birthday = birthday
        
        // Save phone numbers (filter out empty ones)
        contact.phoneNumbers = phoneNumbers
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        // Save emails (filter out empty ones)
        contact.emails = emails
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        // Save notes
        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)
        contact.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        
        onSave()
    }
    
    private func deletePhoneNumber(at offsets: IndexSet) {
        phoneNumbers.remove(atOffsets: offsets)
    }
    
    private func editPhoneNumber(at index: Int) {
        editingPhoneIndex = index
        editingPhoneNumber = phoneNumbers[index]
        showPhoneNumberEditor = true
    }
    
    private func addPhoneNumber() {
        editingPhoneIndex = nil
        editingPhoneNumber = ""
        showPhoneNumberEditor = true
    }
    
    private func savePhoneNumber() {
        let trimmed = editingPhoneNumber.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        if let index = editingPhoneIndex {
            phoneNumbers[index] = trimmed
        } else {
            phoneNumbers.append(trimmed)
        }
        
        showPhoneNumberEditor = false
        editingPhoneIndex = nil
        editingPhoneNumber = ""
    }
    
    private func deleteEmail(at offsets: IndexSet) {
        emails.remove(atOffsets: offsets)
    }
    
    private func editEmail(at index: Int) {
        editingEmailIndex = index
        editingEmail = emails[index]
        showEmailEditor = true
    }
    
    private func addEmail() {
        editingEmailIndex = nil
        editingEmail = ""
        showEmailEditor = true
    }
    
    private func saveEmail() {
        let trimmed = editingEmail.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        if let index = editingEmailIndex {
            emails[index] = trimmed
        } else {
            emails.append(trimmed)
        }
        
        showEmailEditor = false
        editingEmailIndex = nil
        editingEmail = ""
    }
    
    private func formattedBirthday() -> String {
        guard let birthday = birthday else { return "Add birthday" }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: birthday)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("First Name", text: $firstName)
                        .textContentType(.givenName)
                    
                    TextField("Last Name", text: $lastName)
                        .textContentType(.familyName)
                }
                
                Section("Work") {
                    TextField("Company", text: $company)
                        .textContentType(.organizationName)
                    
                    TextField("Job Title", text: $jobTitle)
                        .textContentType(.jobTitle)
                }
                
                Section {
                    if phoneNumbers.isEmpty {
                        Button(action: addPhoneNumber) {
                            HStack {
                                Text("Add Phone Number")
                                    .foregroundStyle(.blue)
                                Spacer()
                            }
                        }
                    } else {
                        ForEach(phoneNumbers.indices, id: \.self) { index in
                            Button(action: {
                                editPhoneNumber(at: index)
                            }) {
                                HStack {
                                    Text(phoneNumbers[index])
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: deletePhoneNumber)
                        
                        Button(action: addPhoneNumber) {
                            HStack {
                                Text("Add Phone Number")
                                    .foregroundStyle(.blue)
                                Spacer()
                            }
                        }
                    }
                } header: {
                    Text("Phone Numbers")
                }
                
                Section {
                    if emails.isEmpty {
                        Button(action: addEmail) {
                            HStack {
                                Text("Add Email Address")
                                    .foregroundStyle(.blue)
                                Spacer()
                            }
                        }
                    } else {
                        ForEach(emails.indices, id: \.self) { index in
                            Button(action: {
                                editEmail(at: index)
                            }) {
                                HStack {
                                    Text(emails[index])
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: deleteEmail)
                        
                        Button(action: addEmail) {
                            HStack {
                                Text("Add Email Address")
                                    .foregroundStyle(.blue)
                                Spacer()
                            }
                        }
                    }
                } header: {
                    Text("Email Addresses")
                }
                
                Section("Birthday") {
                    Button(action: {
                        showBirthdayPicker = true
                    }) {
                        HStack {
                            Text("Birthday")
                            Spacer()
                            Text(formattedBirthday())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: saveChanges)
                        .fontWeight(.semibold)
                        .disabled(!isFormValid)
                }
            }
            .sheet(isPresented: $showBirthdayPicker) {
                BirthdayPickerSheet(
                    selectedDate: Binding(
                        get: { birthday ?? Date() },
                        set: { birthday = $0 }
                    ),
                    onSave: {
                        showBirthdayPicker = false
                    },
                    onCancel: {
                        showBirthdayPicker = false
                    },
                    onClear: {
                        birthday = nil
                        showBirthdayPicker = false
                    }
                )
            }
            .sheet(isPresented: $showPhoneNumberEditor) {
                PhoneNumberEditorSheet(
                    phoneNumber: $editingPhoneNumber,
                    isEditing: editingPhoneIndex != nil,
                    onSave: savePhoneNumber,
                    onCancel: {
                        showPhoneNumberEditor = false
                        editingPhoneIndex = nil
                        editingPhoneNumber = ""
                    }
                )
            }
            .sheet(isPresented: $showEmailEditor) {
                EmailEditorSheet(
                    email: $editingEmail,
                    isEditing: editingEmailIndex != nil,
                    onSave: saveEmail,
                    onCancel: {
                        showEmailEditor = false
                        editingEmailIndex = nil
                        editingEmail = ""
                    }
                )
            }
        }
    }
}

struct BirthdayPickerSheet: View {
    @Binding var selectedDate: Date
    let onSave: () -> Void
    let onCancel: () -> Void
    let onClear: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DatePicker(
                    "Select Birthday",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()
                
                Spacer()
            }
            .navigationTitle("Birthday")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    HStack {
                        Button("Clear", action: onClear)
                        Button("Save", action: onSave)
                            .fontWeight(.semibold)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}

struct PhoneNumberEditorSheet: View {
    @Binding var phoneNumber: String
    let isEditing: Bool
    let onSave: () -> Void
    let onCancel: () -> Void
    @FocusState private var isPhoneNumberFocused: Bool
    
    private var isFormValid: Bool {
        !phoneNumber.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Phone Number", text: $phoneNumber)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                        .focused($isPhoneNumberFocused)
                } header: {
                    Text("Phone Number")
                }
            }
            .navigationTitle(isEditing ? "Edit Phone Number" : "Add Phone Number")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                        .fontWeight(.semibold)
                        .disabled(!isFormValid)
                }
            }
            .onAppear {
                isPhoneNumberFocused = true
            }
        }
    }
}

struct EmailEditorSheet: View {
    @Binding var email: String
    let isEditing: Bool
    let onSave: () -> Void
    let onCancel: () -> Void
    @FocusState private var isEmailFocused: Bool
    
    private var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email Address", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($isEmailFocused)
                } header: {
                    Text("Email Address")
                }
            }
            .navigationTitle(isEditing ? "Edit Email Address" : "Add Email Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                        .fontWeight(.semibold)
                        .disabled(!isFormValid)
                }
            }
            .onAppear {
                isEmailFocused = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        ContactDetailView(
            navigationPath: .constant(NavigationPath()),
            contact: Contact(firstName: "John", lastName: "Doe", company: "Acme Inc", jobTitle: "Software Engineer")
        )
        .modelContainer(for: Contact.self, inMemory: true)
    }
}
