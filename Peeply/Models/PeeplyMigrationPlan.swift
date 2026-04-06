//
//  PeeplyMigrationPlan.swift
//  Peeply
//
//  Created by Jason LaChance on 4/6/26.
//

import SwiftData

enum PeeplyMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var migrationStages: [MigrationStage] = []

    static var stages: [MigrationStage] {
        migrationStages
    }
}
