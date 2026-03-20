//
//  OnboardingView.swift
//  Peeply
//
//  Created by Jason LaChance on 1/18/26.
//

import SwiftUI
import UIKit

struct OnboardingView: View {
    @Binding var navigationPath: NavigationPath
    @State private var showWelcome = true
    @State private var currentQuestionIndex = 0
    
    private let questions = [
        "Question 1",
        "Question 2",
        "Question 3",
        "Question 4",
        "Question 5",
        "Question 6",
        "Question 7",
        "Question 8",
        "Question 9",
        "Question 10"
    ]
    
    private var currentQuestion: String {
        questions[currentQuestionIndex]
    }
    
    private var isLastQuestion: Bool {
        currentQuestionIndex == questions.count - 1
    }
    
    private func startQuestions() {
        showWelcome = false
    }
    
    private func answerQuestion() {
        if isLastQuestion {
            navigateToContactImport()
        } else {
            currentQuestionIndex += 1
        }
    }
    
    private func skipQuestion() {
        if isLastQuestion {
            navigateToContactImport()
        } else {
            currentQuestionIndex += 1
        }
    }
    
    private func skipOnboarding() {
        navigateToContactImport()
    }
    
    private func navigateToContactImport() {
        navigationPath.append(AppRoute.contactImport)
    }
    
    var body: some View {
        ZStack {
            Color.peeplyBackground
                .ignoresSafeArea()
            if showWelcome {
                welcomeView
            } else {
                questionView
            }
        }
    }
    
    private var welcomeView: some View {
        VStack(spacing: 0) {
            // Welcome content - top third of page
            VStack(spacing: 32) {
                // Large SF Symbol icon
                Image(systemName: "person.2.circle.fill")
                    .font(.system(size: 90))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.peeplyRose, Color.peeplyLavender],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Welcome text
                Text("We want to get to know you first to customize your experience!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(red: 250/255, green: 172/255, blue: 167/255))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 56)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity, alignment: .top)
            
            Spacer()
            
            // Get Started button
            Button(action: startQuestions) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundStyle(Color.peeplyWhite)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.peeplyCharcoal)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .navigationTitle("Onboarding")
        .navigationBarTitleDisplayMode(.inline)
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
    }
    
    private var questionView: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack {
                Spacer()
                Text("Question \(currentQuestionIndex + 1) of \(questions.count)")
                    .font(.subheadline)
                    .foregroundStyle(Color.peeplyCharcoal.opacity(0.6))
                    .padding(.top, 16)
                    .padding(.trailing, 20)
            }
            
            Spacer()
            
            // Question text
            Text(currentQuestion)
                .font(.title)
                .fontWeight(.semibold)
                .foregroundStyle(Color.peeplyCharcoal)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
            
            Spacer()
            
            // Answer buttons
            VStack(spacing: 16) {
                Button(action: answerQuestion) {
                    Text("Yes")
                        .font(.headline)
                        .foregroundStyle(Color.peeplyWhite)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [Color.peeplyRose, Color.peeplyLavender],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                }
                
                Button(action: answerQuestion) {
                    Text("No")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(.bordered)
                .tint(Color.peeplyLavender)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<questions.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentQuestionIndex ? Color.peeplyLavender : Color.peeplyCharcoal.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 16)
            
            // Navigation buttons
            HStack {
                // Skip Onboarding button
                Button(action: skipOnboarding) {
                    Text("Skip Onboarding")
                        .font(.subheadline)
                        .foregroundStyle(Color.peeplyCharcoal.opacity(0.6))
                }
                
                Spacer()
                
                // Skip Question button
                Button(action: skipQuestion) {
                    Text("Skip Question")
                        .font(.subheadline)
                        .foregroundStyle(Color.peeplyCharcoal.opacity(0.6))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .navigationTitle("Onboarding")
        .navigationBarTitleDisplayMode(.inline)
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
    }
}

#Preview {
    NavigationStack {
        OnboardingView(navigationPath: .constant(NavigationPath()))
    }
}
