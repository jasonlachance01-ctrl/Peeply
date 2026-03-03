//
//  TermsOfServiceView.swift
//  Peeply
//
//  Created by Jason LaChance on 1/18/26.
//

import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Title
                Text("Peeply Terms of Service")
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundStyle(Color.peeplyCharcoal)
                    .padding(.top, 20)
                
                // Subtitle
                Text("Last updated: February 2026")
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundStyle(Color.peeplyCharcoal.opacity(0.6))
                
                // About Peeply
                VStack(alignment: .leading, spacing: 12) {
                    Text("About Peeply")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                    
                    Text("Peeply is a personal relationship management app designed to help individuals maintain consistent, meaningful connections with the people in their lives. By using Peeply, you agree to these terms.")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                        .lineSpacing(4)
                }
                
                // Acceptable Use
                VStack(alignment: .leading, spacing: 12) {
                    Text("Acceptable Use")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                    
                    Text("Peeply is intended for personal, non-commercial use. You agree to use it lawfully and only for its intended purpose — managing your own personal relationships and contacts.")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                        .lineSpacing(4)
                }
                
                // Your Data
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Data")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                    
                    Text("You own your data entirely. Peeply claims no rights to your contacts or any information you enter. See our Privacy Policy for full details on how your data is handled.")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                        .lineSpacing(4)
                }
                
                // Subscriptions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Subscriptions")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                    
                    Text("Peeply subscriptions are managed through Apple's App Store and subject to Apple billing terms. You may cancel at any time through your iPhone Settings.")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                        .lineSpacing(4)
                }
                
                // Account Deletion
                VStack(alignment: .leading, spacing: 12) {
                    Text("Account Deletion")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                    
                    Text("You may delete your account and all associated data at any time using the \"Delete Account\" option in the Support tab of the app.")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                        .lineSpacing(4)
                }
                
                // Disclaimer
                VStack(alignment: .leading, spacing: 12) {
                    Text("Disclaimer")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                    
                    Text("Peeply is provided as-is. We make no guarantees of uninterrupted service and are not liable for any loss of data or damages arising from use of the app.")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                        .lineSpacing(4)
                }
                
                // Changes to These Terms
                VStack(alignment: .leading, spacing: 12) {
                    Text("Changes to These Terms")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                    
                    Text("We may update these terms occasionally. The date above reflects the most recent revision. Continued use of the app means you accept any updates.")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                        .lineSpacing(4)
                }
                
                // Contact
                VStack(alignment: .leading, spacing: 12) {
                    Text("Contact")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                    
                    Text("Questions: support@peeply.app")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundStyle(Color.peeplyCharcoal)
                        .lineSpacing(4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.peeplyBackground)
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        TermsOfServiceView()
    }
}
