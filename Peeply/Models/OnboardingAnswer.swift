//
//  OnboardingAnswer.swift
//  Peeply
//
//  Created by Jason LaChance on 1/18/26.
//

import Foundation
import SwiftData

@Model
final class OnboardingAnswer {
    var id: UUID
    var questionId: String
    var answer: String
    var userId: UUID
    
    init(
        id: UUID = UUID(),
        questionId: String,
        answer: String,
        userId: UUID
    ) {
        self.id = id
        self.questionId = questionId
        self.answer = answer
        self.userId = userId
    }
}
