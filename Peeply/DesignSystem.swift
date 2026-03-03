//
//  DesignSystem.swift
//  Peeply
//
//  Created by Jason LaChance on 1/18/26.
//

import SwiftUI

struct DesignSystem {
    // MARK: - Colors
    // Reference colors from PeeplyColors.swift
    static let cream = Color.peeplyCream
    static let background = Color.peeplyBackground
    static let rose = Color.peeplyRose
    static let lavender = Color.peeplyLavender
    static let charcoal = Color.peeplyCharcoal
    static let white = Color.peeplyWhite
    
    // MARK: - Typography
    struct Typography {
        static let h1 = Font.system(size: 20, weight: .medium, design: .default)
        static let h2 = Font.system(size: 16, weight: .medium, design: .default)
        static let body = Font.system(size: 14, weight: .regular, design: .default)
        static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let standard: CGFloat = 12
        static let ellipsesSpacing: CGFloat = 20
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let card: CGFloat = 20
        static let ellipses: CGFloat = 30
        static let button: CGFloat = 44
        static let navigationButton: CGFloat = 52
        static let inputCard: CGFloat = 24
    }
    
    // MARK: - Sizes
    struct Sizes {
        static let ellipsesSize: CGFloat = 52
        static let searchIcon: CGFloat = 20
        static let cardIcon: CGFloat = 24
        static let navigationIcon: CGFloat = 24
    }
}
