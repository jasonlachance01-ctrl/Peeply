//
//  PeeplyUser.swift
//  Peeply
//
//  Created by Jason LaChance on 1/18/26.
//

import Foundation
import SwiftData

@Model
final class PeeplyUser {
    var id: UUID
    var email: String
    var subscriptionTier: SubscriptionTier
    var createdAt: Date
    var onboardingCompleted: Bool
    var contactsImported: Bool
    var currentStreak: Int
    var longestStreak: Int
    var lastStreakUpdate: Date?
    var personOfTheDayContactId: UUID?
    var personOfTheDayDate: Date?
    var hasContactedPersonOfTheDay: Bool
    
    init(
        id: UUID = UUID(),
        email: String,
        subscriptionTier: SubscriptionTier,
        createdAt: Date = Date(),
        onboardingCompleted: Bool = false,
        contactsImported: Bool = false,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastStreakUpdate: Date? = nil,
        personOfTheDayContactId: UUID? = nil,
        personOfTheDayDate: Date? = nil,
        hasContactedPersonOfTheDay: Bool = false
    ) {
        self.id = id
        self.email = email
        self.subscriptionTier = subscriptionTier
        self.createdAt = createdAt
        self.onboardingCompleted = onboardingCompleted
        self.contactsImported = contactsImported
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastStreakUpdate = lastStreakUpdate
        self.personOfTheDayContactId = personOfTheDayContactId
        self.personOfTheDayDate = personOfTheDayDate
        self.hasContactedPersonOfTheDay = hasContactedPersonOfTheDay
    }
}
