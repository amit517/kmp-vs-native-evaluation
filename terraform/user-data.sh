#!/bin/bash
set -e

# Update system
dnf update -y

# Install Docker
dnf install -y docker

# Start Docker service
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -aG docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create application directory
mkdir -p /opt/news-backend
cd /opt/news-backend

# Create docker-compose.yml
cat > docker-compose.yml <<'EOF'
version: '3.8'

services:
  news-backend:
    image: ${docker_image}
    container_name: news-backend
    ports:
      - "8080:8080"
    restart: unless-stopped
    environment:
      - JAVA_OPTS=-Xmx256m -Xms128m
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
EOF

# Wait for Docker to be fully ready
sleep 10

# Get AWS region from metadata using IMDSv2 token
echo "Getting AWS region from metadata service..."
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null)
AWS_REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null)

# Fallback to IMDSv1 if IMDSv2 fails
if [ -z "$AWS_REGION" ]; then
    AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone 2>/dev/null | sed 's/[a-z]$//')
fi

echo "AWS_REGION detected: $AWS_REGION"

# Get account ID
if [ -n "$AWS_REGION" ]; then
    echo "Getting AWS Account ID..."
    export AWS_DEFAULT_REGION="$AWS_REGION"
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>&1)
    
    if [ $? -eq 0 ] && [ -n "$ACCOUNT_ID" ]; then
        echo "ACCOUNT_ID: $ACCOUNT_ID"
        
        # Login to ECR
        echo "Logging in to ECR at $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com..."
        aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
        
        if [ $? -eq 0 ]; then
            # Pull and run the Docker image
            echo "Pulling Docker image..."
            docker-compose pull
            
            echo "Starting application..."
            docker-compose up -d
            
            echo "Application started successfully!"
            docker-compose ps
        else
            echo "ERROR: ECR login failed"
        fi
    else
        echo "ERROR: Could not get AWS Account ID: $ACCOUNT_ID"
    fi
else
    echo "ERROR: Could not determine AWS region"
fi

# Create a script for manual updates
cat > /opt/news-backend/update.sh <<'UPDATE_SCRIPT'
#!/bin/bash
# Script to update the backend application
set -e

cd /opt/news-backend

echo "Getting AWS region..."
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null)
AWS_REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null)

if [ -z "$AWS_REGION" ]; then
    AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone 2>/dev/null | sed 's/[a-z]$//')
fi

echo "Region: $AWS_REGION"
export AWS_DEFAULT_REGION="$AWS_REGION"

echo "Getting Account ID..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Account: $ACCOUNT_ID"

echo "Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

echo "Pulling latest image..."
docker-compose pull

echo "Restarting application..."
docker-compose up -d --force-recreate

echo "Backend updated successfully!"
docker-compose ps
UPDATE_SCRIPT

chmod +x /opt/news-backend/update.sh

# Create systemd service for the backend
cat > /etc/systemd/system/news-backend.service <<'SERVICE'
[Unit]
Description=KMP News Backend Service
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/news-backend
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
SERVICE

# Install CloudWatch agent for monitoring (optional, but useful)
dnf install -y amazon-cloudwatch-agent

# Create log directory
mkdir -p /var/log/news-backend

echo "User data script completed successfully" > /var/log/user-data.log
