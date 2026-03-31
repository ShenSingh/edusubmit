#!/bin/bash

# EduSubmit Service Modules Deployment Script for GCP VM 2
# This script deploys Student Service, Submission Service, File Service, and databases

set -e

echo "🚀 Starting EduSubmit Service Modules Deployment..."

# Update system packages
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Java 21
echo "☕ Installing OpenJDK 21..."
sudo apt install -y openjdk-21-jdk

# Install Docker
echo "🐳 Installing Docker..."
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Create application directories
echo "📁 Creating application directories..."
sudo mkdir -p /opt/edusubmit/{services,uploads,logs,data/postgres,data/mongodb}
sudo chown -R $USER:$USER /opt/edusubmit

# Create Docker Compose file for services
cat > /opt/edusubmit/docker-compose.services.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: student_db
      POSTGRES_USER: student_user
      POSTGRES_PASSWORD: student_password
    ports:
      - "5432:5432"
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U student_user -d student_db"]
      interval: 30s
      timeout: 10s
      retries: 3

  mongodb:
    image: mongo:7
    environment:
      MONGO_INITDB_DATABASE: edusubmit_submission_db
    ports:
      - "27017:27017"
    volumes:
      - ./data/mongodb:/data/db
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
      interval: 30s
      timeout: 10s
      retries: 3

  student-service:
    image: edusubmit-student-service:latest
    ports:
      - "8081:8081"
    depends_on:
      postgres:
        condition: service_healthy
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8081/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  submission-service:
    image: edusubmit-submission-service:latest
    ports:
      - "8082:8082"
    depends_on:
      mongodb:
        condition: service_healthy
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8082/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  file-service:
    image: edusubmit-file-service:latest
    ports:
      - "8083:8083"
    volumes:
      - ./uploads:/app/uploads
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8083/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

# Create systemd service for Docker Compose
cat > /etc/systemd/system/edusubmit-services.service << 'EOF'
[Unit]
Description=EduSubmit Service Modules
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/edusubmit
ExecStart=/usr/bin/docker compose -f docker-compose.services.yml up -d
ExecStop=/usr/bin/docker compose -f docker-compose.services.yml down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable edusubmit-services.service

echo "✅ Service modules deployment script completed!"
echo "📝 Next steps:"
echo "1. Build and push Docker images to your registry"
echo "2. Update the config files with actual platform VM external IP"
echo "3. Run: sudo systemctl start edusubmit-services.service"
echo "4. Check status: sudo systemctl status edusubmit-services.service"
