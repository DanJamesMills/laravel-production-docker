#!/bin/bash

# Laravel Production Docker - Interactive Setup Script
# This script will help you configure your environment

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Laravel Production Docker - Interactive Setup${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first:"
        echo "  https://docs.docker.com/engine/install/"
        exit 1
    fi
    
    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not installed or too old."
        echo "  Please install Docker Compose 2.0+:"
        echo "  https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    print_success "Docker and Docker Compose are installed"
}

# Generate random password (avoid shell/env special characters)
generate_password() {
    # Only use alphanumeric and safe special chars: !@#-_+=
    LC_ALL=C tr -dc 'A-Za-z0-9!@#_+=' < /dev/urandom | head -c 32
}

# Get server RAM configuration
get_ram_config() {
    echo -e "\n${GREEN}Server RAM Configuration${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Select your server's total RAM to optimize MySQL settings:"
    echo ""
    echo "  1) 2GB RAM  - Minimal (InnoDB: 512M, Logs: 128M)"
    echo "  2) 4GB RAM  - Recommended (InnoDB: 1G, Logs: 256M) [Default]"
    echo "  3) 8GB RAM  - Performance (InnoDB: 3G, Logs: 512M)"
    echo "  4) 16GB RAM - High Performance (InnoDB: 8G, Logs: 1G)"
    echo "  5) Custom   - Enter your own values"
    echo ""
    
    while true; do
        read -p "Select option [1-5] (default: 2): " ram_choice
        ram_choice=${ram_choice:-2}
        
        case $ram_choice in
            1)
                MYSQL_INNODB_BUFFER_POOL_SIZE="512M"
                MYSQL_INNODB_LOG_FILE_SIZE="128M"
                print_success "Configured for 2GB RAM server"
                break
                ;;
            2)
                MYSQL_INNODB_BUFFER_POOL_SIZE="1G"
                MYSQL_INNODB_LOG_FILE_SIZE="256M"
                print_success "Configured for 4GB RAM server"
                break
                ;;
            3)
                MYSQL_INNODB_BUFFER_POOL_SIZE="3G"
                MYSQL_INNODB_LOG_FILE_SIZE="512M"
                print_success "Configured for 8GB RAM server"
                break
                ;;
            4)
                MYSQL_INNODB_BUFFER_POOL_SIZE="8G"
                MYSQL_INNODB_LOG_FILE_SIZE="1G"
                print_success "Configured for 16GB RAM server"
                break
                ;;
            5)
                read -p "Enter InnoDB Buffer Pool Size (e.g., 2G): " MYSQL_INNODB_BUFFER_POOL_SIZE
                read -p "Enter InnoDB Log File Size (e.g., 512M): " MYSQL_INNODB_LOG_FILE_SIZE
                print_success "Custom MySQL configuration set"
                break
                ;;
            *)
                print_error "Invalid choice. Please select 1-5."
                ;;
        esac
    done
}

# Get PHP version selection
get_php_version() {
    echo -e "\n${GREEN}PHP Version Selection${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Select the PHP version for your Laravel application:"
    echo ""
    echo "  1) PHP 8.1 - Older LTS (supported until Nov 2024)"
    echo "  2) PHP 8.2 - Current LTS (supported until Dec 2025)"
    echo "  3) PHP 8.3 - Latest stable (supported until Nov 2026)"
    echo "  4) PHP 8.4 - Newest release (supported until Nov 2027) [Default]"
    echo ""
    
    while true; do
        read -p "Select option [1-4] (default: 4): " php_choice
        php_choice=${php_choice:-4}
        
        case $php_choice in
            1)
                PHP_VERSION="8.1"
                print_success "Selected PHP 8.1"
                break
                ;;
            2)
                PHP_VERSION="8.2"
                print_success "Selected PHP 8.2"
                break
                ;;
            3)
                PHP_VERSION="8.3"
                print_success "Selected PHP 8.3"
                break
                ;;
            4)
                PHP_VERSION="8.4"
                print_success "Selected PHP 8.4"
                break
                ;;
            *)
                print_error "Invalid choice. Please select 1-4."
                ;;
        esac
    done
}

