package com.amit.vamk.data

import com.amit.vamk.models.Article
import com.amit.vamk.models.Category
import com.amit.vamk.models.CreateArticleRequest
import com.amit.vamk.models.UpdateArticleRequest
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

/**
 * In-memory repository for articles
 * Thread-safe implementation using ConcurrentHashMap
 */
object ArticleRepository {
    private val articles = ConcurrentHashMap<String, Article>()
    private val categories = ConcurrentHashMap<String, Category>()
    
    init {
        // Initialize with mock data
        initializeCategories()
        initializeMockArticles()
    }
    
    /**
     * Initialize categories
     */
    private fun initializeCategories() {
        val categoryList = listOf(
            Category("1", "Technology", "Latest tech news and innovations"),
            Category("2", "Science", "Scientific discoveries and research"),
            Category("3", "Business", "Business news and market updates"),
            Category("4", "Health", "Health and wellness information"),
            Category("5", "Sports", "Sports news and updates"),
            Category("6", "Entertainment", "Entertainment and celebrity news")
        )
        
        categoryList.forEach { category ->
            categories[category.id] = category
        }
    }
    
    /**
     * Initialize mock articles for testing
     */
    private fun initializeMockArticles() {
        val baseTime = System.currentTimeMillis()
        val mockArticles = mutableListOf<Article>()
        
        // Technology articles
        repeat(20) { index ->
            mockArticles.add(
                Article(
                    id = "tech-${index + 1}",
                    title = "Breaking: New AI Development Revolutionizes ${getTechTopic(index)}",
                    content = generateArticleContent("Technology", index),
                    summary = "Researchers announce groundbreaking advancement in artificial intelligence that could transform ${getTechTopic(index)} industry.",
                    imageUrl = "https://picsum.photos/800/600?random=tech${index + 1}",
                    author = getAuthor(index),
                    publishedAt = baseTime - (index * 3600000), // 1 hour apart
                    category = "Technology",
                    readTimeMinutes = (3..10).random(),
                    tags = listOf("AI", "Technology", "Innovation", getTechTopic(index))
                )
            )
        }
        
        // Science articles
        repeat(15) { index ->
            mockArticles.add(
                Article(
                    id = "sci-${index + 1}",
                    title = "Scientists Discover New ${getScienceTopic(index)} Breakthrough",
                    content = generateArticleContent("Science", index),
                    summary = "International team of researchers makes unprecedented discovery in ${getScienceTopic(index)} field.",
                    imageUrl = "https://picsum.photos/800/600?random=sci${index + 1}",
                    author = getAuthor(index + 20),
                    publishedAt = baseTime - ((index + 20) * 3600000),
                    category = "Science",
                    readTimeMinutes = (5..12).random(),
                    tags = listOf("Science", "Research", getScienceTopic(index))
                )
            )
        }
        
        // Business articles
        repeat(15) { index ->
            mockArticles.add(
                Article(
                    id = "biz-${index + 1}",
                    title = "${getCompany(index)} Announces Major ${getBusinessTopic(index)} Initiative",
                    content = generateArticleContent("Business", index),
                    summary = "Leading company reveals strategic plans for ${getBusinessTopic(index)} expansion in global markets.",
                    imageUrl = "https://picsum.photos/800/600?random=biz${index + 1}",
                    author = getAuthor(index + 35),
                    publishedAt = baseTime - ((index + 35) * 3600000),
                    category = "Business",
                    readTimeMinutes = (4..8).random(),
                    tags = listOf("Business", "Finance", getBusinessTopic(index))
                )
            )
        }
        
        // Health articles
        repeat(10) { index ->
            mockArticles.add(
                Article(
                    id = "health-${index + 1}",
                    title = "New Study Reveals ${getHealthTopic(index)} Benefits",
                    content = generateArticleContent("Health", index),
                    summary = "Medical researchers publish findings on the positive effects of ${getHealthTopic(index)} on overall wellness.",
                    imageUrl = "https://picsum.photos/800/600?random=health${index + 1}",
                    author = getAuthor(index + 50),
                    publishedAt = baseTime - ((index + 50) * 3600000),
                    category = "Health",
                    readTimeMinutes = (6..10).random(),
                    tags = listOf("Health", "Wellness", getHealthTopic(index))
                )
            )
        }
        
        // Sports articles
        repeat(10) { index ->
            mockArticles.add(
                Article(
                    id = "sport-${index + 1}",
                    title = "${getSportsTeam(index)} Wins Championship in ${getSportType(index)}",
                    content = generateArticleContent("Sports", index),
                    summary = "Historic victory as ${getSportsTeam(index)} clinches championship title in thrilling final match.",
                    imageUrl = "https://picsum.photos/800/600?random=sport${index + 1}",
                    author = getAuthor(index + 60),
                    publishedAt = baseTime - ((index + 60) * 3600000),
                    category = "Sports",
                    readTimeMinutes = (3..7).random(),
                    tags = listOf("Sports", getSportType(index), "Championship")
                )
            )
        }
        
        // Entertainment articles
        repeat(10) { index ->
            mockArticles.add(
                Article(
                    id = "ent-${index + 1}",
                    title = "Award-Winning ${getEntertainmentType(index)} Set for Release",
                    content = generateArticleContent("Entertainment", index),
                    summary = "Highly anticipated ${getEntertainmentType(index)} from acclaimed creators debuts this season.",
                    imageUrl = "https://picsum.photos/800/600?random=ent${index + 1}",
                    author = getAuthor(index + 70),
                    publishedAt = baseTime - ((index + 70) * 3600000),
                    category = "Entertainment",
                    readTimeMinutes = (4..8).random(),
                    tags = listOf("Entertainment", getEntertainmentType(index), "Media")
                )
            )
        }
        
        // Add all articles to repository
        mockArticles.forEach { article ->
            articles[article.id] = article
        }
        
        updateCategoryCounts()
    }
    
