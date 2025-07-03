#!/bin/bash

# Simple Docker build script with architecture detection
# Builds images with the same tags as specified in README.md

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_usage() {
    echo "Usage: $0 [--clean] [--help]"
    echo ""
    echo "Options:"
    echo "  --clean    Remove existing images before building"
    echo "  --help     Show this help message"
    echo ""
    echo "This script detects your architecture and builds the appropriate Docker images:"
    echo "  - kennon/hadoop:hadoop_334 (Hadoop base image)"
    echo "  - kennon/hadoop:spark_312 (Spark image)"
    echo "  - kennon/hadoop:postgres-hms (PostgreSQL Hive Metastore)"
}

# Detect architecture and set Dockerfile path
detect_arch() {
    local arch=$(uname -m)
    case $arch in
        arm64|aarch64)
            echo "hadoop_arm64/Dockerfile"
            ;;
        x86_64|amd64)
            echo "Dockerfile"
            ;;
        *)
            print_error "Unsupported architecture: $arch"
            print_error "Supported: arm64, aarch64, x86_64, amd64"
            exit 1
            ;;
    esac
}

# Clean existing images
clean_images() {
    print_info "Cleaning existing images..."
    docker rmi kennon/hadoop:hadoop_334 2>/dev/null || true
    docker rmi kennon/hadoop:spark_312 2>/dev/null || true
    docker rmi kennon/hadoop:postgres-hms 2>/dev/null || true
    print_success "Cleanup completed"
}

# Build images
build_images() {
    local hadoop_dockerfile=$(detect_arch)
    local arch_name=$(uname -m)
    
    print_info "Detected architecture: $arch_name"
    print_info "Using Hadoop Dockerfile: $hadoop_dockerfile"
    
    # Build Hadoop image
    print_info "Building Hadoop image..."
    docker build -f "$hadoop_dockerfile" -t kennon/hadoop:hadoop_334 .
    print_success "Hadoop image built: kennon/hadoop:hadoop_334"
    
    # Build Spark image
    print_info "Building Spark image..."
    docker build -f ./spark/Dockerfile -t kennon/hadoop:spark_312 .
    print_success "Spark image built: kennon/hadoop:spark_312"
    
    # Build PostgreSQL HMS image
    print_info "Building PostgreSQL HMS image..."
    docker build -f ./postgres-hms/Dockerfile -t kennon/hadoop:postgres-hms .
    print_success "PostgreSQL HMS image built: kennon/hadoop:postgres-hms"
    
    print_success "All images built successfully!"
    
    # Show built images
    echo ""
    print_info "Built images:"
    docker images kennon/hadoop --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
}

# Main
main() {
    local clean=false
    
    # Parse arguments
    for arg in "$@"; do
        case $arg in
            --clean)
                clean=true
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $arg"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Check Docker
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running"
        exit 1
    fi
    
    # Clean if requested
    if [ "$clean" = true ]; then
        clean_images
    fi
    
    # Build images
    build_images
}

main "$@"