#!/bin/bash

# Test script for Minimal Hive Setup
# This script validates that the Hive services are working correctly

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

# Function to wait for service
wait_for_service() {
    local service_name=$1
    local port=$2
    local max_attempts=30
    local attempt=1
    
    print_info "Waiting for $service_name on port $port..."
    
    while [ $attempt -le $max_attempts ]; do
        if docker exec hive-server netstat -tlnp 2>/dev/null | grep -q ":$port.*LISTEN" || \
           docker exec hive-server ss -tlnp 2>/dev/null | grep -q ":$port.*LISTEN"; then
            print_success "$service_name is ready on port $port"
            return 0
        fi
        print_info "Attempt $attempt/$max_attempts: Waiting for $service_name..."
        sleep 3
        attempt=$((attempt + 1))
    done
    
    print_error "$service_name failed to start on port $port"
    return 1
}

# Function to test PostgreSQL connection
test_postgres() {
    print_info "Testing PostgreSQL connection..."
    
    if docker exec psqlhms pg_isready -U postgres >/dev/null 2>&1; then
        print_success "PostgreSQL is accessible"
    else
        print_error "PostgreSQL is not accessible"
        return 1
    fi
    
    # Test metastore database
    if docker exec psqlhms psql -U hive -d metastore -c "SELECT 1;" >/dev/null 2>&1; then
        print_success "Hive metastore database is accessible"
    else
        print_error "Hive metastore database is not accessible"
        return 1
    fi
}

# Function to test Hive Metastore Service
test_metastore() {
    print_info "Testing Hive Metastore Service..."
    
    if wait_for_service "Hive Metastore" "9083"; then
        # Test metastore functionality
        if docker exec hive-server hive --service metatool -listFSRoot >/dev/null 2>&1; then
            print_success "Hive Metastore Service is functional"
        else
            print_warning "Hive Metastore Service is running but may have issues"
        fi
    else
        return 1
    fi
}

# Function to test HiveServer2
test_hiveserver2() {
    print_info "Testing HiveServer2..."
    
    if wait_for_service "HiveServer2" "10000"; then
        print_success "HiveServer2 is running"
    else
        return 1
    fi
}

# Function to test Beeline connection
test_beeline() {
    print_info "Testing Beeline connection..."
    
    # Create a simple test query
    local test_query="SHOW DATABASES;"
    
    if docker exec hive-server beeline -u "jdbc:hive2://localhost:10000/" -e "$test_query" >/dev/null 2>&1; then
        print_success "Beeline connection successful"
    else
        print_error "Beeline connection failed"
        return 1
    fi
}

# Function to test table operations
test_table_operations() {
    print_info "Testing table operations..."
    
    local test_db="test_minimal_hive"
    local test_table="test_table"
    
    # SQL commands for testing
    local sql_commands="
    DROP DATABASE IF EXISTS $test_db CASCADE;
    CREATE DATABASE $test_db;
    USE $test_db;
    CREATE TABLE $test_table (
        id INT,
        name STRING,
        created_date DATE
    );
    INSERT INTO $test_table VALUES 
        (1, 'Test User 1', '2024-01-01'),
        (2, 'Test User 2', '2024-01-02');
    SELECT COUNT(*) FROM $test_table;
    SELECT * FROM $test_table;
    DESCRIBE FORMATTED $test_table;
    DROP TABLE $test_table;
    DROP DATABASE $test_db;
    "
    
    if docker exec hive-server beeline -u "jdbc:hive2://localhost:10000/" -e "$sql_commands" >/dev/null 2>&1; then
        print_success "Table operations successful"
    else
        print_error "Table operations failed"
        return 1
    fi
}

