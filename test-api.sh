#!/bin/bash

# API Testing Script for KMP Research News Backend

BASE_URL="http://localhost:8080"
API_URL="$BASE_URL/api"

echo "================================================"
echo "KMP Research News Backend - API Testing"
echo "================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to test endpoint
test_endpoint() {
    local method=$1
    local endpoint=$2
    local description=$3
    local data=$4
    
    echo -e "${BLUE}Testing:${NC} $method $endpoint"
    echo "Description: $description"
    
    if [ -z "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X $method "$BASE_URL$endpoint")
    else
        response=$(curl -s -w "\n%{http_code}" -X $method "$BASE_URL$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data")
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ $http_code -ge 200 ] && [ $http_code -lt 300 ]; then
        echo -e "${GREEN}✅ Success${NC} (HTTP $http_code)"
    else
        echo -e "${RED}❌ Failed${NC} (HTTP $http_code)"
    fi
    
    echo "Response:"
    echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
    echo ""
    echo "---"
    echo ""
}

# Check if server is running
echo "🔍 Checking if server is running..."
if ! curl -s "$BASE_URL/health" > /dev/null 2>&1; then
    echo -e "${RED}❌ Server is not running on $BASE_URL${NC}"
    echo ""
    echo "Please start the server first:"
    echo "  ./gradlew run"
    echo ""
    exit 1
fi

echo -e "${GREEN}✅ Server is running${NC}"
echo ""
echo "================================================"
echo "Starting API Tests"
echo "================================================"
echo ""

# Test 1: Health Check
test_endpoint "GET" "/health" "Health check endpoint"

# Test 2: API Status
test_endpoint "GET" "/api/status" "API status and endpoints"

# Test 3: List all articles (first page)
test_endpoint "GET" "/api/articles" "List all articles (default pagination)"

# Test 4: List articles with custom pagination
test_endpoint "GET" "/api/articles?page=1&limit=5" "List 5 articles per page"

# Test 5: Filter by category
test_endpoint "GET" "/api/articles?category=Technology" "Filter by Technology category"

# Test 6: Search articles
test_endpoint "GET" "/api/articles?search=AI" "Search for 'AI' in articles"

# Test 7: Get single article
test_endpoint "GET" "/api/articles/tech-1" "Get single article by ID"

# Test 8: Get non-existent article (should fail with 404)
test_endpoint "GET" "/api/articles/invalid-id" "Get non-existent article (expect 404)"

# Test 9: Create new article
NEW_ARTICLE='{
  "title": "Test Article from Script",
  "content": "This is a test article created by the testing script. It contains sample content for testing purposes.",
  "summary": "A test article for API validation",
  "author": "Test Script",
  "category": "Technology",
  "readTimeMinutes": 3,
  "tags": ["test", "api", "automation"]
}'
test_endpoint "POST" "/api/articles" "Create new article" "$NEW_ARTICLE"

# Test 10: Create article with missing fields (should fail with 400)
INVALID_ARTICLE='{"title": "Incomplete Article"}'
test_endpoint "POST" "/api/articles" "Create article with missing fields (expect 400)" "$INVALID_ARTICLE"

# Test 11: List all categories
test_endpoint "GET" "/api/categories" "List all categories"

# Test 12: Get articles by category
test_endpoint "GET" "/api/categories/Technology/articles?limit=3" "Get Technology articles (3 items)"

# Test 13: Get articles from non-existent category (should fail with 404)
test_endpoint "GET" "/api/categories/InvalidCategory/articles" "Get articles from invalid category (expect 404)"

echo "================================================"
echo "Testing Complete!"
echo "================================================"
echo ""
echo "Summary:"
echo "  ✅ Most endpoints should show 200 OK status"
echo "  ❌ Some endpoints tested error cases (404, 400)"
echo ""
echo "Next Steps:"
echo "  1. Review the responses above"
echo "  2. Test with your mobile apps"
echo "  3. Start benchmarking performance"
echo ""