# Get domain configuration
get_domain() {
    echo -e "\n${GREEN}Domain Configuration${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Enter your domain name (e.g., example.com, app.example.com)"
    echo "Or press Enter to use 'localhost' for local development"
    echo ""
    
    read -p "Domain: " APP_DOMAIN
    APP_DOMAIN=${APP_DOMAIN:-localhost}
    
    if [ "$APP_DOMAIN" = "localhost" ]; then
        APP_URL="http://localhost"
        print_info "Using localhost for local development"
    else
        read -p "Use HTTPS? [Y/n]: " use_https
        use_https=${use_https:-Y}
        
        if [[ $use_https =~ ^[Yy]$ ]]; then
            APP_URL="https://${APP_DOMAIN}"
        else
            APP_URL="http://${APP_DOMAIN}"
        fi
        
        print_success "Domain set to: ${APP_URL}"
    fi
}

# Get database credentials
get_database_credentials() {
    echo -e "\n${GREEN}Database Configuration${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    read -p "MySQL Database Name (default: laravel): " MYSQL_DATABASE
    MYSQL_DATABASE=${MYSQL_DATABASE:-laravel}
    
    read -p "MySQL Username (default: laravel_user): " MYSQL_USER
    MYSQL_USER=${MYSQL_USER:-laravel_user}
    
    read -p "Generate secure MySQL password? [Y/n]: " gen_mysql_pass
    gen_mysql_pass=${gen_mysql_pass:-Y}
    
    if [[ $gen_mysql_pass =~ ^[Yy]$ ]]; then
        MYSQL_PASSWORD=$(generate_password)
        MYSQL_ROOT_PASSWORD=$(generate_password)
        print_success "Generated secure MySQL passwords"
    else
        read -sp "MySQL User Password: " MYSQL_PASSWORD
        echo ""
        read -sp "MySQL Root Password: " MYSQL_ROOT_PASSWORD
        echo ""
    fi
    
    print_success "Database credentials configured"
}

# Save credentials to file
save_credentials() {
    echo -e "\n${GREEN}Saving Credentials${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Create credentials directory if it doesn't exist
    mkdir -p credentials
    
    # Create credentials file with timestamp
    CREDENTIALS_FILE="credentials/credentials_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$CREDENTIALS_FILE" << EOF
Laravel Production Docker - Credentials
Generated: $(date)
═══════════════════════════════════════════════════════════════

Application Configuration:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Domain:           ${APP_DOMAIN}
URL:              ${APP_URL}
PHP Version:      ${PHP_VERSION}

Database Configuration:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Database Name:    ${MYSQL_DATABASE}
Database User:    ${MYSQL_USER}
User Password:    ${MYSQL_PASSWORD}
Root Password:    ${MYSQL_ROOT_PASSWORD}

Database Host (internal):  mysql
Database Host (external):  localhost:3306

Redis Configuration:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Redis Host:       redis (internal) or localhost:6379 (external)
Redis Password:   ${REDIS_PASSWORD}

MySQL Performance Settings:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
InnoDB Buffer Pool:  ${MYSQL_INNODB_BUFFER_POOL_SIZE}
InnoDB Log File:     ${MYSQL_INNODB_LOG_FILE_SIZE}
Max Connections:     200

⚠️  IMPORTANT SECURITY NOTES:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Store this file securely and do not commit it to version control
• The credentials/ directory is added to .gitignore
• Change these passwords if this file is ever compromised
• For production, consider using a password manager or secrets vault

Useful Docker Commands:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
docker compose ps                 # Check container status
docker compose logs -f php        # View PHP logs
docker compose exec php bash      # Access PHP container
docker compose exec mysql mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}
docker compose down               # Stop all containers
docker compose up -d              # Start all containers

EOF

    # Add credentials directory to .gitignore
    if [ ! -f ".gitignore" ]; then
        echo "credentials/" > .gitignore
        print_success "Created .gitignore with credentials/ directory"
    elif ! grep -q "credentials/" .gitignore 2>/dev/null; then
        echo "credentials/" >> .gitignore
        print_success "Added credentials/ to .gitignore"
    fi
    
    print_success "Credentials saved to: ${CREDENTIALS_FILE}"
    print_warning "Keep this file secure and do not commit it to version control!"
}

