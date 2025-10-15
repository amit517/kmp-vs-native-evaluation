# API Documentation

## Base URL
```
http://localhost:8080/api
```

## Response Format
All responses are in JSON format. Errors follow this structure:
```json
{
  "error": "Error Type",
  "message": "Detailed error message",
  "statusCode": 400
}
```

---

## Articles Endpoints

### 1. List Articles (Paginated)

**GET** `/api/articles`

Get a paginated list of articles with optional filtering.

**Query Parameters:**
- `page` (optional, default: 1) - Page number
- `limit` (optional, default: 20, max: 100) - Articles per page
- `category` (optional) - Filter by category name
- `search` (optional) - Search in title, content, summary, and tags

**Example Requests:**
```bash
# Get first page (20 articles)
curl http://localhost:8080/api/articles

# Get page 2 with 10 articles per page
curl http://localhost:8080/api/articles?page=2&limit=10

# Filter by Technology category
curl http://localhost:8080/api/articles?category=Technology

# Search for AI articles
curl http://localhost:8080/api/articles?search=AI

# Combined: Technology articles, page 1, 15 per page
curl "http://localhost:8080/api/articles?category=Technology&page=1&limit=15"
```

**Response (200 OK):**
```json
{
  "articles": [
    {
      "id": "tech-1",
      "title": "Breaking: New AI Development...",
      "content": "Full article content...",
      "summary": "Article summary...",
      "imageUrl": "https://picsum.photos/800/600?random=tech1",
      "author": "Sarah Johnson",
      "publishedAt": 1704461940000,
      "category": "Technology",
      "readTimeMinutes": 5,
      "tags": ["AI", "Technology", "Innovation"]
    }
  ],
  "page": 1,
  "pageSize": 20,
  "totalPages": 4,
  "totalArticles": 80
}
```

---

### 2. Get Single Article

**GET** `/api/articles/{id}`

Get detailed information about a specific article.

**Path Parameters:**
- `id` (required) - Article ID

**Example Request:**
```bash
curl http://localhost:8080/api/articles/tech-1
```

**Response (200 OK):**
```json
{
  "id": "tech-1",
  "title": "Breaking: New AI Development...",
  "content": "Full article content with multiple paragraphs...",
  "summary": "Brief summary of the article...",
  "imageUrl": "https://picsum.photos/800/600?random=tech1",
  "author": "Sarah Johnson",
  "publishedAt": 1704461940000,
  "category": "Technology",
  "readTimeMinutes": 5,
  "tags": ["AI", "Technology", "Innovation"]
}
```

**Error (404 Not Found):**
```json
{
  "error": "Not Found",
  "message": "Article with ID 'invalid-id' not found",
  "statusCode": 404
}
```

---

### 3. Create Article

**POST** `/api/articles`

Create a new article.

**Request Body:**
```json
{
  "title": "My New Article",
  "content": "Full article content here...",
  "summary": "Brief summary of the article",
  "author": "John Doe",
  "category": "Technology",
  "readTimeMinutes": 7,
  "tags": ["Tech", "Innovation", "News"]
}
```

**Example Request:**
```bash
curl -X POST http://localhost:8080/api/articles \
  -H "Content-Type: application/json" \
  -d '{
    "title": "My New Article",
    "content": "This is the full content of my article...",
    "summary": "A brief summary",
    "author": "John Doe",
    "category": "Technology",
    "readTimeMinutes": 5,
    "tags": ["Tech", "News"]
  }'
```

**Response (201 Created):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "My New Article",
  "content": "This is the full content...",
  "summary": "A brief summary",
  "imageUrl": null,
  "author": "John Doe",
  "publishedAt": 1704461940000,
  "category": "Technology",
  "readTimeMinutes": 5,
  "tags": ["Tech", "News"]
}
```

**Validation Errors (400 Bad Request):**
```json
{
  "error": "Bad Request",
  "message": "Article title cannot be empty",
  "statusCode": 400
}
```

---

### 4. Update Article

**PUT** `/api/articles/{id}`

Update an existing article. All fields are optional.

**Path Parameters:**
- `id` (required) - Article ID

**Request Body:**
```json
{
  "title": "Updated Title",
  "content": "Updated content...",
  "summary": "Updated summary",
  "author": "Jane Doe",
  "category": "Science",
  "readTimeMinutes": 8,
  "tags": ["Updated", "Tags"]
}
```

**Example Request:**
```bash
curl -X PUT http://localhost:8080/api/articles/tech-1 \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Updated Article Title",
    "readTimeMinutes": 10
  }'