    // Helper functions for generating diverse content
    private fun getTechTopic(index: Int): String {
        val topics = listOf("Machine Learning", "Quantum Computing", "Robotics", "Cybersecurity", 
            "Cloud Computing", "IoT", "Blockchain", "5G Networks", "Autonomous Vehicles", "AR/VR")
        return topics[index % topics.size]
    }
    
    private fun getScienceTopic(index: Int): String {
        val topics = listOf("Climate Science", "Genetics", "Space Exploration", "Nanotechnology",
            "Neuroscience", "Physics", "Marine Biology", "Astronomy", "Chemistry", "Ecology")
        return topics[index % topics.size]
    }
    
    private fun getBusinessTopic(index: Int): String {
        val topics = listOf("Digital Transformation", "Sustainability", "Market Expansion",
            "Innovation", "Partnership", "Investment", "Growth Strategy", "Merger", "IPO", "Acquisition")
        return topics[index % topics.size]
    }
    
    private fun getHealthTopic(index: Int): String {
        val topics = listOf("Exercise", "Meditation", "Nutrition", "Sleep", "Mental Health",
            "Preventive Care", "Healthy Aging", "Stress Management", "Immunity", "Fitness")
        return topics[index % topics.size]
    }
    
    private fun getSportsTeam(index: Int): String {
        val teams = listOf("Thunder", "Eagles", "Lions", "Tigers", "Warriors", "Knights",
            "Dragons", "Falcons", "Sharks", "Phoenix")
        return teams[index % teams.size]
    }
    
    private fun getSportType(index: Int): String {
        val sports = listOf("Basketball", "Football", "Soccer", "Tennis", "Baseball",
            "Hockey", "Rugby", "Cricket", "Golf", "Swimming")
        return sports[index % sports.size]
    }
    
    private fun getEntertainmentType(index: Int): String {
        val types = listOf("Film", "Series", "Album", "Concert Tour", "Documentary",
            "Podcast", "Game", "Musical", "Art Exhibition", "Book")
        return types[index % types.size]
    }
    
    private fun getCompany(index: Int): String {
        val companies = listOf("TechCorp", "InnovateTech", "FutureSync", "GlobalTech",
            "NextGen Industries", "Pioneer Systems", "Quantum Labs", "Synergy Group",
            "Nexus Technologies", "Apex Solutions")
        return companies[index % companies.size]
    }
    
    private fun getAuthor(index: Int): String {
        val authors = listOf(
            "Sarah Johnson", "Michael Chen", "Emma Williams", "David Garcia",
            "Lisa Anderson", "James Martinez", "Maria Rodriguez", "Robert Taylor",
            "Jennifer Lee", "William Brown", "Patricia Wilson", "Richard Moore",
            "Linda Davis", "Thomas Jackson", "Barbara White", "Christopher Harris",
            "Nancy Martin", "Daniel Thompson", "Karen Garcia", "Matthew Martinez"
        )
        return authors[index % authors.size]
    }
    