# Ask about Laravel starter kit
ask_starter_kit() {
    echo -e "\n${GREEN}Laravel Starter Kit${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Choose a starter kit for your Laravel application:"
    echo ""
    echo "  1) Laravel only - No starter kit (blank Laravel)"
    echo "  2) React - Modern SPA with React, Inertia & shadcn/ui"
    echo "  3) Vue - Modern SPA with Vue, Inertia & shadcn-vue"
    echo "  4) Livewire - Dynamic frontend with Livewire & Flux UI"
    echo ""
    echo "Learn more: ${CYAN}https://laravel.com/docs/starter-kits${NC}"
    echo ""
    
    read -p "Select option [1-4]: " starter_choice
    
    case $starter_choice in
        1)
            STARTER_KIT="none"
            print_success "Will install Laravel without starter kit"
            ;;
        2)
            STARTER_KIT="react"
            print_success "Will install Laravel with React starter kit"
            ;;
        3)
            STARTER_KIT="vue"
            print_success "Will install Laravel with Vue starter kit"
            ;;
        4)
            STARTER_KIT="livewire"
            print_success "Will install Laravel with Livewire starter kit"
            ;;
        *)
            STARTER_KIT="none"
            print_warning "Invalid option. Installing Laravel without starter kit"
            ;;
    esac
}

# Ask about Laravel installation
ask_laravel_installation() {
    echo -e "\n${GREEN}Laravel Installation${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Would you like to install a fresh Laravel application?"
    echo ""
    echo "  1) Yes - Install fresh Laravel (latest version)"
    echo "  2) No  - I have an existing Laravel app in ./app directory"
    echo ""
    
    read -p "Select option [1-2]: " laravel_choice
    
    case $laravel_choice in
        1)
            INSTALL_LARAVEL=true
            print_success "Will install fresh Laravel after Docker setup"
            ;;
        2)
            INSTALL_LARAVEL=false
            STARTER_KIT="none"
            
            if [ ! -f "./app/public/index.php" ]; then
                print_warning "No Laravel app found in ./app directory"
                print_info "You'll need to place your Laravel application there before starting"
            else
                print_success "Existing Laravel app detected"
            fi
            ;;
        *)
            INSTALL_LARAVEL=false
            STARTER_KIT="none"
            print_info "Skipping Laravel installation"
            ;;
    esac
}

# Create .env file
create_env_file() {
    echo -e "\n${GREEN}Creating Configuration${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Get user UID/GID
    USER_ID=$(id -u)
    GROUP_ID=$(id -g)
    
    # Generate Redis password
    REDIS_PASSWORD=$(generate_password)
    
    cat > .env << EOF
# Laravel Production Docker Configuration
# Generated: $(date)

# User Permissions (matches your system user)
UID=${USER_ID}
GID=${GROUP_ID}

# PHP Version Selection (8.1, 8.2, 8.3, or 8.4)
PHP_VERSION=${PHP_VERSION}

# Application Configuration
APP_NAME=Laravel
APP_ENV=production
APP_URL=${APP_URL}
APP_DOMAIN=${APP_DOMAIN}

# Database Configuration
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=${MYSQL_DATABASE}
DB_USERNAME=${MYSQL_USER}
DB_PASSWORD=${MYSQL_PASSWORD}

# MySQL Root Password
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_DATABASE=${MYSQL_DATABASE}
MYSQL_USER=${MYSQL_USER}
MYSQL_PASSWORD=${MYSQL_PASSWORD}

# MySQL Performance Tuning (${ram_choice} RAM configuration)
MYSQL_INNODB_BUFFER_POOL_SIZE=${MYSQL_INNODB_BUFFER_POOL_SIZE}
MYSQL_INNODB_LOG_FILE_SIZE=${MYSQL_INNODB_LOG_FILE_SIZE}
MYSQL_MAX_CONNECTIONS=200
MYSQL_QUERY_CACHE_SIZE=0
MYSQL_QUERY_CACHE_TYPE=0
MYSQL_INNODB_FLUSH_LOG_AT_TRX_COMMIT=2

# Redis Configuration
REDIS_HOST=redis
REDIS_PASSWORD=${REDIS_PASSWORD}
REDIS_PORT=6379
CACHE_DRIVER=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis

# Broadcasting (if using)
BROADCAST_DRIVER=redis

# PHP Configuration
PHP_MEMORY_LIMIT=512M
PHP_UPLOAD_MAX_FILESIZE=100M
PHP_POST_MAX_SIZE=100M

# Timezone
TZ=UTC
EOF

    print_success "Created .env file with your configuration"
    
    # Save credentials to credentials folder
    save_credentials
    
    # Update nginx vhost config with domain
    print_info "Updating nginx configuration with domain: ${APP_DOMAIN}"
    sed -i.bak "s/server_name .*/server_name ${APP_DOMAIN};/" config/vhosts/default.conf
    rm -f config/vhosts/default.conf.bak
    print_success "Nginx configuration updated"
    
    # Create app/.env if installing Laravel
    if [ "$INSTALL_LARAVEL" = true ]; then
        print_info "Laravel .env will be created during installation"
    fi
}

