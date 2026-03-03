//
//  PeeplyApp.swift
//  Peeply
//
//  Created by Jason LaChance on 1/18/26.
//

import SwiftUI
import SwiftData

@main
struct PeeplyApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(createModelContainer())
    }
    
    private func createModelContainer() -> ModelContainer {
        let schema = Schema([Contact.self, PeeplyUser.self, OnboardingAnswer.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch let error {
            fatalError("Failed to create model container: \(error.localizedDescription)")
        }
    }
}
