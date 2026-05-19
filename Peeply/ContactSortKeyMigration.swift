//
//  ContactSortKeyMigration.swift
//  Peeply
//
//  Created by Jason LaChance on 1/18/26.
//

import Foundation
import SwiftData

enum ContactSortKeyMigration {
    /// Backfill persisted displaySortKey values for older Contact records that were created
    /// before the sort key existed, or whose names changed before the key was kept in sync.
    ///
    /// This migration is intentionally idempotent:
    /// - If every contact already has the correct key, nothing is saved.
    /// - If some contacts are missing or stale, only those contacts are updated.
    @MainActor
    static func backfillDisplaySortKeysIfNeeded(in modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Contact>()

        guard let contacts = try? modelContext.fetch(descriptor), !contacts.isEmpty else {
            return
        }

        var didChangeAnyContact = false

        for contact in contacts {
            let expectedDisplaySortKey = Contact.makeDisplaySortKey(
                firstName: contact.firstName,
                lastName: contact.lastName
            )

            if contact.displaySortKey != expectedDisplaySortKey {
                contact.displaySortKey = expectedDisplaySortKey
                didChangeAnyContact = true
            }
        }

        guard didChangeAnyContact else { return }

        do {
            try modelContext.save()
        } catch {
            print("Failed to backfill contact displaySortKey values: \(error)")
        }
    }
}
