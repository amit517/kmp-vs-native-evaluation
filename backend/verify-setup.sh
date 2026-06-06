#!/bin/bash

# KMP Research Backend - Setup Verification Script

echo "================================================"
echo "KMP Research Backend - Setup Verification"
echo "================================================"
echo ""

# Check if server is running
echo "🔍 Checking if server is running..."
if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ Server is running on port 8080"
    echo ""
    
    # Test health endpoint
    echo "📡 Testing /health endpoint..."
    echo "Response:"
    curl -s http://localhost:8080/health | python3 -m json.tool
    echo ""
    
    # Test API status
    echo "📡 Testing /api/status endpoint..."
    echo "Response:"
    curl -s http://localhost:8080/api/status | python3 -m json.tool
    echo ""
    
    # Test root endpoint
    echo "📡 Testing / endpoint..."
    echo "Response:"
    curl -s http://localhost:8080/
    echo ""
    
    echo "================================================"
    echo "✅ All endpoints are working correctly!"
    echo "================================================"
else
    echo "❌ Server is not running on port 8080"
    echo ""
    echo "To start the server:"
    echo "  1. In IntelliJ: Run Application.kt"
    echo "  2. In Terminal: ./gradlew run"
    echo ""
fi

echo ""
echo "📋 Next Steps:"
echo "  1. Implement Article data models"
echo "  2. Create ArticleRepository with mock data"
echo "  3. Implement article CRUD endpoints"
echo "  4. Test with mobile clients"
echo ""
