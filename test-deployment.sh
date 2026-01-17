#!/bin/bash

# Test AWS Deployment Script
API_ENDPOINT="http://63.177.119.99:8080"

echo "========================================="
echo "Testing KMP News Backend on AWS"
echo "========================================="
echo ""
echo "API Endpoint: $API_ENDPOINT"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Waiting for backend to be ready..."
echo "This may take 3-5 minutes on first startup..."
echo ""

MAX_RETRIES=20
RETRY_COUNT=0
WAIT_TIME=15

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo -n "Attempt $((RETRY_COUNT + 1))/$MAX_RETRIES: "
    
    # Test health endpoint
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$API_ENDPOINT/health" 2>/dev/null)
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}✓ Backend is healthy!${NC}"
        echo ""
        
        # Test health response
        echo "Health Check Response:"
        curl -s "$API_ENDPOINT/health" | python3 -m json.tool || curl -s "$API_ENDPOINT/health"
        echo ""
        echo ""
        
        # Test articles endpoint
        echo "Testing Articles Endpoint:"
        echo "Fetching first 3 articles..."
        curl -s "$API_ENDPOINT/api/articles?page=1&limit=3" | python3 -m json.tool 2>/dev/null || curl -s "$API_ENDPOINT/api/articles?page=1&limit=3"
        echo ""
        echo ""
        
        echo -e "${GREEN}=========================================${NC}"
        echo -e "${GREEN}✓ Deployment Successful!${NC}"
        echo -e "${GREEN}=========================================${NC}"
        echo ""
        echo "Your API is live at: $API_ENDPOINT"
        echo ""
        echo "Update your mobile app with:"
        echo "  const val BASE_URL = \"$API_ENDPOINT\""
        echo ""
        exit 0
    else
        echo -e "${YELLOW}Not ready yet (HTTP $HTTP_CODE)${NC}"
        RETRY_COUNT=$((RETRY_COUNT + 1))
        
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo "   Waiting ${WAIT_TIME}s before retry..."
            sleep $WAIT_TIME
        fi
    fi
done

echo ""
echo -e "${RED}=========================================${NC}"
echo -e "${RED}Backend did not respond after $((MAX_RETRIES * WAIT_TIME / 60)) minutes${NC}"
echo -e "${RED}=========================================${NC}"
echo ""
echo "This could mean:"
echo "1. The instance is still initializing (can take up to 5 minutes)"
echo "2. Docker is still pulling the image from ECR"
echo "3. There may be an issue with the deployment"
echo ""
echo "Troubleshooting steps:"
echo "1. Check instance status:"
echo "   aws ec2 describe-instance-status --instance-ids i-05cef0a750c7bea5c --region eu-central-1"
echo ""
echo "2. SSH into instance and check logs:"
echo "   ssh ec2-user@63.177.119.99"
echo "   sudo docker ps"
echo "   sudo docker logs news-backend"
echo ""
echo "3. Check user-data script execution:"
echo "   ssh ec2-user@63.177.119.99"
echo "   sudo cat /var/log/cloud-init-output.log"
echo ""

exit 1
