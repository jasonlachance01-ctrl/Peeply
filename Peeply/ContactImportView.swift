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
    // Navigation path binding so this screen can route forward after import completes.
    @Binding var navigationPath: NavigationPath

    // SwiftData model context used to insert and save Contact / PeeplyUser models.
    @Environment(\.modelContext) private var modelContext

    // Existing app users from SwiftData. The app seems to assume a single current user.
    @Query private var users: [PeeplyUser]

    // UI state flags for alerts and import progress.
    @State private var showPermissionDeniedAlert = false
    @State private var showImportErrorAlert = false
    @State private var showSuccessMessage = false
    @State private var isImporting = false
    @State private var showNotificationPrePromptAlert = false

    // Summary shown after the import completes.
    @State private var importSummary: ImportSummary?

    // Apple Contacts framework entry point for reading the device contact database.
    //private let contactStore = CNContactStore()

    // Save imported contacts in chunks instead of one giant save at the end.
    // This reduces memory growth and limits how much work is lost if a batch fails.
    private let saveBatchSize = 250

    // Convenience to get the first (current) Peeply user, if one already exists.
    private var currentUser: PeeplyUser? {
        users.first
    }

    /// Aggregated counts collected during import so the UI can report what happened.
    struct ImportSummary: Sendable {
        var scanned = 0
        var imported = 0
        var skippedDuplicates = 0
        var skippedNameless = 0
        var contactsWithPhotos = 0
        var partialFailures = 0
    }

    /// Ask the user for permission to read contacts.
    ///
    /// If access is granted, start the import flow.
    /// If access is denied, show an explanatory alert.
    private func requestContactsPermission() {
        let contactStore = CNContactStore()

        contactStore.requestAccess(for: .contacts) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    Task {
                        await importContacts()
                    }
                } else {
                    showPermissionDeniedAlert = true
                }
            }
        }
    }

    /// Main import routine.
    ///
    /// Design goals:
    /// - stream contacts instead of loading all into memory at once,
    /// - deduplicate using stronger keys than just first/last name,
    /// - save in chunks for better memory behavior,
    /// - keep going if one batch fails instead of failing the whole import.
    ///
    /// Threading model:
    /// - Contacts enumeration runs off the main thread because CNContactStore fetches perform I/O.
    /// - SwiftUI state and the environment-provided SwiftData modelContext stay on MainActor.
    /// - The importer therefore uses a two-phase pipeline:
    ///   1) background enumeration into lightweight PreparedContact values,
    ///   2) main-actor persistence into SwiftData in batches.
    private func importContacts() async {
        await MainActor.run {
            isImporting = true
            importSummary = nil
        }

        do {
            // Build a dedupe index from contacts already stored in Peeply.
            // This lets us avoid importing duplicates across app launches.
            let dedupeIndex = try await MainActor.run {
                try buildExistingDedupeIndex()
            }

            // Ask the Contacts framework for only the fields we actually need.
            // Fetching fewer fields reduces memory and improves performance.
            //
            // Note:
            // CNContactStore fetch methods should not be executed on the main thread.
            // We enumerate in a detached task and return only Sendable value types.
            let backgroundResult = try await Task.detached(priority: .userInitiated) {
                try enumerateContactsOffMain(startingDedupeIndex: dedupeIndex)
            }.value

            // Persist the prepared contacts on MainActor because this view's modelContext
            // is environment-scoped SwiftData state and should remain actor-confined.
            let finalSummary = try await MainActor.run {
                try persistPreparedContacts(
                    backgroundResult.preparedContacts,
                    startingSummary: backgroundResult.summary,
                    startingDedupeIndex: dedupeIndex
                )
            }

            // Ensure the app has a current user record and mark contacts as imported.
            try await MainActor.run {
                try upsertUserImportState()
            }

            // Schedule the daily badge notification after a successful import pass.
            PersonOfTheDayManager.scheduleDailyBadgeNotification()

            await MainActor.run {
                importSummary = finalSummary
                isImporting = false
                showSuccessMessage = true
                showNotificationPrePromptAlert = true
            }

            // Console summary is useful during development and large-import testing.
            print("=== Contact Import Summary ===")
            print("Scanned: \(finalSummary.scanned)")
            print("Imported: \(finalSummary.imported)")
            print("Skipped duplicates: \(finalSummary.skippedDuplicates)")
            print("Skipped nameless: \(finalSummary.skippedNameless)")
            print("With photos: \(finalSummary.contactsWithPhotos)")
            print("Partial failures: \(finalSummary.partialFailures)")
        } catch {
            // Top-level failure: permission / fetch setup / catastrophic import issue.
            await MainActor.run {
                isImporting = false
                showImportErrorAlert = true
            }
            print("Error importing contacts: \(error)")
        }
    }

    /// Update the existing Peeply user, or create one if none exists yet.
    ///
    /// This records that contacts were imported and seeds Person of the Day metadata.
    @MainActor
    private func upsertUserImportState() throws {
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
    }

    /// Normalized intermediate representation of a CNContact.
    ///
    /// This separates "read and normalize" from "insert into SwiftData".
    /// It also gives us a clean place to compute duplicate-detection keys.
    private struct PreparedContact: Sendable {
        let firstName: String
        let lastName: String?
        let normalizedNameKey: String
        let phoneNumbers: [String]
        let normalizedPhones: Set<String>
        let emails: [String]
        let normalizedEmails: Set<String>
        let company: String?
        let jobTitle: String?
        let birthday: Date?
        let addresses: [String]
        let photoData: Data?
        let displaySortKey: String
    }

    /// Result returned from the background enumeration phase.
    ///
    /// This contains only lightweight Sendable values so it can safely cross
    /// from the detached task back to MainActor persistence.
    private struct BackgroundEnumerationResult: Sendable {
        let preparedContacts: [PreparedContact]
        let summary: ImportSummary
    }

    /// In-memory duplicate detection index.
    ///
    /// We track several kinds of keys:
    /// - name-only,
    /// - phone-only,
    /// - email-only,
    /// - composite name+phone,
    /// - composite name+email.
    ///
    /// This is much stronger than firstName + lastName only.
    private struct DedupeIndex: Sendable {
        var nameKeys = Set<String>()
        var phoneKeys = Set<String>()
        var emailKeys = Set<String>()
        var compositeKeys = Set<String>()
    }

    /// Build the dedupe index from contacts already stored in Peeply.
    ///
    /// This lets the importer skip duplicates that were imported in a previous session.
    @MainActor
    private func buildExistingDedupeIndex() throws -> DedupeIndex {
        let descriptor = FetchDescriptor<Contact>()
        let existingContacts = try modelContext.fetch(descriptor)

        var index = DedupeIndex()
        var didBackfillDisplaySortKey = false

        for contact in existingContacts {
            // Backfill persisted sort keys for contacts that predate displaySortKey
            // or whose names changed before the sort key was kept in sync.
            let expectedDisplaySortKey = Contact.makeDisplaySortKey(
                firstName: contact.firstName,
                lastName: contact.lastName
            )
            if contact.displaySortKey != expectedDisplaySortKey {
                contact.displaySortKey = expectedDisplaySortKey
                didBackfillDisplaySortKey = true
            }

            let firstName = normalizeName(contact.firstName)
            let lastName = normalizeName(contact.lastName ?? "")
            let normalizedNameKey = "\(firstName)|\(lastName)"

            if !firstName.isEmpty {
                index.nameKeys.insert(normalizedNameKey)
            }

            let normalizedPhones = Set(contact.phoneNumbers.map(normalizePhone).filter { !$0.isEmpty })
            let normalizedEmails = Set(contact.emails.map(normalizeEmail).filter { !$0.isEmpty })

            index.phoneKeys.formUnion(normalizedPhones)
            index.emailKeys.formUnion(normalizedEmails)

            if !normalizedNameKey.isEmpty {
                for phone in normalizedPhones {
                    index.compositeKeys.insert("\(normalizedNameKey)|p:\(phone)")
                }
                for email in normalizedEmails {
                    index.compositeKeys.insert("\(normalizedNameKey)|e:\(email)")
                }
            }
        }

        if didBackfillDisplaySortKey {
            try modelContext.save()
        }

        return index
    }

    /// Enumerate device contacts off the main thread and convert them into
    /// lightweight PreparedContact values.
    ///
    /// This phase intentionally does NOT touch SwiftUI state or modelContext.
    /// Keeping Contacts I/O here avoids the Xcode runtime warning about
    /// enumerateContacts(with:) running on the main thread.
    private nonisolated func enumerateContactsOffMain(
        startingDedupeIndex: DedupeIndex
    ) throws -> BackgroundEnumerationResult {
        let contactStore = CNContactStore()
        var summary = ImportSummary()

        // Ask the Contacts framework for only the fields we actually need.
        // Fetching fewer fields reduces memory and improves performance.
        let keys: [CNKeyDescriptor] = [
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactJobTitleKey as CNKeyDescriptor,
            CNContactBirthdayKey as CNKeyDescriptor,
            CNContactPostalAddressesKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor
        ]

        // CNContactFetchRequest + enumerateContacts lets us process contacts one-by-one
        // rather than building a giant [CNContact] array in memory.
        let request = CNContactFetchRequest(keysToFetch: keys)
        request.unifyResults = true
        request.sortOrder = .userDefault

        // Mutable copy of the dedupe index so each newly prepared contact is registered
        // immediately and can block duplicates later in the same import run.
        var mutableDedupeIndex = startingDedupeIndex

        // Buffer of lightweight prepared contacts that will later be persisted on MainActor.
        var preparedContacts: [PreparedContact] = []
        preparedContacts.reserveCapacity(512)

        try contactStore.enumerateContacts(with: request) { cnContact, stop in
            summary.scanned += 1

            // autoreleasepool helps keep transient Foundation / Contacts objects
            // from piling up during very large imports.
            autoreleasepool {
                // Convert the Contacts-framework object into a normalized form
                // that Peeply can use for dedupe and persistence.
                guard let prepared = prepareImportedContact(from: cnContact) else {
                    // Skip completely empty / unusable contacts.
                    summary.skippedNameless += 1
                    return
                }

                // Skip anything that looks like a duplicate by name, phone, email,
                // or name+phone / name+email composite matching.
                if isDuplicate(prepared: prepared, dedupeIndex: mutableDedupeIndex) {
                    summary.skippedDuplicates += 1
                    return
                }

                // Keep only the normalized value representation during the background phase.
                // SwiftData model creation is deferred until the main-actor persistence phase.
                preparedContacts.append(prepared)

                // Register the prepared contact in the in-memory dedupe index immediately
                // so later contacts in the same import run can detect it as a duplicate.
                register(prepared: prepared, into: &mutableDedupeIndex)

                summary.imported += 1
                if prepared.photoData != nil {
                    summary.contactsWithPhotos += 1
                }
            }
        }

        return BackgroundEnumerationResult(
            preparedContacts: preparedContacts,
            summary: summary
        )
    }

    /// Persist prepared contacts into SwiftData on MainActor.
    ///
    /// SwiftData's view-scoped modelContext should remain on the main actor, so this phase
    /// performs model creation, insertion, and save batching after background enumeration ends.
    @MainActor
    private func persistPreparedContacts(
        _ preparedContacts: [PreparedContact],
        startingSummary: ImportSummary,
        startingDedupeIndex: DedupeIndex
    ) throws -> ImportSummary {
        var summary = startingSummary

        // Number of inserted Contact records not yet flushed to disk with save().
        var pendingInsertCount = 0

        // Mutable copy of the dedupe index so each newly imported contact is registered
        // immediately and can block duplicates later in the same persistence pass.
        //
        // We start from the same existing-contact index used during enumeration, then
        // register only contacts that are actually inserted into SwiftData.
        var mutableDedupeIndex = startingDedupeIndex

        for prepared in preparedContacts {
            // Defensive duplicate check.
            //
            // Background enumeration already filtered duplicates, but the app's stored data
            // could have changed before persistence begins. Rechecking here keeps inserts safe.
            if isDuplicate(prepared: prepared, dedupeIndex: mutableDedupeIndex) {
                summary.imported -= 1
                summary.skippedDuplicates += 1
                continue
            }

            // Create the SwiftData Contact model from the prepared data.
            let newContact = Contact(
                firstName: prepared.firstName,
                lastName: prepared.lastName,
                phoneNumbers: prepared.phoneNumbers,
                emails: prepared.emails,
                company: prepared.company,
                jobTitle: prepared.jobTitle,
                notes: nil, // Contact notes are not imported.
                birthday: prepared.birthday,
                addresses: prepared.addresses,
                photoData: prepared.photoData
            )

            // Make the persisted sort key explicit in the import path so the diff clearly shows
            // that imported contacts participate in query-level sorting immediately.
            newContact.displaySortKey = prepared.displaySortKey

            // Stage the insert in the SwiftData context.
            modelContext.insert(newContact)

            // Register the new contact in the in-memory dedupe index immediately
            // so later contacts in the same import run can detect it as a duplicate.
            register(prepared: prepared, into: &mutableDedupeIndex)

            pendingInsertCount += 1

            // Persist every batch of contacts instead of waiting for the very end.
            if pendingInsertCount >= saveBatchSize {
                do {
                    try modelContext.save()
                    pendingInsertCount = 0
                } catch {
                    // Roll back only unsaved changes in the current batch and continue.
                    // Apple documents rollback() as restoring the context to the last
                    // committed state. This keeps the import resilient to partial failures.
                    summary.partialFailures += 1
                    modelContext.rollback()
                    pendingInsertCount = 0
                }
            }
        }

        // Save any remaining inserts that didn't fill a whole batch.
        if pendingInsertCount > 0 {
            do {
                try modelContext.save()
            } catch {
                summary.partialFailures += 1
                modelContext.rollback()
            }
        }

        return summary
    }

    /// Convert a CNContact into Peeply's prepared format.
    ///
    /// Returns nil when the contact has no usable identity at all
    /// (no name, no phone, no email).
    private nonisolated func prepareImportedContact(from cnContact: CNContact) -> PreparedContact? {
        let firstNameRaw = cnContact.givenName.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastNameRaw = cnContact.familyName.trimmingCharacters(in: .whitespacesAndNewlines)

        let firstName = firstNameRaw
        let lastName = lastNameRaw.isEmpty ? nil : lastNameRaw

        let normalizedFirst = normalizeName(firstNameRaw)
        let normalizedLast = normalizeName(lastNameRaw)
        let normalizedNameKey = "\(normalizedFirst)|\(normalizedLast)"

        let phoneNumbers = cnContact.phoneNumbers.map { $0.value.stringValue }
        let normalizedPhones = Set(phoneNumbers.map(normalizePhone).filter { !$0.isEmpty })

        let emails = cnContact.emailAddresses.map { $0.value as String }
        let normalizedEmails = Set(emails.map(normalizeEmail).filter { !$0.isEmpty })

        let hasName = !normalizedFirst.isEmpty || !normalizedLast.isEmpty
        let hasPhone = !normalizedPhones.isEmpty
        let hasEmail = !normalizedEmails.isEmpty

        // Skip entries that are effectively blank and unusable.
        guard hasName || hasPhone || hasEmail else {
            return nil
        }

        let company = cnContact.organizationName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty

        let jobTitle = cnContact.jobTitle
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty

        // Contacts birthday is DateComponents, so convert it to Date if possible.
        var birthday: Date? = nil
        if let birthdayComponents = cnContact.birthday {
            var components = DateComponents()
            components.year = birthdayComponents.year
            components.month = birthdayComponents.month
            components.day = birthdayComponents.day
            birthday = Calendar.current.date(from: components)
        }

        // Flatten each postal address into one readable string.
        let addresses = cnContact.postalAddresses.compactMap { labeledValue -> String? in
            let address = labeledValue.value
            let parts = [
                address.street.trimmingCharacters(in: .whitespacesAndNewlines),
                address.city.trimmingCharacters(in: .whitespacesAndNewlines),
                address.state.trimmingCharacters(in: .whitespacesAndNewlines),
                address.postalCode.trimmingCharacters(in: .whitespacesAndNewlines),
                address.country.trimmingCharacters(in: .whitespacesAndNewlines)
            ].filter { !$0.isEmpty }

            return parts.isEmpty ? nil : parts.joined(separator: ", ")
        }

        // Thumbnail image is smaller than full imageData and better for large imports.
        let photoData = cnContact.thumbnailImageData

        // If no first name exists, fall back to email or phone so the app still has
        // a visible primary label for the imported record.
        let resolvedFirstName = firstName.isEmpty ? (emails.first ?? phoneNumbers.first ?? "Unknown") : firstName
        let displaySortKey = Contact.makeDisplaySortKey(firstName: resolvedFirstName, lastName: lastName)

        return PreparedContact(
            firstName: resolvedFirstName,
            lastName: lastName,
            normalizedNameKey: normalizedNameKey,
            phoneNumbers: phoneNumbers,
            normalizedPhones: normalizedPhones,
            emails: emails,
            normalizedEmails: normalizedEmails,
            company: company,
            jobTitle: jobTitle,
            birthday: birthday,
            addresses: addresses,
            photoData: photoData,
            displaySortKey: displaySortKey
        )
    }

    /// Decide whether a prepared contact should be considered a duplicate.
    ///
    /// Current strategy:
    /// - exact normalized name match,
    /// - any normalized phone match,
    /// - any normalized email match,
    /// - any name+phone composite match,
    /// - any name+email composite match.
    private nonisolated func isDuplicate(prepared: PreparedContact, dedupeIndex: DedupeIndex) -> Bool {
        //if !prepared.normalizedNameKey.replacingOccurrences(of: "|", with: "").isEmpty,
        //   dedupeIndex.nameKeys.contains(prepared.normalizedNameKey) {
        //    return true
        //}

        if prepared.normalizedPhones.contains(where: { dedupeIndex.phoneKeys.contains($0) }) {
            return true
        }

        if prepared.normalizedEmails.contains(where: { dedupeIndex.emailKeys.contains($0) }) {
            return true
        }

        for phone in prepared.normalizedPhones {
            if dedupeIndex.compositeKeys.contains("\(prepared.normalizedNameKey)|p:\(phone)") {
                return true
            }
        }

        for email in prepared.normalizedEmails {
            if dedupeIndex.compositeKeys.contains("\(prepared.normalizedNameKey)|e:\(email)") {
                return true
            }
        }

        return false
    }

    /// Add a newly imported contact's keys into the dedupe index.
    ///
    /// This prevents duplicates later in the same import pass.
    private nonisolated func register(prepared: PreparedContact, into dedupeIndex: inout DedupeIndex) {
        if !prepared.normalizedNameKey.replacingOccurrences(of: "|", with: "").isEmpty {
            dedupeIndex.nameKeys.insert(prepared.normalizedNameKey)
        }

        dedupeIndex.phoneKeys.formUnion(prepared.normalizedPhones)
        dedupeIndex.emailKeys.formUnion(prepared.normalizedEmails)

        for phone in prepared.normalizedPhones {
            dedupeIndex.compositeKeys.insert("\(prepared.normalizedNameKey)|p:\(phone)")
        }

        for email in prepared.normalizedEmails {
            dedupeIndex.compositeKeys.insert("\(prepared.normalizedNameKey)|e:\(email)")
        }
    }

    /// Normalize names so matching is more reliable across case / accents / whitespace.
    private nonisolated func normalizeName(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    /// Normalize emails by trimming and lowercasing.
    private nonisolated func normalizeEmail(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    /// Normalize phone numbers to digits only.
    ///
    /// If longer than 10 digits, keep the last 10 as a pragmatic matching strategy
    /// for North American numbers. You may want to replace this later with a
    /// libPhoneNumber-style parser for international accuracy.
    private nonisolated func normalizePhone(_ value: String) -> String {
        let digits = value.filter(\.isNumber)
        if digits.count > 10 {
            return String(digits.suffix(10))
        }
        return digits
    }

    /// Route forward to the contact list after a successful import.
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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .alert("Contacts Permission Required", isPresented: $showPermissionDeniedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("To import your contacts, go to iPhone Settings > Privacy & Security > Contacts and enable access for Peeply.")
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
                        PersonOfTheDayManager.scheduleDailyBadgeNotification()
                    }
                }
            }
            Button("Skip", role: .cancel) { }
        } message: {
            Text("Peeply selects a Person of the Day for you each morning to help you stay consistent in your connections. Tap Continue to enable your notifications and never miss a Person of the Day!")
        }
    }

    /// The pre-import screen shown before a successful import.
    private var importView: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("Now let's import your contacts so Peeply can begin to help you build strong relationships!")
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)

            Button(action: requestContactsPermission) {
                Group {
                    if isImporting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Import Contacts")
                            .font(.headline)
                            .foregroundStyle(Color.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.peeplyPink)
                .cornerRadius(16)
            }
            .disabled(isImporting)
            .padding(.horizontal, 20)

            Spacer()

            Text("Contacts access is required to use Peeply. Allow access by tapping Import Contacts, or enable it later in iPhone Settings > Privacy & Security > Contacts.")
                .font(.caption)
                .foregroundStyle(Color.peeplyCharcoal.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
        }
        .background(Color.white)
    }

    /// The post-import success screen.
    private var successView: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.peeplyPink)

                    Text("Your contacts successfully imported!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.peeplyCharcoal)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    if let summary = importSummary {
                        Text("Imported \(summary.imported) contacts, skipped \(summary.skippedDuplicates) duplicates, and encountered \(summary.partialFailures) partial save failures.")
                            .font(.caption)
                            .foregroundStyle(Color.peeplyCharcoal.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    } else {
                        Text("Your contacts are now available in Peeply.")
                            .font(.caption)
                            .foregroundStyle(Color.peeplyCharcoal.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                .padding(.top, 40)
                .padding(.bottom, 32)

                Spacer()

                Button(action: continueToContactList) {
                    Text("Go to Your Contacts")
                        .font(.headline)
                        .foregroundStyle(Color.peeplyWhite)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.peeplyPink)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }
}

/// Convenience helper for converting empty strings into nil.
private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
