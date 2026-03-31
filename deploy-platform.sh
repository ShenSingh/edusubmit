#!/bin/bash

# EduSubmit Platform Services Deployment Script for GCP VM 1
# This script deploys Config Server, Discovery Server, and API Gateway

set -e

echo "🚀 Starting EduSubmit Platform Services Deployment..."

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
sudo mkdir -p /opt/edusubmit/{config,logs}
sudo chown -R $USER:$USER /opt/edusubmit

# Copy JAR files (assuming they're built and copied to VM)
# In production, you would copy the JARs from your build artifacts
echo "📋 Copying JAR files..."
# cp /path/to/built/jars/*.jar /opt/edusubmit/

# Create Docker Compose file for platform services
cat > /opt/edusubmit/docker-compose.platform.yml << 'EOF'
version: '3.8'

services:
  config-server:
    image: edusubmit-config-server:latest
    ports:
      - "8888:8888"
    environment:
      - SPRING_PROFILES_ACTIVE=native
    volumes:
      - ./config:/app/config
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8888/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  discovery-server:
    image: edusubmit-discovery-server:latest
    ports:
      - "8761:8761"
    depends_on:
      config-server:
        condition: service_healthy
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8761/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  api-gateway:
    image: edusubmit-api-gateway:latest
    ports:
      - "8080:8080"
    depends_on:
      discovery-server:
        condition: service_healthy
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

# Create systemd service for Docker Compose
cat > /etc/systemd/system/edusubmit-platform.service << 'EOF'
[Unit]
Description=EduSubmit Platform Services
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/edusubmit
ExecStart=/usr/bin/docker compose -f docker-compose.platform.yml up -d
ExecStop=/usr/bin/docker compose -f docker-compose.platform.yml down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable edusubmit-platform.service

echo "✅ Platform services deployment script completed!"
echo "📝 Next steps:"
echo "1. Build and push Docker images to your registry"
echo "2. Update the config files with actual external IPs"
echo "3. Run: sudo systemctl start edusubmit-platform.service"
echo "4. Check status: sudo systemctl status edusubmit-platform.service"
