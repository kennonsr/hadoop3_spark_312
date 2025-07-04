#!/bin/bash

# Minimal Hive Docker Build Script
# This script builds only the essential containers for a simplified Hive setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_info "Docker is running"
}

# Function to show help
show_help() {
    echo "Minimal Hive Docker Build Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -c, --clean    Clean existing images before building"
    echo "  -b, --build    Build images (default)"
    echo "  -r, --run      Build and run containers"
    echo "  -s, --stop     Stop running containers"
    echo "  -d, --down     Stop and remove containers"
    echo ""
    echo "Examples:"
    echo "  $0                 # Build images"
    echo "  $0 --clean --run   # Clean, build, and run"
    echo "  $0 --stop          # Stop containers"
    echo ""
}

# Function to clean existing images
clean_images() {
    print_info "Cleaning existing images..."
    
    # Stop and remove containers if running
    docker-compose -f docker-compose-minimal.yml down 2>/dev/null || true
    
    # Remove images
    docker rmi kennon/hadoop:hive-minimal 2>/dev/null || true
    docker rmi kennon/hadoop:postgres-hms 2>/dev/null || true
    
    # Clean up dangling images
    docker image prune -f >/dev/null 2>&1 || true
    
    print_success "Cleanup complete"
}

# Function to build PostgreSQL HMS image
build_postgres_hms() {
    print_info "Building PostgreSQL Hive Metastore image..."
    
    if docker build -f postgres-hms/Dockerfile -t kennon/hadoop:postgres-hms . ; then
        print_success "PostgreSQL HMS image built: kennon/hadoop:postgres-hms"
    else
        print_error "Failed to build PostgreSQL HMS image"
        exit 1
    fi
}

# Function to build minimal Hive image
build_hive_minimal() {
    print_info "Building Minimal Hive image..."
    print_info "This may take several minutes..."
    
    if docker build -f hive-minimal/Dockerfile -t kennon/hadoop:hive-minimal . ; then
        print_success "Minimal Hive image built: kennon/hadoop:hive-minimal"
    else
        print_error "Failed to build Minimal Hive image"
        exit 1
    fi
}

# Function to build all images
build_images() {
    print_info "Starting build process for Minimal Hive setup..."
    print_info "Images to build:"
    print_info "  - kennon/hadoop:postgres-hms (PostgreSQL Hive Metastore)"
    print_info "  - kennon/hadoop:hive-minimal (Minimal Hive with local filesystem)"
    echo ""
    
    build_postgres_hms
    build_hive_minimal
    
    print_success "All images built successfully!"
    
    # Show image sizes
    print_info "Image sizes:"
    docker images | grep "kennon/hadoop" | grep -E "(postgres-hms|hive-minimal)"
}

# Function to run containers
run_containers() {
    print_info "Starting containers with docker-compose..."
    
    if docker-compose -f docker-compose-minimal.yml up -d; then
        print_success "Containers started successfully!"
        print_info "Services:"
        print_info "  - PostgreSQL Metastore: localhost:5432"
        print_info "  - Hive Metastore: localhost:9083"
        print_info "  - HiveServer2: localhost:10000"
        print_info ""
        print_info "Connect with Beeline:"
        print_info "  docker exec -it hive-server beeline -u \"jdbc:hive2://localhost:10000/\""
        print_info ""
        print_info "Check logs:"
        print_info "  docker-compose -f docker-compose-minimal.yml logs -f hive-server"
    else
        print_error "Failed to start containers"
        exit 1
    fi
}

# Function to stop containers
stop_containers() {
    print_info "Stopping containers..."
    docker-compose -f docker-compose-minimal.yml stop
    print_success "Containers stopped"
}

# Function to stop and remove containers
down_containers() {
    print_info "Stopping and removing containers..."
    docker-compose -f docker-compose-minimal.yml down
    print_success "Containers stopped and removed"
}

# Function to show status
show_status() {
    print_info "Container status:"
    docker-compose -f docker-compose-minimal.yml ps
}

# Main function
main() {
    local clean=false
    local build=true
    local run=false
    local stop=false
    local down=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--clean)
                clean=true
                shift
                ;;
            -b|--build)
                build=true
                shift
                ;;
            -r|--run)
                build=true
                run=true
                shift
                ;;
            -s|--stop)
                stop=true
                build=false
                shift
                ;;
            -d|--down)
                down=true
                build=false
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Check Docker
    check_docker
    
    # Execute actions
    if [ "$down" = true ]; then
        down_containers
    elif [ "$stop" = true ]; then
        stop_containers
    else
        if [ "$clean" = true ]; then
            clean_images
        fi
        
        if [ "$build" = true ]; then
            build_images
        fi
        
        if [ "$run" = true ]; then
            run_containers
        fi
    fi
    
    # Show final status
    if [ "$build" = true ] || [ "$run" = true ]; then
        echo ""
        show_status
    fi
}

# Run main function with all arguments
main "$@"