    private fun generateArticleContent(category: String, index: Int): String {
        return """
            This is a comprehensive article about ${category.lowercase()} topic number ${index + 1}.
            
            ## Introduction
            
            In recent developments, experts have made significant progress in understanding and advancing this field. 
            This breakthrough represents a major milestone in ${category.lowercase()} research and development.
            
            ## Key Findings
            
            The research team conducted extensive analysis over several months, gathering data from multiple sources 
            and collaborating with international partners. Their findings reveal important insights that could 
            reshape our understanding of this domain.
            
            ### Impact on Industry
            
            Industry leaders are already taking notice of these developments. Several major companies have announced 
            plans to integrate these findings into their operations, potentially transforming how they approach 
            ${category.lowercase()} challenges.
            
            ### Future Implications
            
            Looking ahead, experts predict that these advances will continue to influence the field for years to come. 
            The potential applications are vast, ranging from immediate practical uses to long-term strategic planning.
            
            ## Expert Opinions
            
            Leading researchers in the field have praised the work, noting its methodological rigor and innovative 
            approach. "This represents a significant step forward," noted one prominent expert. "The implications 
            for future research are profound."
            
            ## Conclusion
            
            As we continue to explore these developments, it's clear that the intersection of research, innovation, 
            and practical application will drive progress in ${category.lowercase()}. The coming months will likely 
            bring even more exciting discoveries and opportunities for advancement.
            
            Stay tuned for more updates as this story develops.
        """.trimIndent()
    }
    
    private fun updateCategoryCounts() {
        categories.values.forEach { category ->
            val count = articles.values.count { it.category == category.name }
            categories[category.id] = category.copy(articleCount = count)
        }
    }
    
    // CRUD Operations
    
    /**
     * Get all articles with pagination
     */
    fun getArticles(page: Int = 1, pageSize: Int = 20, category: String? = null): List<Article> {
        val filtered = if (category != null) {
            articles.values.filter { it.category == category }
        } else {
            articles.values.toList()
        }
        
        val sorted = filtered.sortedByDescending { it.publishedAt }
        val startIndex = (page - 1) * pageSize
        
        return if (startIndex >= sorted.size) {
            emptyList()
        } else {
            sorted.drop(startIndex).take(pageSize)
        }
    }
    
    /**
     * Get total number of articles
     */
    fun getTotalArticles(category: String? = null): Int {
        return if (category != null) {
            articles.values.count { it.category == category }
        } else {
            articles.size
        }
    }
    
    /**
     * Get article by ID
     */
    fun getArticleById(id: String): Article? {
        return articles[id]
    }
    
    /**
     * Create new article
     */
    fun createArticle(request: CreateArticleRequest, imageUrl: String? = null): Article {
        val id = UUID.randomUUID().toString()
        val article = Article(
            id = id,
            title = request.title,
            content = request.content,
            summary = request.summary,
            imageUrl = imageUrl,
            author = request.author,
            publishedAt = System.currentTimeMillis(),
            category = request.category,
            readTimeMinutes = request.readTimeMinutes,
            tags = request.tags
        )
        
        articles[id] = article
        updateCategoryCounts()
        
        return article
    }
    
    /**
     * Update existing article
     */
    fun updateArticle(id: String, request: UpdateArticleRequest): Article? {
        val existing = articles[id] ?: return null
        
        val updated = existing.copy(
            title = request.title ?: existing.title,
            content = request.content ?: existing.content,
            summary = request.summary ?: existing.summary,
            author = request.author ?: existing.author,
            category = request.category ?: existing.category,
            readTimeMinutes = request.readTimeMinutes ?: existing.readTimeMinutes,
            tags = request.tags ?: existing.tags
        )
        
        articles[id] = updated
        updateCategoryCounts()
        
        return updated
    }
    
    /**
     * Delete article
     */
    fun deleteArticle(id: String): Boolean {
        val removed = articles.remove(id) != null
        if (removed) {
            updateCategoryCounts()
        }
        return removed
    }
    
    /**
     * Get all categories
     */
    fun getCategories(): List<Category> {
        return categories.values.toList()
    }
    
    /**
     * Get category by name
     */
    fun getCategoryByName(name: String): Category? {
        return categories.values.find { it.name.equals(name, ignoreCase = true) }
    }
    
    /**
     * Search articles by query
     */
    fun searchArticles(query: String, page: Int = 1, pageSize: Int = 20): List<Article> {
        val filtered = articles.values.filter { article ->
            article.title.contains(query, ignoreCase = true) ||
            article.content.contains(query, ignoreCase = true) ||
            article.summary.contains(query, ignoreCase = true) ||
            article.tags.any { it.contains(query, ignoreCase = true) }
        }
        
        val sorted = filtered.sortedByDescending { it.publishedAt }
        val startIndex = (page - 1) * pageSize
        
        return if (startIndex >= sorted.size) {
            emptyList()
        } else {
            sorted.drop(startIndex).take(pageSize)
        }
    }
}
