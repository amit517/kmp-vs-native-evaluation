//
//  ArticleMapper.swift
//  IosNativeBuild
//
//  Maps between DTOs and Domain Models
//

import Foundation

struct ArticleMapper {

    // MARK: - DTO -> Domain

    static func toDomain(_ dto: ArticleDTO) -> Article {
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

    // MARK: - DTO -> Entity

    static func toEntity(_ dto: ArticleDTO, isFavorite: Bool = false) -> ArticleEntity {
        return ArticleEntity(
            id: dto.id,
            title: dto.title,
            content: dto.content,
            summary: dto.summary,
            imageUrl: dto.imageUrl,
            author: dto.author,
            publishedAt: Double(dto.publishedAt),
            category: dto.category,
            readTimeMinutes: dto.readTimeMinutes,
            tags: dto.tags.joined(separator: ","),
            isFavorite: isFavorite,
            cachedAt: Date().timeIntervalSince1970 * 1000
        )
    }

    static func toEntityList(_ dtos: [ArticleDTO], isFavorite: Bool = false) -> [ArticleEntity] {
        return dtos.map { toEntity($0, isFavorite: isFavorite) }
    }

    // MARK: - Entity -> Domain

    static func toDomain(_ entity: ArticleEntity) -> Article {
        let date = Date(timeIntervalSince1970: entity.publishedAt / 1000.0)
        return Article(
            id: entity.id,
            title: entity.title,
            content: entity.content,
            summary: entity.summary,
            imageUrl: entity.imageUrl,
            author: entity.author,
            publishedAt: date,
            category: ArticleCategory.fromString(entity.category),
            readTimeMinutes: entity.readTimeMinutes,
            tags: entity.tags.isEmpty ? [] : entity.tags.components(separatedBy: ","),
            isFavorite: entity.isFavorite
        )
    }

    static func entityToDomainList(_ entities: [ArticleEntity]) -> [Article] {
        return entities.map { toDomain($0) }
    }

    // MARK: - Domain -> Entity

    static func toEntity(_ article: Article) -> ArticleEntity {
        return ArticleEntity(
            id: article.id,
            title: article.title,
            content: article.content,
            summary: article.summary,
            imageUrl: article.imageUrl,
            author: article.author,
            publishedAt: article.publishedAt.timeIntervalSince1970 * 1000,
            category: article.category.rawValue,
            readTimeMinutes: article.readTimeMinutes,
            tags: article.tags.joined(separator: ","),
            isFavorite: article.isFavorite,
            cachedAt: Date().timeIntervalSince1970 * 1000
        )
    }

    static func domainToEntityList(_ articles: [Article]) -> [ArticleEntity] {
        return articles.map { toEntity($0) }
    }
}