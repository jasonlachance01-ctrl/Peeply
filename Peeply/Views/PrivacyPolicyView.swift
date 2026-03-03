//
//  PrivacyPolicyView.swift
//  Peeply
//
//  Created by Jason LaChance on 1/18/26.
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Title
                Text("Peeply Privacy Policy")
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundStyle(Color.peeplyCharcoal)
                    .padding(.top, 20)
                
                // Subtitle
                Text("Last updated: February 2026")
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundStyle(Color.peeplyCharcoal.opacity(0.6))
                
                // Our Commitment
                VStack(alignment: .leading, spacing: 12) {
                    Text("Our Commitment")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                    
                    Text("Peeply exists for one purpose: to help you maintain meaningful, consistent relationships with the people who matter most in your life. We are not a data company. We do not monetize your information. Your trust is the foundation of everything we build.")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                        .lineSpacing(4)
                }
                
                // What Peeply Collects
                VStack(alignment: .leading, spacing: 12) {
                    Text("What Peeply Collects")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                    
                    Text("Peeply imports the contact information you choose to share from your iOS Contacts, including names, phone numbers, email addresses, and other standard contact fields. Additionally, Peeply stores the \"Last One-to-One\" interaction dates that you manually enter. No other data is collected.")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                        .lineSpacing(4)
                }
                
                // How We Collect It
                VStack(alignment: .leading, spacing: 12) {
                    Text("How We Collect It")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                    
                    Text("All data enters Peeply through one of two ways: you explicitly import it from iOS Contacts (requiring your permission), or you manually enter it within the app. Peeply does not collect data automatically, passively, or in the background.")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                        .lineSpacing(4)
                }
                
                // How Your Data Is Used
                VStack(alignment: .leading, spacing: 12) {
                    Text("How Your Data Is Used")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                    
                    Text("Your data is used solely to display your contacts and relationship reminders within the app. It is never used for advertising, analytics, or any commercial purpose.")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                        .lineSpacing(4)
                }
                
                // Third Parties
                VStack(alignment: .leading, spacing: 12) {
                    Text("Third Parties")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                    
                    Text("Peeply does not share your data with any third parties. We do not use advertising networks, analytics SDKs, or data brokers. The only external service your data may touch is your personal iCloud account, governed by Apple's own privacy policy, if you choose to enable iCloud sync.")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                        .lineSpacing(4)
                }
                
                // Data Storage
                VStack(alignment: .leading, spacing: 12) {
                    Text("Data Storage")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                    
                    Text("Your data is stored locally on your device using Apple's SwiftData framework. If iCloud sync is enabled, data is stored in your personal iCloud account under your Apple ID.")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                        .lineSpacing(4)
                }
                
                // Data Retention & Deletion
                VStack(alignment: .leading, spacing: 12) {
                    Text("Data Retention & Deletion")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                    
                    Text("Your data remains in the app until you delete it. You may delete individual contacts at any time. To delete all your data, use the \"Delete Account\" option in the Support tab, which permanently removes all your Peeply data from your device. You may also email us at support@peeply.app to request data deletion.")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                        .lineSpacing(4)
                }
                
                // iOS Contacts Permission
                VStack(alignment: .leading, spacing: 12) {
                    Text("iOS Contacts Permission")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                    
                    Text("Peeply requests access to your iOS Contacts to enable the import feature. This permission is entirely optional. You can revoke it at any time in iPhone Settings > Privacy & Security > Contacts.")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                        .lineSpacing(4)
                }
                
                // Children's Privacy
                VStack(alignment: .leading, spacing: 12) {
                    Text("Children's Privacy")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                    
                    Text("Peeply is not directed at children under 13 and does not knowingly collect data from children.")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                        .lineSpacing(4)
                }
                
                // Changes to This Policy
                VStack(alignment: .leading, spacing: 12) {
                    Text("Changes to This Policy")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                    
                    Text("If we update this policy, we will revise the date above. Continued use of the app constitutes acceptance of any changes.")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                        .lineSpacing(4)
                }
                
                // Contact
                VStack(alignment: .leading, spacing: 12) {
                    Text("Contact")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                    
                    Text("Questions or data deletion requests: support@peeply.app")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                        .lineSpacing(4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.peeplyBackground)
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
