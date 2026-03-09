//
//  PersonOfTheDayView.swift
//  Peeply
//
//  Created by Jason LaChance on 1/18/26.
//

import SwiftUI

struct PersonOfTheDayView: View {
    let contact: Contact
    let onDismiss: () -> Void
    @Environment(\.openURL) private var openURL
    
    private var fullName: String {
        if let lastName = contact.lastName, !lastName.isEmpty {
            return "\(contact.firstName) \(lastName)"
        } else {
            return contact.firstName
        }
    }
    
    private var initials: String {
        let firstInitial = contact.firstName.prefix(1).uppercased()
        let lastInitial = contact.lastName?.prefix(1).uppercased() ?? ""
        return "\(firstInitial)\(lastInitial)"
    }
    
    private var contactPhoto: UIImage? {
        guard let photoData = contact.photoData else { return nil }
        return UIImage(data: photoData)
    }
    
    private var primaryPhoneNumber: String? {
        contact.phoneNumbers.first
    }
    
    private func cleanPhoneNumber(_ phoneNumber: String) -> String {
        return phoneNumber.replacingOccurrences(
            of: "[^0-9+]",
            with: "",
            options: .regularExpression
        )
    }
    
    private func callPhone(_ phoneNumber: String) {
        let cleaned = cleanPhoneNumber(phoneNumber)
        if let url = URL(string: "tel://\(cleaned)") {
            openURL(url)
        }
    }
    
    private func sendMessage(_ phoneNumber: String) {
        let cleaned = cleanPhoneNumber(phoneNumber)
        if let url = URL(string: "sms://\(cleaned)") {
            openURL(url)
        }
    }
    
    var body: some View {
        ZStack {
            Color.peeplyBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Dismiss button (top-right)
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.peeplyCharcoal.opacity(0.6))
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }
                
                Spacer()
                
                // Content
                VStack(spacing: 32) {
                    // Headline
                    Text("Your Peeply Person of the Day!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.peeplyCharcoal)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    // Contact photo or initials
                    if let photo = contactPhoto {
                        Image(uiImage: photo)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.peeplyRose, Color.peeplyLavender],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 4
                                    )
                            )
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.peeplyRose, Color.peeplyLavender],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .overlay(
                                Text(initials)
                                    .font(.system(size: 48, weight: .semibold))
                                    .foregroundStyle(Color.peeplyWhite)
                            )
                    }
                    
                    // Contact name
                    Text(fullName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.peeplyCharcoal)
                    
                    // Phone number
                    if let phoneNumber = primaryPhoneNumber {
                        Text(phoneNumber)
                            .font(.body)
                            .foregroundStyle(Color.peeplyCharcoal.opacity(0.7))
                            .padding(.bottom, 8)
                    }
                    
                    // Action buttons
                    if let phoneNumber = primaryPhoneNumber {
                        HStack(spacing: 16) {
                            // Call button
                            Button(action: {
                                callPhone(phoneNumber)
                                onDismiss()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "phone.fill")
                                    Text("Call")
                                }
                                .font(.headline)
                                .foregroundStyle(Color.peeplyWhite)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [Color.peeplyRose, Color.peeplyLavender],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                            }
                            
                            // Text button
                            Button(action: {
                                sendMessage(phoneNumber)
                                onDismiss()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "message.fill")
                                    Text("Text")
                                }
                                .font(.headline)
                                .foregroundStyle(Color.peeplyCharcoal)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.peeplyWhite)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.peeplyRose, Color.peeplyLavender],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                }
                .padding(.vertical, 40)
                
                Spacer()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    PersonOfTheDayView(
        contact: Contact(
            firstName: "John",
            lastName: "Doe",
            phoneNumbers: ["(555) 123-4567"]
        ),
        onDismiss: {}
    )
}
