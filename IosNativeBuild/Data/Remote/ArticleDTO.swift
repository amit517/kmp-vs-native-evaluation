//
//  ArticleDTO.swift
//  IosNativeBuild
//
//  Data Transfer Objects for API
//

import Foundation

struct ArticleDTO: Codable {
    let id: String
    let title: String
    let content: String
    let summary: String
    let imageUrl: String?
    let author: String
    let publishedAt: Int64  // Timestamp in milliseconds
    let category: String
    let readTimeMinutes: Int
    let tags: [String]
}

struct ArticlesResponse: Codable {
    let articles: [ArticleDTO]
    let page: Int
    let pageSize: Int
    let totalPages: Int
    let totalArticles: Int
}