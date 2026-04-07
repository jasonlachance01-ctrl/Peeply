//
//  OnboardingView.swift
//  Peeply
//
//  Created by Jason LaChance on 1/18/26.
//

import SwiftUI
import SwiftData
import UIKit

enum QuestionType {
    case textEntry
    case multipleChoice
}

struct OnboardingQuestion {
    let id: Int
    let question: String
    let subtitle: String?
    let type: QuestionType
    let answers: [String]
}

struct OnboardingView: View {
    @Binding var navigationPath: NavigationPath
    @Query private var users: [PeeplyUser]
    @Environment(\.modelContext) private var modelContext
    @State private var showWelcome = true
    @State private var currentQuestionIndex = 0
    @State private var emailInput = ""
    
    private var currentUser: PeeplyUser? {
        users.first
    }
    
    private let questions: [OnboardingQuestion] = [
        OnboardingQuestion(
            id: 1,
            question: "What is your email address?",
            subtitle: "We won't over-communicate, but from time to time we may have something exciting to share!",
            type: .textEntry,
            answers: []
        ),
        OnboardingQuestion(
            id: 2,
            question: "Do you currently own your own business? (Affiliate, Consultant, Direct Sales, Independent Contractor)",
            subtitle: nil,
            type: .multipleChoice,
            answers: ["Yes", "No"]
        ),
        OnboardingQuestion(
            id: 3,
            question: "How many people do you typically speak with in a day about your product or business?",
            subtitle: nil,
            type: .multipleChoice,
            answers: ["0–1", "2–5", "6–10", "Over 10 per day"]
        ),
        OnboardingQuestion(
            id: 4,
            question: "How would you describe your follow-up habits today?",
            subtitle: nil,
            type: .multipleChoice,
            answers: ["I am great at follow-up", "I could definitely improve"]
        ),
        OnboardingQuestion(
            id: 5,
            question: "Which best describes you?",
            subtitle: nil,
            type: .multipleChoice,
            answers: ["Introvert", "Extrovert", "A mix, depending on the situation"]
        ),
        OnboardingQuestion(
            id: 6,
            question: "What communication method do you prefer most?",
            subtitle: nil,
            type: .multipleChoice,
            answers: ["Live, in-person conversation", "Phone conversations", "Voice messages (e.g. WhatsApp)", "Text messages", "FaceTime / video calls"]
        ),
        OnboardingQuestion(
            id: 7,
            question: "How many NEW people do you meet in an average month? Truly new people whom you did not know before.",
            subtitle: nil,
            type: .multipleChoice,
            answers: ["0–1", "2–5", "6–10", "More than 10"]
        ),
        OnboardingQuestion(
            id: 8,
            question: "Think of the 5 people who matter most to you. When did you last reach out to each of them — just to connect, not for a reason.",
            subtitle: nil,
            type: .multipleChoice,
            answers: ["Within the last week", "Within the last month", "I honestly can't remember"]
        ),
        OnboardingQuestion(
            id: 9,
            question: "When you think about your most meaningful relationships, what feels most true?",
            subtitle: nil,
            type: .multipleChoice,
            answers: ["I invest in them consistently", "I feel like I've let some drift"]
        ),
        OnboardingQuestion(
            id: 10,
            question: "If the people in your contacts list were asked if you consistently make them feel remembered and valued, what would they say today?",
            subtitle: nil,
            type: .multipleChoice,
            answers: ["Absolutely, without hesitation", "Mostly yes", "Honestly, probably not enough"]
        )
    ]
    
    private var currentQuestion: OnboardingQuestion {
        questions[currentQuestionIndex]
    }
    
    private var isLastQuestion: Bool {
        currentQuestionIndex == questions.count - 1
    }
    
    private func startQuestions() {
        if currentUser == nil {
            let newUser = PeeplyUser(email: "", subscriptionTier: .gettingStarted)
            modelContext.insert(newUser)
            try? modelContext.save()
        }
        showWelcome = false
    }
    
    private func answerQuestion() {
        if currentQuestion.type == .textEntry {
            currentUser?.email = emailInput
            try? modelContext.save()
        }
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
        currentUser?.onboardingCompleted = true
        try? modelContext.save()
        navigationPath = NavigationPath()
        navigationPath.append(AppRoute.planSelection)
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            if showWelcome {
                welcomeView
            } else {
                questionView
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private var welcomeView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Welcome content - top third of page
            VStack(spacing: 32) {
                // Welcome text
                Text("We want to get to know you first to customize your experience!")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 56)
            .frame(maxWidth: .infinity)
            
            Spacer()
            
            // Get Started button
            Button(action: startQuestions) {
                Text("Let's Go")
                    .font(.headline)
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.peeplyPink)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
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
            
            if currentQuestion.type == .textEntry {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        TextField("Email address", text: $emailInput)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .submitLabel(.next)
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                            .background(Color.peeplyWhite)
                            .cornerRadius(16)
                        
                        Button(action: answerQuestion) {
                            Image(systemName: "arrow.forward.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(Color.peeplyCharcoal)
                        }
                    }
                    
                    if let subtitle = currentQuestion.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Color.peeplyCharcoal.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            } else {
                // Question text
                Text(currentQuestion.question)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.peeplyCharcoal)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 24)
            }
            
            Spacer()
            
            // Answer buttons
            if currentQuestion.type != .textEntry {
                VStack(spacing: 16) {
                    ForEach(currentQuestion.answers, id: \.self) { answer in
                        Button(action: answerQuestion) {
                            Text(answer)
                                .font(.headline)
                                .foregroundStyle(Color.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.peeplyPink)
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            
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
    }
}

#Preview {
    NavigationStack {
        OnboardingView(navigationPath: .constant(NavigationPath()))
    }
}
