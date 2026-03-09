//
//  PlanSelectionView.swift
//  Peeply
//
//  Created by Jason LaChance on 1/18/26.
//

import SwiftUI

struct PlanSelectionView: View {
    @Binding var navigationPath: NavigationPath
    @State private var selectedPlanName: String?
    @State private var selectedPlanPrice: String?
    @State private var showConfirmationAlert = false
    
    var body: some View {
        ZStack {
            Color.peeplyBackground
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    // Screen title
                    Text("Choose your Peeply Plan")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.peeplyCharcoal)
                        .padding(.top, 32)
                        .padding(.bottom, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Plan cards
                    VStack(spacing: 16) {
                        PlanCard(
                            planName: "Getting Started",
                            price: "$10",
                            billingPeriod: "month",
                            showCancelAnytime: true,
                            isMostPopular: false
                        ) {
                            selectedPlanName = "Getting Started"
                            selectedPlanPrice = "$10/month"
                            showConfirmationAlert = true
                        }
                        
                        PlanCard(
                            planName: "Most Popular",
                            price: "$80",
                            billingPeriod: "year",
                            showCancelAnytime: true,
                            isMostPopular: true
                        ) {
                            selectedPlanName = "Most Popular"
                            selectedPlanPrice = "$80/year"
                            showConfirmationAlert = true
                        }
                        
                        PlanCard(
                            planName: "Lifetime",
                            price: "$200",
                            billingPeriod: "one time",
                            showCancelAnytime: false,
                            isMostPopular: false
                        ) {
                            selectedPlanName = "Lifetime"
                            selectedPlanPrice = "$200 one time"
                            showConfirmationAlert = true
                        }
                    }
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle("Plan Selection")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbarBackground(Color.peeplyWhite, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            // Set navigation title color
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.peeplyWhite)
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.peeplyCharcoal)]
            appearance.titleTextAttributes = [.foregroundColor: UIColor(Color.peeplyCharcoal)]
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
        }
        .alert("Confirm Purchase", isPresented: $showConfirmationAlert) {
            Button("Cancel", role: .cancel) {
                selectedPlanName = nil
                selectedPlanPrice = nil
            }
            Button("Confirm") {
                navigationPath.append(AppRoute.onboarding)
                selectedPlanName = nil
                selectedPlanPrice = nil
            }
            .tint(Color.peeplyLavender)
        } message: {
            if let planName = selectedPlanName, let planPrice = selectedPlanPrice {
                Text("\(planName) - \(planPrice)")
            }
        }
    }
}

struct PlanCard: View {
    let planName: String
    let price: String
    let billingPeriod: String
    let showCancelAnytime: Bool
    let isMostPopular: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // Plan name
                    Text(planName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    // Most Popular badge
                    if isMostPopular {
                        Text("Most Popular")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.peeplyWhite)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.peeplyLavender)
                            .clipShape(Capsule())
                    }
                }
                
                // Price and billing period
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(price)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("/\(billingPeriod)")
                        .font(.subheadline)
                        .foregroundStyle(Color.peeplyCharcoal.opacity(0.6))
                }
                
                // Cancel anytime text
                if showCancelAnytime {
                    Text("*cancel anytime")
                        .font(.caption)
                        .foregroundStyle(Color.peeplyCharcoal.opacity(0.6))
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color.peeplyCream, Color.peeplyRose.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.peeplyRose.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        PlanSelectionView(navigationPath: .constant(NavigationPath()))
    }
}
