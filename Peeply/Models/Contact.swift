//
//  Contact.swift
//  Peeply
//
//  Created by Jason LaChance on 1/18/26.
//

import Foundation
import SwiftData

@Model
final class Contact {
    var id: UUID
    var firstName: String
    var lastName: String?
    var phoneNumbers: [String]
    var emails: [String]
    var company: String?
    var jobTitle: String?
    var notes: String?
    var birthday: Date?
    var addresses: [String]
    var lastOneToOne: Date?
    var photoData: Data?
    var socialMediaLinks: [String: String] // Platform name -> URL/username
    var createdAt: Date?
    var wasPersonOfTheDay: Date?
    
    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String? = nil,
        phoneNumbers: [String] = [],
        emails: [String] = [],
        company: String? = nil,
        jobTitle: String? = nil,
        notes: String? = nil,
        birthday: Date? = nil,
        addresses: [String] = [],
        lastOneToOne: Date? = nil,
        photoData: Data? = nil,
        socialMediaLinks: [String: String] = [:],
        createdAt: Date? = Date(),
        wasPersonOfTheDay: Date? = nil
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumbers = phoneNumbers
        self.emails = emails
        self.company = company
        self.jobTitle = jobTitle
        self.notes = notes
        self.birthday = birthday
        self.addresses = addresses
        self.lastOneToOne = lastOneToOne
        self.photoData = photoData
        self.socialMediaLinks = socialMediaLinks
        self.createdAt = createdAt
        self.wasPersonOfTheDay = wasPersonOfTheDay
    }
}
