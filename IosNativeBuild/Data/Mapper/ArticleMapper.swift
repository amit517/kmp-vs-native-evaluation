//
//  ArticleMapper.swift
//  IosNativeBuild
//
//  Maps between DTOs and Domain Models
//

import Foundation

struct ArticleMapper {
    static func toDomain(_ dto: ArticleDTO) -> Article {
        // Convert timestamp (milliseconds) to Date
        let date = Date(timeIntervalSince1970: TimeInterval(dto.publishedAt) / 1000.0)

        return Article(
            id: dto.id,
            title: dto.title,
            content: dto.content,
            summary: dto.summary,
            imageUrl: dto.imageUrl,
            author: dto.author,
            publishedAt: date,
            category: ArticleCategory.fromString(dto.category),
            readTimeMinutes: dto.readTimeMinutes,
            tags: dto.tags,
            isFavorite: false
        )
    }

    static func toDomainList(_ dtos: [ArticleDTO]) -> [Article] {
        return dtos.map { toDomain($0) }
    }
}