# Install Laravel
install_laravel() {
    if [ "$INSTALL_LARAVEL" = true ]; then
        echo -e "\n${GREEN}Installing Laravel${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        print_info "Building PHP container..."
        docker compose build php
        
        print_info "Installing Laravel (this may take a few minutes)..."
        
        # Remove app directory contents if it exists
        if [ -d "./app" ]; then
            print_info "Cleaning existing app directory..."
            rm -rf ./app/*
            rm -rf ./app/.[!.]*
        else
            mkdir -p ./app
        fi
        
        # Create Laravel project with or without starter kit
        if [ "$STARTER_KIT" = "none" ]; then
            print_info "Installing Laravel (without starter kit)..."
            docker compose run --rm php composer create-project laravel/laravel /var/www/html --no-interaction
        else
            print_info "Installing Laravel with ${STARTER_KIT^} starter kit..."
            docker compose run --rm php composer create-project laravel/laravel /var/www/html "--starter-kit=${STARTER_KIT}" --no-interaction
            
            # Install frontend dependencies for starter kits
            print_info "Installing frontend dependencies..."
            docker compose run --rm php sh -c "cd /var/www/html && npm install && npm run build"
        fi
        
        print_success "Laravel installed successfully"
        
        # Update Laravel .env
        print_info "Configuring Laravel environment..."
        
        docker compose run --rm php sh -c "cp /var/www/html/.env.example /var/www/html/.env"
        
        # Update database configuration in Laravel .env
        # Laravel 11+ comments out DB_ lines by default, so uncomment them first
        docker compose run --rm php sh -c "cd /var/www/html && \
            sed -i 's/^# DB_CONNECTION=/DB_CONNECTION=/' .env && \
            sed -i 's/^# DB_HOST=/DB_HOST=/' .env && \
            sed -i 's/^# DB_PORT=/DB_PORT=/' .env && \
            sed -i 's/^# DB_DATABASE=/DB_DATABASE=/' .env && \
            sed -i 's/^# DB_USERNAME=/DB_USERNAME=/' .env && \
            sed -i 's/^# DB_PASSWORD=/DB_PASSWORD=/' .env && \
            sed -i 's/^DB_CONNECTION=.*/DB_CONNECTION=mysql/' .env && \
            sed -i 's/^DB_HOST=.*/DB_HOST=mysql/' .env && \
            sed -i 's/^DB_PORT=.*/DB_PORT=3306/' .env"
        
        # Set database credentials using printf to handle special characters
        docker compose run --rm php sh -c "cd /var/www/html && \
            sed -i \"s/^DB_DATABASE=.*/DB_DATABASE=${MYSQL_DATABASE}/\" .env && \
            sed -i \"s/^DB_USERNAME=.*/DB_USERNAME=${MYSQL_USER}/\" .env"
        
        # Handle password with special characters by using a temp file
        docker compose run --rm php sh -c "cd /var/www/html && \
            grep -v '^DB_PASSWORD=' .env > .env.tmp && \
            echo \"DB_PASSWORD=${MYSQL_PASSWORD}\" >> .env.tmp && \
            mv .env.tmp .env"
        
        # Update APP_URL
        docker compose run --rm php sh -c "cd /var/www/html && \
            sed -i \"s|^APP_URL=.*|APP_URL=${APP_URL}|\" .env"
        
        # Generate app key
        print_info "Generating application key..."
        docker compose run --rm php sh -c "cd /var/www/html && php artisan key:generate"
        
        print_success "Laravel configured"
    fi
}

# Start containers
start_containers() {
    echo -e "\n${GREEN}Starting Docker Containers${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Remove any existing containers and volumes for fresh start
    print_info "Removing any existing containers and volumes..."
    docker compose down -v 2>/dev/null || true
    
    print_info "Building and starting containers..."
    docker compose up -d --build
    
    print_info "Waiting for services to be healthy (this may take 30-60 seconds)..."
    sleep 10
    
    # Wait for MySQL to be ready
    max_attempts=30
    attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if docker compose exec -T mysql mysqladmin ping -h localhost --silent; then
            print_success "MySQL is ready"
            break
        fi
        attempt=$((attempt + 1))
        sleep 2
    done
    
    if [ "$INSTALL_LARAVEL" = true ]; then
        print_info "Running Laravel migrations..."
        docker compose exec -T php php artisan migrate --force
        
        print_info "Optimizing Laravel..."
        docker compose exec -T php php artisan config:cache
        docker compose exec -T php php artisan route:cache
        docker compose exec -T php php artisan view:cache
    fi
    
    print_success "All containers started successfully"
}

