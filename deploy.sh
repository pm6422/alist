#!/bin/bash

# One-click Docker and Alist deployment script
set -e

echo "=========================================="
echo "  Docker & Alist One-Click Deployment"
echo "=========================================="

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Log functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Please run this script as root"
        exit 1
    fi
}

# Check system requirements
check_system() {
    log_info "Checking system requirements..."

    # Check memory
    local mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local mem_gb=$((mem_total / 1024 / 1024))

    if [ $mem_gb -lt 1 ]; then
        log_warn "Low memory detected: ${mem_gb}GB (Recommended: 2GB+)"
    else
        log_info "Memory: ${mem_gb}GB"
    fi

    # Check disk space
    local disk_free=$(df / | awk 'NR==2 {print $4}')
    local disk_gb=$((disk_free / 1024 / 1024))

    if [ $disk_gb -lt 5 ]; then
        log_warn "Low disk space: ${disk_gb}GB free (Recommended: 10GB+ free)"
    else
        log_info "Disk space: ${disk_gb}GB free"
    fi
}

# Install Docker and Docker Compose
install_docker() {
    if command -v docker &> /dev/null && docker compose version &> /dev/null; then
        log_info "Docker and Docker Compose are already installed"
        log_info "Docker version: $(docker --version)"
        log_info "Docker Compose version: $(docker compose version)"
        return
    fi

    log_info "Installing Docker..."
    curl -fsSL https://get.docker.com | bash

    # Start and enable Docker service
    systemctl start docker
    systemctl enable docker

    # Verify installation
    if docker --version &> /dev/null && docker compose version &> /dev/null; then
        log_info "Docker installed successfully: $(docker --version)"
        log_info "Docker Compose version: $(docker compose version)"
    else
        log_error "Docker installation failed"
        exit 1
    fi
}

# Create necessary directories
create_directories() {
    log_info "Creating configuration directories..."

    mkdir -p config/alist
    mkdir -p config/caddy/{data,config}

    # Set proper permissions
    chmod 755 config/alist
    chmod 755 config/caddy/{data,config}

    log_info "Directories created successfully"
}

# Check if Caddyfile exists, create if missing
create_caddyfile() {
    local caddyfile_path="config/caddy/Caddyfile"

    if [ -f "$caddyfile_path" ]; then
        log_info "Caddyfile already exists, skipping creation"
        return
    fi

    log_info "Creating Caddyfile configuration..."

    mkdir -p config/caddy
    cat > "$caddyfile_path" << 'EOF'
# Alist service
alist.pm6422.site {
    reverse_proxy alist:5244
}
EOF

    log_info "Caddyfile created successfully"
}

# Deploy services
deploy_services() {
    log_info "Starting service deployment..."

    # Check if docker-compose file exists
    if [ ! -f "docker-compose.yml" ]; then
        log_error "docker-compose.yml file not found. Please run this script in the correct directory."
        exit 1
    fi

    # Validate docker-compose file
    if ! docker compose config -q; then
        log_error "Invalid docker-compose.yml file"
        exit 1
    fi

    # Pull latest images
    log_info "Pulling Docker images..."
    docker compose pull

    # Start services
    log_info "Starting services..."
    docker compose up -d

    # Wait for services to initialize
    log_info "Waiting for services to start (this may take a minute)..."
    sleep 30

    # Check service status
    log_info "Checking service status..."
    docker compose ps

    # Show logs if services are not healthy
    if ! docker compose ps | grep -q "Up (healthy)"; then
        log_warn "Some services may not be fully healthy. Checking logs..."
        docker compose logs --tail=20
    fi
}

# Show deployment information
show_info() {
    echo ""
    echo "=========================================="
    echo "          Deployment Complete!"
    echo "=========================================="
    echo "Services deployed:"
    echo "  - Caddy (Reverse Proxy)"
    echo "  - Alist (File Management)"
    echo ""
    echo "Access URLs:"
    echo "  - Alist: https://alist.pm6422.site"
    echo ""
    echo "Management Commands:"
    echo "  # View service status"
    echo "  docker compose ps"
    echo ""
    echo "  # View logs"
    echo "  docker compose logs -f"
    echo ""
    echo "  # Stop services"
    echo "  docker compose down"
    echo ""
    echo "  # Restart services"
    echo "  docker compose restart"
    echo ""
    echo "  # Update services"
    echo "  docker compose pull && docker compose up -d"
    echo ""
    echo "Important Notes:"
    echo "  - Ensure alist.pm6422.site DNS points to this server"
    echo "  - SSL certificates will be auto-generated by Caddy"
    echo "  - Services will auto-start on system reboot"
    echo "  - Check logs if you encounter issues: docker compose logs"
    echo "=========================================="
}

# Health check function
health_check() {
    log_info "Performing health check..."

    # Check if containers are running
    if docker compose ps | grep -q "Up"; then
        log_info "All services are running"
    else
        log_error "Some services failed to start"
        docker compose ps
        exit 1
    fi
}

# Main function
main() {
    log_info "Starting deployment process..."

    check_root
    check_system
    install_docker
    create_directories
    create_caddyfile
    deploy_services
    health_check
    show_info

    log_info "Deployment completed successfully!"
}

# Run main function
main "$@"