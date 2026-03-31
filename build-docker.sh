#!/bin/bash

# EduSubmit Docker Build Script
# This script builds all Docker images for the microservices

set -e

echo "🏗️ Building EduSubmit Docker Images..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Build platform services
echo "🏗️ Building Platform Services..."

cd platform-seed/edusubmit-config-server
print_status "Building Config Server..."
mvn clean package -DskipTests
docker build -t edusubmit-config-server:latest .
print_status "Config Server built successfully"

cd ../edusubmit-discovery-server
print_status "Building Discovery Server..."
mvn clean package -DskipTests
docker build -t edusubmit-discovery-server:latest .
print_status "Discovery Server built successfully"

cd ../edusubmit-api-gateway
print_status "Building API Gateway..."
mvn clean package -DskipTests
docker build -t edusubmit-api-gateway:latest .
print_status "API Gateway built successfully"

cd ../../..

# Build service modules
echo "🏗️ Building Service Modules..."

cd service-seed/edusubmit-student-service
print_status "Building Student Service..."
mvn clean package -DskipTests
docker build -t edusubmit-student-service:latest .
print_status "Student Service built successfully"

cd ../edusubmit-submission-service
print_status "Building Submission Service..."
mvn clean package -DskipTests
docker build -t edusubmit-submission-service:latest .
print_status "Submission Service built successfully"

cd ../edusubmit-file-service
print_status "Building File Service..."
mvn clean package -DskipTests
docker build -t edusubmit-file-service:latest .
print_status "File Service built successfully"

cd ../../..

print_status "All Docker images built successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Tag images for your registry: docker tag edusubmit-<service>:latest <registry>/edusubmit-<service>:latest"
echo "2. Push images: docker push <registry>/edusubmit-<service>:latest"
echo "3. Update deployment scripts with your registry URL"
echo "4. Run deployment scripts on respective VMs"
