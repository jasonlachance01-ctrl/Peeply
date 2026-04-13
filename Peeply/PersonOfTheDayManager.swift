//
//  PersonOfTheDayManager.swift
//  Peeply
//
//  Created by Jason LaChance on 1/18/26.
//

import Foundation
import SwiftData
import UserNotifications

class PersonOfTheDayManager {
    /// Updates the Person of the Day if needed
    /// - Parameters:
    ///   - user: The PeeplyUser to update
    ///   - contacts: Array of available contacts to choose from
    ///   - modelContext: The SwiftData model context for saving
    static func updatePersonOfTheDay(for user: PeeplyUser, contacts: [Contact], in modelContext: ModelContext) {
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate today's 3:00 AM cutoff
        var todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
        todayComponents.hour = 3
        todayComponents.minute = 0
        todayComponents.second = 0
        guard let today3AM = calendar.date(from: todayComponents) else {
            return
        }
        
        // Check if person of the day is already set for today (after 3 AM)
        if let lastDate = user.personOfTheDayDate {
            // Check if last selection was made on or after today's 3 AM cutoff
            if lastDate >= today3AM {
                // Person of the day is already set for today - keep it
                return
            }
        }
        
        // Only select new person if current time is past today's 3 AM
        if now < today3AM {
            // Current time is before 3 AM today, don't select yet
            return
        }
        
        // Need to select a new person of the day
        // Filter out contacts that don't have at least a first name
        var validContacts = contacts.filter { !$0.firstName.isEmpty }
        
        guard !validContacts.isEmpty else {
            // No valid contacts available
            return
        }
        
        // Filter out contacts that have been Person of the Day before (no-repeats logic)
        var unselectedContacts = validContacts.filter { $0.wasPersonOfTheDay == nil }
        
        // If all contacts have been selected, reset all and start over
        if unselectedContacts.isEmpty {
            // Reset all contacts' wasPersonOfTheDay
            for contact in validContacts {
                contact.wasPersonOfTheDay = nil
            }
            // Now all contacts are available again
            unselectedContacts = validContacts
        }
        
        // Select a random contact from unselected contacts
        guard let randomContact = unselectedContacts.randomElement() else {
            return
        }
        
        // Update the selected contact
        randomContact.wasPersonOfTheDay = now
        
        // Update user
        user.personOfTheDayContactId = randomContact.id
        user.personOfTheDayDate = now
        user.hasContactedPersonOfTheDay = false
        
        // Save changes
        try? modelContext.save()

        UNUserNotificationCenter.current().setBadgeCount(1, withCompletionHandler: nil)
        
        // Schedule notification for next day
        schedulePersonOfTheDayNotification()
    }
    
    /// Schedules a daily notification at 3:00 AM for Person of the Day
    static func schedulePersonOfTheDayNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["personOfTheDay"])
        let content = UNMutableNotificationContent()
        content.title = "Your Person of the Day is ready! 🌟"
        content.body = "Open Peeply to see who to connect with today."
        content.badge = 1
        content.sound = .default
        var dateComponents = DateComponents()
        dateComponents.hour = 3
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "personOfTheDay",
            content: content,
            trigger: trigger
        )
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
}
