//
//  AppRoute.swift
//  Peeply
//
//  Created by Jason LaChance on 1/18/26.
//

import Foundation
import SwiftData

enum AppRoute: Hashable {
    case splash
    case planSelection
    case onboarding
    case contactImport
    case contactList
    case contactDetail(Contact)
    case support
    case about
    case privacyPolicy
    case termsOfService
    
    static func == (lhs: AppRoute, rhs: AppRoute) -> Bool {
        switch (lhs, rhs) {
        case (.splash, .splash),
             (.planSelection, .planSelection),
             (.onboarding, .onboarding),
             (.contactImport, .contactImport),
             (.contactList, .contactList),
             (.support, .support),
             (.about, .about),
             (.privacyPolicy, .privacyPolicy),
             (.termsOfService, .termsOfService):
            return true
        case (.contactDetail(let lhsContact), .contactDetail(let rhsContact)):
            return lhsContact.id == rhsContact.id
        default:
            return false
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .splash:
            hasher.combine(0)
        case .planSelection:
            hasher.combine(1)
        case .onboarding:
            hasher.combine(2)
        case .contactImport:
            hasher.combine(3)
        case .contactList:
            hasher.combine(4)
        case .contactDetail(let contact):
            hasher.combine(5)
            hasher.combine(contact.id)
        case .support:
            hasher.combine(6)
        case .about:
            hasher.combine(7)
        case .privacyPolicy:
            hasher.combine(8)
        case .termsOfService:
            hasher.combine(9)
        }
    }
}
