//
//  StreakManager.swift
//  Peeply
//
//  Created by Jason LaChance on 1/18/26.
//

import Foundation
import SwiftData

class StreakManager {
    /// Updates the user's connection streak when a contact's lastOneToOne is set to today
    /// - Parameters:
    ///   - user: The PeeplyUser to update
    ///   - modelContext: The SwiftData model context for saving
    /// - Returns: true if streak was incremented (for celebration), false otherwise
    static func updateStreak(for user: PeeplyUser, in modelContext: ModelContext) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let lastUpdate = user.lastStreakUpdate else {
            // First time updating - start streak at 1
            user.currentStreak = 1
            user.lastStreakUpdate = today
            user.longestStreak = max(user.longestStreak, user.currentStreak)
            try? modelContext.save()
            return true
        }
        
        let lastUpdateDay = calendar.startOfDay(for: lastUpdate)
        
        if calendar.isDate(lastUpdateDay, inSameDayAs: today) {
            // Already updated today - do nothing
            return false
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  calendar.isDate(lastUpdateDay, inSameDayAs: yesterday) {
            // Last update was yesterday - increment streak
            user.currentStreak += 1
            user.lastStreakUpdate = today
            user.longestStreak = max(user.longestStreak, user.currentStreak)
            try? modelContext.save()
            return true
        } else {
            // Last update was older - reset streak to 1
            user.currentStreak = 1
            user.lastStreakUpdate = today
            user.longestStreak = max(user.longestStreak, user.currentStreak)
            try? modelContext.save()
            return false
        }
    }
    
    /// Checks if a date is today
    static func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}
