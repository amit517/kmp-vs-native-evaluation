//
//  Theme.swift
//  IosNativeBuild
//
//  App Theme Configuration
//

import SwiftUI

struct AppTheme {
    // Primary Colors
    static let primary = Color(hex: "1976D2")
    static let primaryVariant = Color(hex: "1565C0")
    static let onPrimary = Color.white

    // Secondary Colors
    static let secondary = Color(hex: "03A9F4")
    static let secondaryVariant = Color(hex: "0288D1")
    static let onSecondary = Color.white

    // Background Colors
    static let background = Color(hex: "FAFAFA")
    static let surface = Color.white
    static let onBackground = Color(hex: "212121")
    static let onSurface = Color(hex: "212121")

    // Error Colors
    static let error = Color(hex: "D32F2F")
    static let onError = Color.white

    // Dark Theme Colors
    static let darkPrimary = Color(hex: "90CAF9")
    static let darkBackground = Color(hex: "121212")
    static let darkSurface = Color(hex: "1E1E1E")
    static let darkOnBackground = Color(hex: "E0E0E0")
    static let darkOnSurface = Color(hex: "E0E0E0")

    // Category Colors
    static let technologyColor = Color(hex: "2196F3")
    static let businessColor = Color(hex: "4CAF50")
    static let entertainmentColor = Color(hex: "FF9800")
    static let sportsColor = Color(hex: "F44336")
    static let scienceColor = Color(hex: "9C27B0")
    static let healthColor = Color(hex: "E91E63")

    static func categoryColor(for category: ArticleCategory) -> Color {
        switch category {
        case .technology: return technologyColor
        case .business: return businessColor
        case .entertainment: return entertainmentColor
        case .sports: return sportsColor
        case .science: return scienceColor
        case .health: return healthColor
        }
    }
}

// Color extension for hex values
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}