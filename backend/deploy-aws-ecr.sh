#!/bin/bash
set -e

echo "========================================="
echo "KMP News Backend - AWS ECR Deployment"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="eu-central-1"
ECR_REPO_NAME="kmp-news-backend"
IMAGE_TAG="latest"

echo "Step 1: Creating ECR repository (if it doesn't exist)..."
aws ecr describe-repositories --repository-names "$ECR_REPO_NAME" --region "$AWS_REGION" 2>/dev/null || \
aws ecr create-repository \
    --repository-name "$ECR_REPO_NAME" \
    --region "$AWS_REGION" \
    --image-scanning-configuration scanOnPush=true

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} ECR repository ready"
else
    echo -e "${RED}❌ Failed to create ECR repository${NC}"
    exit 1
fi

# Get ECR repository URI
ECR_URI=$(aws ecr describe-repositories --repository-names "$ECR_REPO_NAME" --region "$AWS_REGION" --query 'repositories[0].repositoryUri' --output text)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo ""
echo "ECR Repository: $ECR_URI"
echo ""

echo "Step 2: Logging in to ECR..."
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ ECR login failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Logged in to ECR"

echo ""
echo "Step 3: Building Docker image..."
docker build -t "$ECR_REPO_NAME:$IMAGE_TAG" .

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Docker build failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Docker image built"

echo ""
echo "Step 4: Tagging image for ECR..."
docker tag "$ECR_REPO_NAME:$IMAGE_TAG" "$ECR_URI:$IMAGE_TAG"
echo -e "${GREEN}✓${NC} Image tagged"

echo ""
echo "Step 5: Pushing image to ECR..."
docker push "$ECR_URI:$IMAGE_TAG"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Docker push failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Image pushed to ECR"

echo ""
echo "Step 6: Updating terraform.tfvars with ECR image..."
cd terraform
if [ -f terraform.tfvars ]; then
    # Update the docker_image line
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|docker_image = .*|docker_image = \"$ECR_URI:$IMAGE_TAG\"|g" terraform.tfvars
    else
        sed -i "s|docker_image = .*|docker_image = \"$ECR_URI:$IMAGE_TAG\"|g" terraform.tfvars
    fi
    echo -e "${GREEN}✓${NC} terraform.tfvars updated"
else
    cp terraform.tfvars.example terraform.tfvars
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|docker_image = .*|docker_image = \"$ECR_URI:$IMAGE_TAG\"|g" terraform.tfvars
    else
        sed -i "s|docker_image = .*|docker_image = \"$ECR_URI:$IMAGE_TAG\"|g" terraform.tfvars
    fi
    echo -e "${GREEN}✓${NC} terraform.tfvars created"
fi

echo ""
echo "Step 7: Initializing Terraform..."
terraform init

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Terraform init failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Terraform initialized"

echo ""
echo "Step 8: Planning Terraform deployment..."
terraform plan

echo ""
read -p "Do you want to apply this Terraform plan? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled"
    exit 0
fi

echo ""
echo "Step 9: Applying Terraform configuration..."
terraform apply -auto-approve

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Terraform apply failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}✓ Deployment successful!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""

# Get outputs
API_ENDPOINT=$(terraform output -raw api_endpoint 2>/dev/null || echo "")
PUBLIC_IP=$(terraform output -raw instance_public_ip 2>/dev/null || echo "")

if [ -n "$API_ENDPOINT" ]; then
    echo "API Endpoint: $API_ENDPOINT"
    echo "Public IP: $PUBLIC_IP"
    echo ""
    echo "Waiting for instance to initialize (2-3 minutes)..."
    sleep 120
    
    echo "Testing health endpoint..."
    curl -f "$API_ENDPOINT/health" && echo -e "\n${GREEN}✓${NC} Backend is healthy!" || echo -e "\n${YELLOW}⚠${NC} Backend may still be initializing..."
fi

cd ..
