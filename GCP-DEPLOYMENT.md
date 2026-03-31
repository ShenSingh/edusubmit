# EduSubmit - GCP Deployment Guide

This guide provides step-by-step instructions for deploying the EduSubmit microservices application to Google Cloud Platform using two VMs.

## Architecture Overview

- **VM 1 (Platform Services)**: Config Server, Discovery Server, API Gateway
- **VM 2 (Service Modules)**: Student Service, Submission Service, File Service, Databases

## Prerequisites

- Two GCP VMs (Ubuntu 22.04 LTS recommended)
- Docker and Docker Compose installed on both VMs
- OpenJDK 21 installed on both VMs
- Firewall rules configured for required ports

## Required Ports

### VM 1 (Platform Services)
- 8888: Config Server
- 8761: Discovery Server (Eureka)
- 8080: API Gateway

### VM 2 (Service Modules)
- 5432: PostgreSQL
- 27017: MongoDB
- 8081: Student Service
- 8082: Submission Service
- 8083: File Service

## Deployment Steps

### Step 1: Prepare Your Environment

1. **Create GCP VMs**:
   - VM 1: Platform services (2 vCPUs, 4GB RAM recommended)
   - VM 2: Service modules + databases (4 vCPUs, 8GB RAM recommended)

2. **Configure Firewall Rules**:
   - Allow HTTP/HTTPS traffic
   - Allow the ports listed above
   - Allow internal communication between VMs

3. **Clone Repository**:
   ```bash
   git clone <your-repo-url>
   cd edusubmit
   ```

### Step 2: Update Configuration Files

1. **Get External IPs**:
   - Note the external IP of VM 1 (platform VM)
   - Note the external IP of VM 2 (services VM)

2. **Update Config Files**:
   - Edit `platform-seed/edusubmit-config-server/config/*.yml`
   - Replace `platform-vm-external-ip` with VM 1's external IP
   - Replace `services-vm-external-ip` with VM 2's external IP

3. **Update Frontend**:
   - Edit `frontend/edusubmit-frontend/src/services/api.js`
   - Replace `platform-vm-external-ip` with VM 1's external IP

### Step 3: Build Docker Images

Run the build script:
```bash
chmod +x build-docker.sh
./build-docker.sh
```

This will:
- Build all JAR files using Maven
- Create Docker images for all services
- Tag them as `edusubmit-<service>:latest`

### Step 4: Deploy to VM 1 (Platform Services)

1. **Copy deployment files**:
   ```bash
   scp deploy-platform.sh <vm1-user>@<vm1-external-ip>:~
   scp -r platform-seed/edusubmit-config-server/config <vm1-user>@<vm1-external-ip>:~
   ```

2. **Run deployment script**:
   ```bash
   ssh <vm1-user>@<vm1-external-ip>
   chmod +x deploy-platform.sh
   sudo ./deploy-platform.sh
   ```

3. **Push Docker images** (if using a registry):
   ```bash
   # Tag and push images
   docker tag edusubmit-config-server:latest <registry>/edusubmit-config-server:latest
   docker tag edusubmit-discovery-server:latest <registry>/edusubmit-discovery-server:latest
   docker tag edusubmit-api-gateway:latest <registry>/edusubmit-api-gateway:latest
   docker push <registry>/edusubmit-*
   ```

### Step 5: Deploy to VM 2 (Service Modules)

1. **Copy deployment files**:
   ```bash
   scp deploy-services.sh <vm2-user>@<vm2-external-ip>:~
   ```

2. **Run deployment script**:
   ```bash
   ssh <vm2-user>@<vm2-external-ip>
   chmod +x deploy-services.sh
   sudo ./deploy-services.sh
   ```

3. **Push Docker images** (if using a registry):
   ```bash
   # Tag and push images
   docker tag edusubmit-student-service:latest <registry>/edusubmit-student-service:latest
   docker tag edusubmit-submission-service:latest <registry>/edusubmit-submission-service:latest
   docker tag edusubmit-file-service:latest <registry>/edusubmit-file-service:latest
   docker push <registry>/edusubmit-*
   ```

### Step 6: Start Services

**On VM 1**:
```bash
sudo systemctl start edusubmit-platform.service
sudo systemctl status edusubmit-platform.service
```

**On VM 2**:
```bash
sudo systemctl start edusubmit-services.service
sudo systemctl status edusubmit-services.service
```

### Step 7: Deploy Frontend

1. **Build the frontend**:
   ```bash
   cd frontend/edusubmit-frontend
   npm install
   npm run build
   ```

2. **Deploy to web server** (nginx/apache) or cloud storage (Cloud Storage)

## Monitoring and Health Checks

### Check Service Health
```bash
# Platform VM
curl http://localhost:8888/actuator/health  # Config Server
curl http://localhost:8761/actuator/health  # Discovery Server
curl http://localhost:8080/actuator/health  # API Gateway

# Services VM
curl http://localhost:8081/actuator/health  # Student Service
curl http://localhost:8082/actuator/health  # Submission Service
curl http://localhost:8083/actuator/health  # File Service
```

### View Logs
```bash
# Platform services
sudo docker compose -f /opt/edusubmit/docker-compose.platform.yml logs -f

# Service modules
sudo docker compose -f /opt/edusubmit/docker-compose.services.yml logs -f
```

### Check Eureka Dashboard
- URL: `http://<vm1-external-ip>:8761`
- View registered services

## Troubleshooting

### Common Issues

1. **Services not registering with Eureka**:
   - Check network connectivity between VMs
   - Verify external IPs in configuration files
   - Check Eureka server logs

2. **Database connection failures**:
   - Ensure PostgreSQL/MongoDB are running
   - Check database credentials in config files
   - Verify network connectivity

3. **File upload issues**:
   - Check file service logs
   - Verify upload directory permissions
   - Ensure sufficient disk space

### Logs Location
- Application logs: `/opt/edusubmit/logs/`
- Docker logs: `docker compose logs <service-name>`

## Security Considerations

1. **Database Security**:
   - Change default passwords
   - Configure database user permissions
   - Enable SSL/TLS for database connections

2. **Network Security**:
   - Use VPC internal IPs for service communication
   - Configure firewall rules to restrict access
   - Use HTTPS for external APIs

3. **Application Security**:
   - Implement authentication/authorization
   - Use secrets management for sensitive data
   - Enable CSRF protection

## Scaling Considerations

- Use GCP Load Balancer for API Gateway
- Configure auto-scaling groups for VMs
- Consider using Cloud SQL for managed databases
- Use Cloud Storage for file uploads

## Backup and Recovery

- Regular database backups
- VM snapshots
- Configuration file backups
- Docker image backups

---

For additional support, check the application logs or create an issue in the repository.