```

**Response (200 OK):**
Returns the updated article object.

**Error (404 Not Found):**
```json
{
  "error": "Not Found",
  "message": "Article with ID 'invalid-id' not found",
  "statusCode": 404
}
```

---

### 5. Delete Article

**DELETE** `/api/articles/{id}`

Delete an article.

**Path Parameters:**
- `id` (required) - Article ID

**Example Request:**
```bash
curl -X DELETE http://localhost:8080/api/articles/tech-1
```

**Response (200 OK):**
```json
{
  "message": "Article deleted successfully",
  "id": "tech-1"
}
```

**Error (404 Not Found):**
```json
{
  "error": "Not Found",
  "message": "Article with ID 'invalid-id' not found",
  "statusCode": 404
}
```

---

## Categories Endpoints

### 1. List Categories

**GET** `/api/categories`

Get all available categories with article counts.

**Example Request:**
```bash
curl http://localhost:8080/api/categories
```

**Response (200 OK):**
```json
[
  {
    "id": "1",
    "name": "Technology",
    "description": "Latest tech news and innovations",
    "articleCount": 20
  },
  {
    "id": "2",
    "name": "Science",
    "description": "Scientific discoveries and research",
    "articleCount": 15
  },
  {
    "id": "3",
    "name": "Business",
    "description": "Business news and market updates",
    "articleCount": 15
  },
  {
    "id": "4",
    "name": "Health",
    "description": "Health and wellness information",
    "articleCount": 10
  },
  {
    "id": "5",
    "name": "Sports",
    "description": "Sports news and updates",
    "articleCount": 10
  },
  {
    "id": "6",
    "name": "Entertainment",
    "description": "Entertainment and celebrity news",
    "articleCount": 10
  }
]
```

---

### 2. Get Articles by Category

**GET** `/api/categories/{name}/articles`

Get articles for a specific category with pagination.

**Path Parameters:**
- `name` (required) - Category name (e.g., "Technology", "Science")

**Query Parameters:**
- `page` (optional, default: 1) - Page number
- `limit` (optional, default: 20, max: 100) - Articles per page

**Example Request:**
```bash
curl http://localhost:8080/api/categories/Technology/articles?page=1&limit=10
```

**Response (200 OK):**
```json
{
  "category": {
    "id": "1",
    "name": "Technology",
    "description": "Latest tech news and innovations",
    "articleCount": 20
  },
  "articles": [...],
  "page": 1,
  "pageSize": 10,
  "totalPages": 2,
  "totalArticles": 20
}
```

**Error (404 Not Found):**
```json
{
  "error": "Not Found",
  "message": "Category 'InvalidCategory' not found",
  "statusCode": 404
}
```

---

## Health & Status Endpoints

### Health Check

**GET** `/health`

Check if the server is running.

**Response (200 OK):**
```json
{
  "status": "healthy",
  "timestamp": 1704461940000,
  "version": "1.0.0"
}
```

### API Status

**GET** `/api/status`

Get API status and available endpoints.

**Response (200 OK):**
```json
{
  "api": "KMP Research News Backend",
  "version": "1.0.0",
  "status": "operational",
  "endpoints": [
    {
      "method": "GET",
      "path": "/api/articles",
      "description": "List articles (paginated, filterable, searchable)"
    }
  ]
}
```

---

## Mock Data

The API includes 80 pre-generated articles:
- **Technology**: 20 articles
- **Science**: 15 articles
- **Business**: 15 articles
- **Health**: 10 articles
- **Sports**: 10 articles
- **Entertainment**: 10 articles

All articles have:
- Realistic titles and content
- Placeholder images from Picsum
- Multiple authors
- Tags for categorization
- Read time estimates

---

## Performance Notes

For research purposes, all endpoints include simulated network delays:
- GET requests: 30-50ms delay
- POST requests: 100ms delay
- PUT requests: 80ms delay
- DELETE requests: 50ms delay

This ensures realistic testing conditions for mobile app benchmarking.

---

## Testing with curl

```bash
# List all articles
curl http://localhost:8080/api/articles

# Get Technology articles
curl http://localhost:8080/api/articles?category=Technology

# Search for AI
curl http://localhost:8080/api/articles?search=AI

# Get single article
curl http://localhost:8080/api/articles/tech-1

# Create article
curl -X POST http://localhost:8080/api/articles \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","content":"Content","summary":"Summary","author":"Me","category":"Technology","readTimeMinutes":5}'

# Get all categories
curl http://localhost:8080/api/categories

# Get category articles
curl http://localhost:8080/api/categories/Technology/articles
```

---

## Error Handling

All errors return appropriate HTTP status codes:
- **400 Bad Request** - Invalid request parameters
- **404 Not Found** - Resource not found
- **409 Conflict** - Conflict with current state
- **500 Internal Server Error** - Server error

Error response format:
```json
{
  "error": "Error Type",
  "message": "Detailed error message",
  "statusCode": 400
}
```
