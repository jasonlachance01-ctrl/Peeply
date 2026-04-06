//
//  PeeplySchemaV1.swift
//  Peeply
//
//  Created by Jason LaChance on 4/6/26.
//

import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] = [
        Contact.self,
        PeeplyUser.self,
        OnboardingAnswer.self,
    ]
}
