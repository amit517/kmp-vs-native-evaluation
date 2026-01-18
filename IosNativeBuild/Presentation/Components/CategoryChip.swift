//
//  CategoryChip.swift
//  IosNativeBuild
//
//  Category Filter Chip Component
//

import SwiftUI

struct CategoryChip: View {
    let category: ArticleCategory?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(category?.displayName ?? "All")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ?
                    (category != nil ? AppTheme.categoryColor(for: category!) : AppTheme.primary) :
                    Color.gray.opacity(0.2)
                )
                .foregroundColor(isSelected ? .white : AppTheme.onSurface)
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}