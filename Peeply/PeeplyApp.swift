//
//  PeeplyApp.swift
//  Peeply
//
//  Created by Jason LaChance on 1/18/26.
//

import SwiftUI
import SwiftData
import RevenueCat
import UserNotifications
import GoMarketMe

@main
struct PeeplyApp: App {
    init() {
        Purchases.configure(withAPIKey: "appl_qcjTLYRzAoUdqtJvrxRgClMbaQB")
        GoMarketMe.shared.initialize(apiKey: "Zx3wrjwhmRZPOnjYXmId4q3vmcWgRyV7gqMVJBS3")
    }
    
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
            cloudKitDatabase: .none
        )
        
        do {
            return try ModelContainer(
                for: Schema([Contact.self, PeeplyUser.self, OnboardingAnswer.self]),
                migrationPlan: PeeplyMigrationPlan.self,
                configurations: [configuration]
            )
        } catch let error {
            print("ModelContainer with migrationPlan failed: \(error.localizedDescription)")
            
            do {
                return try ModelContainer(for: schema, configurations: [configuration])
            } catch let error {
                print("ModelContainer without migrationPlan failed: \(error.localizedDescription)")
                
                let inMemoryConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true,
                    cloudKitDatabase: .none
                )
                
                do {
                    return try ModelContainer(for: schema, configurations: [inMemoryConfiguration])
                } catch let error {
                    print("All ModelContainer attempts failed: \(error.localizedDescription)")
                    fatalError("Failed to create model container: \(error.localizedDescription)")
                }
            }
        }
    }
}
