# Alist File Management System

A Docker-based file management system that supports multiple storage services and provides a unified file management interface.

## Features

- 📁 **Multiple Storage Support**: Integrates various cloud storage and local storage services
- 🔒 **Secure Access**: Automatic HTTPS encryption via Caddy reverse proxy
- 🐳 **Containerized Deployment**: One-click deployment using Docker Compose
- 📱 **Responsive Design**: Web interface accessible from any device
- 🔄 **Auto-renewal SSL**: Automatic Let's Encrypt certificate management
- 🚀 **Easy Maintenance**: Simple update and management process

## Prerequisites

- Linux server with public IP address
- Domain name pointing to your server IP
- Docker and Docker Compose (automatically installed by script)

## Quick Start

### 1. Clone or Download Files

Ensure you have the following files in your directory:
- `docker-compose.yml` - Service configuration
- `deploy.sh` - Automated deployment script
- `config/caddy/Caddyfile` - Reverse proxy configuration

### 2. Configure DNS

Add DNS A record for your domain:
alist.yourdomain.com → YOUR_SERVER_IP


Wait for DNS propagation (usually 5-60 minutes).

### 3. Run Deployment Script

```bash

# Make script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

The script will automatically:

- Install Docker and Docker Compose (if not present)
- Create the necessary directories
- Pull Docker images
- Start all services
- Configure SSL certificates

### 5. Set password of admin user
```bash

docker exec -it alist ./alist admin set NEW_PASSWORD
```

### 5. Access Your Service
Once deployment completes, access your Alist instance at:

https://alist.yourdomain.com


### 6. Restart a Service
```bash

docker compose restart caddy
```

### 6. Stop all Services
```bash

docker compose down
```