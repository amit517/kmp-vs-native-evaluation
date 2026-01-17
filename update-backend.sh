#!/bin/bash
set -e

echo "========================================="
echo "KMP News Backend - Update Deployment"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="eu-central-1"
ACCOUNT_ID="609103576101"
ECR_REPO_NAME="kmp-news-backend"
IMAGE_TAG="latest"
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"
INSTANCE_IP="63.177.119.99"

# Store the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo -e "${BLUE}This script will:${NC}"
echo "1. Build your Docker image"
echo "2. Push it to Amazon ECR"
echo "3. Update the running instance on AWS"
echo ""

# Check for uncommitted changes
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo -e "${YELLOW}⚠ Warning: You have uncommitted changes${NC}"
    echo "Consider committing your changes first:"
    echo "  git add ."
    echo "  git commit -m 'Your update description'"
    echo ""
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Update cancelled"
        exit 0
    fi
fi

# Get current git commit for tagging (optional)
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
echo -e "${BLUE}Git commit: ${GIT_COMMIT}${NC}"
echo ""

# Step 1: Test locally (optional quick test)
echo "Step 1: Quick syntax check..."
if command -v ./gradlew &> /dev/null; then
    echo "Running Gradle check..."
    ./gradlew check --quiet || {
        echo -e "${RED}❌ Gradle check failed. Please fix errors before deploying.${NC}"
        exit 1
    }
    echo -e "${GREEN}✓${NC} Syntax check passed"
else
    echo -e "${YELLOW}⚠${NC} Gradle wrapper not found, skipping syntax check"
fi
echo ""

# Step 2: Login to ECR
echo "Step 2: Logging in to Amazon ECR..."
aws ecr get-login-password --region "$AWS_REGION" | \
    docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ ECR login failed${NC}"
    echo "Make sure AWS credentials are configured: aws configure"
    exit 1
fi
echo -e "${GREEN}✓${NC} Logged in to ECR"
echo ""

# Step 3: Build Docker image
echo "Step 3: Building Docker image..."
echo "This may take 2-5 minutes..."
echo ""

docker build -t "${ECR_REPO_NAME}:${IMAGE_TAG}" .

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Docker build failed${NC}"
    exit 1
fi
echo ""
echo -e "${GREEN}✓${NC} Docker image built successfully"
echo ""

# Step 4: Tag image
echo "Step 4: Tagging image for ECR..."
docker tag "${ECR_REPO_NAME}:${IMAGE_TAG}" "${ECR_URI}:${IMAGE_TAG}"

# Also tag with commit hash for versioning
docker tag "${ECR_REPO_NAME}:${IMAGE_TAG}" "${ECR_URI}:${GIT_COMMIT}"

echo -e "${GREEN}✓${NC} Image tagged"
echo ""

# Step 5: Push to ECR
echo "Step 5: Pushing image to ECR..."
echo "Pushing latest tag..."
docker push "${ECR_URI}:${IMAGE_TAG}"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Docker push failed${NC}"
    exit 1
fi

echo "Pushing commit tag (${GIT_COMMIT})..."
docker push "${ECR_URI}:${GIT_COMMIT}" 2>/dev/null || echo "  (commit tag push skipped)"

echo -e "${GREEN}✓${NC} Image pushed to ECR"
echo ""

# Step 6: Update on EC2
echo "Step 6: Updating application on EC2..."
echo ""

read -p "Do you want to update the EC2 instance now? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${YELLOW}Deployment to ECR complete, but EC2 instance not updated.${NC}"
    echo ""
    echo "To update manually later, SSH into the instance and run:"
    echo "  ssh ec2-user@${INSTANCE_IP}"
    echo "  cd /opt/news-backend"
    echo "  sudo ./update.sh"
    exit 0
fi

echo ""
echo "Connecting to EC2 instance..."
echo "Running update script on server..."
echo ""

# SSH and update (requires SSH key to be configured)
ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ec2-user@${INSTANCE_IP} << 'ENDSSH'
echo "Connected to EC2 instance"
cd /opt/news-backend

echo "Logging in to ECR..."
AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password --region $AWS_REGION | \
    sudo docker login --username AWS --password-stdin \
    $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

echo "Pulling latest image..."
sudo docker-compose pull

echo "Restarting application..."
sudo docker-compose up -d --force-recreate

echo "Waiting for application to start..."
sleep 5

echo "Checking container status..."
sudo docker ps | grep news-backend

echo ""
echo "Recent logs:"
sudo docker logs --tail 20 news-backend

ENDSSH

if [ $? -ne 0 ]; then
    echo ""
    echo -e "${RED}❌ SSH connection or update failed${NC}"
    echo ""
    echo "Possible issues:"
    echo "1. SSH key not configured"
    echo "2. Instance not accessible"
    echo "3. Security group blocking SSH"
    echo ""
    echo "To update manually:"
    echo "  ssh ec2-user@${INSTANCE_IP}"
    echo "  cd /opt/news-backend && sudo ./update.sh"
    exit 1
fi

echo ""
echo -e "${GREEN}✓${NC} Application updated on EC2"
echo ""

# Step 7: Test the deployment
echo "Step 7: Testing the updated deployment..."
echo "Waiting 10 seconds for app to fully start..."
sleep 10

echo ""
echo "Testing health endpoint..."
HEALTH_CHECK=$(curl -s -w "\n%{http_code}" http://${INSTANCE_IP}:8080/health 2>/dev/null)
HTTP_CODE=$(echo "$HEALTH_CHECK" | tail -n 1)
RESPONSE=$(echo "$HEALTH_CHECK" | head -n -1)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓${NC} Health check passed!"
    echo "Response: $RESPONSE"
else
    echo -e "${YELLOW}⚠${NC} Health check returned HTTP $HTTP_CODE"
    echo "The app may still be starting up. Check manually:"
    echo "  curl http://${INSTANCE_IP}:8080/health"
fi

echo ""
echo "Testing articles endpoint..."
ARTICLES=$(curl -s http://${INSTANCE_IP}:8080/api/articles?page=1&limit=1 2>/dev/null)
if [ -n "$ARTICLES" ]; then
    echo -e "${GREEN}✓${NC} Articles endpoint working"
    echo "$ARTICLES" | head -c 200
    echo "..."
else
    echo -e "${YELLOW}⚠${NC} Articles endpoint may not be ready yet"
fi

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}✓ Update Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Deployment Information:"
echo "  • Commit: ${GIT_COMMIT}"
echo "  • Image: ${ECR_URI}:${IMAGE_TAG}"
echo "  • API: http://${INSTANCE_IP}:8080"
echo ""
echo "Your backend has been updated successfully!"
echo ""
echo "Next steps:"
echo "1. Test the API endpoints thoroughly"
echo "2. Check logs if needed: ssh ec2-user@${INSTANCE_IP}"
echo "3. Update mobile app if API changes were made"
echo ""
echo "Monitor logs with:"
echo "  ssh ec2-user@${INSTANCE_IP} 'sudo docker logs -f news-backend'"
echo ""