# Display summary
display_summary() {
    echo -e "\n${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Setup Complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}\n"
    
    echo -e "${BLUE}Application URL:${NC}       ${APP_URL}"
    echo -e "${BLUE}PHP Version:${NC}           ${PHP_VERSION}"
    echo -e "${BLUE}Database Host:${NC}         mysql (internal) or localhost:3306 (external)"
    echo -e "${BLUE}Database Name:${NC}         ${MYSQL_DATABASE}"
    echo -e "${BLUE}Database User:${NC}         ${MYSQL_USER}"
    echo -e "${BLUE}MySQL Config:${NC}          Buffer: ${MYSQL_INNODB_BUFFER_POOL_SIZE}, Logs: ${MYSQL_INNODB_LOG_FILE_SIZE}"
    echo ""
    
    if [ "$INSTALL_LARAVEL" = true ]; then
        if [ "$STARTER_KIT" != "none" ]; then
            echo -e "${GREEN}Fresh Laravel application with ${STARTER_KIT^} starter kit installed!${NC}"
        else
            echo -e "${GREEN}Fresh Laravel application installed!${NC}"
        fi
        echo ""
    fi
    
    echo -e "${YELLOW}Important Credentials (save these securely):${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "MySQL User Password:  ${MYSQL_PASSWORD}"
    echo -e "MySQL Root Password:  ${MYSQL_ROOT_PASSWORD}"
    echo -e "Redis Password:       ${REDIS_PASSWORD}"
    echo ""
    echo -e "${GREEN}✓ Credentials have been saved to the credentials/ folder${NC}"
    echo ""
    
    echo -e "${BLUE}Useful Commands:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  docker compose ps                 # Check container status"
    echo "  docker compose logs -f php8.4     # View PHP logs"
    echo "  docker compose exec php8.4 bash   # Access PHP container"
    echo "  docker compose down               # Stop all containers"
    echo "  docker compose up -d              # Start all containers"
    echo ""
    
    if [ "$APP_DOMAIN" != "localhost" ]; then
        echo -e "${YELLOW}Next Steps:${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  1. Point your domain (${APP_DOMAIN}) to this server's IP"
        echo "  2. Configure SSL certificates (see SECURITY.md)"
        echo "  3. Update firewall rules to allow ports 80 and 443"
        echo "  4. Review .env file and adjust settings as needed"
        echo ""
    fi
    
    print_success "Your Laravel production environment is ready!"
}

# Main execution
main() {
    print_header
    
    # Warning about data deletion
    echo -e "${YELLOW}⚠️  WARNING ⚠️${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${RED}This setup script will:${NC}"
    echo -e "  ${RED}•${NC} Remove any existing Docker containers"
    echo -e "  ${RED}•${NC} Delete all Docker volumes (including database data)"
    echo -e "  ${RED}•${NC} Overwrite .env configuration file"
    echo ""
    echo -e "${YELLOW}If you have existing data, back it up before continuing!${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    read -p "Do you want to continue? [y/N]: " confirm_setup
    if [[ ! $confirm_setup =~ ^[Yy]$ ]]; then
        print_error "Setup cancelled by user."
        exit 0
    fi
    echo ""
    
    # Check prerequisites
    check_docker
    
    # Check if .env already exists
    if [ -f ".env" ]; then
        print_warning ".env file already exists"
        read -p "Do you want to overwrite it? [y/N]: " overwrite
        if [[ ! $overwrite =~ ^[Yy]$ ]]; then
            print_error "Setup cancelled. Remove or rename .env to run setup again."
            exit 1
        fi
    fi
    
    # Gather configuration
    get_ram_config
    get_php_version
    get_domain
    get_database_credentials
    ask_laravel_installation
    
    # Ask about starter kit if installing Laravel
    if [ "$INSTALL_LARAVEL" = true ]; then
        ask_starter_kit
    fi
    
    # Create configuration files
    create_env_file
    
    # Install Laravel if requested
    if [ "$INSTALL_LARAVEL" = true ]; then
        install_laravel
    fi
    
    # Start containers
    start_containers
    
    # Show summary
    display_summary
}

# Run main function
main
