//
//  ArticleCategory.swift
//  IosNativeBuild
//
//  Domain Model for Article Categories
//

import Foundation

enum ArticleCategory: String, Codable, CaseIterable, Identifiable {
    case technology = "TECHNOLOGY"
    case business = "BUSINESS"
    case entertainment = "ENTERTAINMENT"
    case sports = "SPORTS"
    case science = "SCIENCE"
    case health = "HEALTH"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .technology: return "Technology"
        case .business: return "Business"
        case .entertainment: return "Entertainment"
        case .sports: return "Sports"
        case .science: return "Science"
        case .health: return "Health"
        }
    }

    static func fromString(_ value: String) -> ArticleCategory {
        return ArticleCategory(rawValue: value.uppercased()) ?? .technology
    }
}