# Function to test warehouse directory
test_warehouse() {
    print_info "Testing warehouse directory..."
    
    if docker exec hive-server test -d /opt/hive/warehouse; then
        print_success "Warehouse directory exists"
        
        # Check permissions
        local perms=$(docker exec hive-server stat -c "%a" /opt/hive/warehouse)
        if [ "$perms" = "777" ]; then
            print_success "Warehouse directory has correct permissions (777)"
        else
            print_warning "Warehouse directory permissions: $perms (expected: 777)"
        fi
    else
        print_error "Warehouse directory does not exist"
        return 1
    fi
}

# Function to show service status
show_status() {
    print_info "Service Status:"
    echo "----------------------------------------"
    docker-compose -f docker-compose-minimal.yml ps
    echo "----------------------------------------"
    
    print_info "Port Status:"
    echo "PostgreSQL (5432):"
    docker exec psqlhms netstat -tlnp | grep :5432 || echo "  Not listening"
    echo "Metastore (9083):"
    docker exec hive-server netstat -tlnp | grep :9083 || echo "  Not listening"
    echo "HiveServer2 (10000):"
    docker exec hive-server netstat -tlnp | grep :10000 || echo "  Not listening"
    echo "----------------------------------------"
}

# Function to show logs
show_logs() {
    print_info "Recent Hive Server logs:"
    echo "----------------------------------------"
    docker-compose -f docker-compose-minimal.yml logs --tail=20 hive-server
    echo "----------------------------------------"
}

# Function to run all tests
run_all_tests() {
    print_info "Starting Minimal Hive Test Suite"
    print_info "================================="
    
    local failed_tests=0
    
    # Check if containers are running
    if ! docker-compose -f docker-compose-minimal.yml ps | grep -q "Up"; then
        print_error "Containers are not running. Please start them first:"
        print_info "  ./build-minimal.sh --run"
        exit 1
    fi
    
    # Run tests
    test_postgres || ((failed_tests++))
    test_metastore || ((failed_tests++))
    test_hiveserver2 || ((failed_tests++))
    test_beeline || ((failed_tests++))
    test_warehouse || ((failed_tests++))
    test_table_operations || ((failed_tests++))
    
    # Show results
    echo ""
    print_info "Test Results:"
    print_info "============="
    
    if [ $failed_tests -eq 0 ]; then
        print_success "All tests passed! ✅"
        print_info "Your Minimal Hive setup is working correctly."
        print_info ""
        print_info "Connect with: docker exec -it hive-server beeline -u \"jdbc:hive2://localhost:10000/\""
    else
        print_error "$failed_tests test(s) failed! ❌"
        print_info "Check the logs for more details:"
        show_logs
    fi
    
    return $failed_tests
}

# Function to show help
show_help() {
    echo "Minimal Hive Test Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help       Show this help message"
    echo "  -s, --status     Show service status"
    echo "  -l, --logs       Show recent logs"
    echo "  -t, --test       Run all tests (default)"
    echo "  --postgres       Test PostgreSQL only"
    echo "  --metastore      Test Metastore only"
    echo "  --hiveserver2    Test HiveServer2 only"
    echo "  --beeline        Test Beeline only"
    echo "  --warehouse      Test warehouse directory only"
    echo "  --tables         Test table operations only"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run all tests"
    echo "  $0 --status           # Show service status"
    echo "  $0 --beeline          # Test Beeline connection only"
    echo ""
}

# Main function
main() {
    case "${1:-test}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -s|--status)
            show_status
            exit 0
            ;;
        -l|--logs)
            show_logs
            exit 0
            ;;
        -t|--test)
            run_all_tests
            exit $?
            ;;
        --postgres)
            test_postgres
            exit $?
            ;;
        --metastore)
            test_metastore
            exit $?
            ;;
        --hiveserver2)
            test_hiveserver2
            exit $?
            ;;
        --beeline)
            test_beeline
            exit $?
            ;;
        --warehouse)
            test_warehouse
            exit $?
            ;;
        --tables)
            test_table_operations
            exit $?
            ;;
        *)
            run_all_tests
            exit $?
            ;;
    esac
}

# Run main function with all arguments
main "$@"