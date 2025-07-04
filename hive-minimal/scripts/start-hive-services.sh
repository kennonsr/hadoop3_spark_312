#!/bin/bash
set -e

echo "=========================================="
echo "Starting Minimal Hive Services"
echo "=========================================="

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to wait for PostgreSQL
wait_for_postgres() {
    log "Waiting for PostgreSQL to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if pg_isready -h psqlhms -p 5432 -U postgres >/dev/null 2>&1; then
            log "PostgreSQL is ready!"
            return 0
        fi
        log "Attempt $attempt/$max_attempts: PostgreSQL not ready, waiting..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    log "ERROR: PostgreSQL failed to become ready after $max_attempts attempts"
    exit 1
}

# Function to test metastore connection
test_metastore_connection() {
    log "Testing metastore database connection..."
    if hive --service schemaTool -dbType postgres -info >/dev/null 2>&1; then
        log "Metastore schema is valid"
        return 0
    else
        log "WARNING: Metastore schema validation failed, but continuing..."
        return 0
    fi
}

# Function to start Hive Metastore Service
start_metastore() {
    log "Starting Hive Metastore Service..."
    
    # Create log directory if it doesn't exist
    mkdir -p /opt/hive/logs
    
    # Start metastore in background
    nohup hive --service metastore > /opt/hive/logs/metastore.log 2>&1 &
    local metastore_pid=$!
    
    log "Metastore started with PID: $metastore_pid"
    
    # Wait for metastore to be ready
    local max_attempts=15
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if netstat -tlnp 2>/dev/null | grep -q ":9083.*LISTEN" || ss -tlnp 2>/dev/null | grep -q ":9083.*LISTEN"; then
            log "Hive Metastore Service is ready on port 9083"
            return 0
        fi
        log "Attempt $attempt/$max_attempts: Waiting for Metastore to start..."
        sleep 3
        attempt=$((attempt + 1))
    done
    
    log "ERROR: Metastore failed to start properly"
    log "Metastore logs:"
    tail -20 /opt/hive/logs/metastore.log
    exit 1
}

# Function to start HiveServer2
start_hiveserver2() {
    log "Starting HiveServer2..."
    
    # Test metastore connection first
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if hive --service metatool -listFSRoot >/dev/null 2>&1; then
            log "Metastore connection verified"
            break
        fi
        log "Attempt $attempt/$max_attempts: Testing metastore connection..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    # Start HiveServer2 (this will run in foreground)
    log "HiveServer2 starting on port 10000..."
    log "Container is ready for Beeline connections!"
    log "Connect with: beeline -u \"jdbc:hive2://localhost:10000/\""
    log "=========================================="
    
    exec hive --service hiveserver2
}

# Function to setup warehouse directory
setup_warehouse() {
    log "Setting up warehouse directory..."
    
    # Create warehouse directory with proper permissions
    mkdir -p /opt/hive/warehouse
    chmod 777 /opt/hive/warehouse
    chown hadoop:hadoop /opt/hive/warehouse
    
    # Create temp directories
    mkdir -p /tmp/hive /tmp/hive_resources
    chmod 777 /tmp/hive /tmp/hive_resources
    
    log "Warehouse directory setup complete: /opt/hive/warehouse"
}

# Function to display configuration info
show_config_info() {
    log "=========================================="
    log "Configuration Information:"
    log "- Warehouse: file:///opt/hive/warehouse"
    log "- Metastore: PostgreSQL at psqlhms:5432"
    log "- Metastore Service: port 9083"
    log "- HiveServer2: port 10000"
    log "- Logs: /opt/hive/logs/"
    log "=========================================="
}

# Function to cleanup on exit
cleanup() {
    log "Shutting down Hive services..."
    pkill -f "hive.*metastore" || true
    pkill -f "hive.*hiveserver2" || true
    log "Cleanup complete"
}

# Set trap for cleanup
trap cleanup EXIT INT TERM

# Main execution
main() {
    log "Initializing Hive Minimal Setup..."
    
    # Show configuration
    show_config_info
    
    # Wait for PostgreSQL
    wait_for_postgres
    
    # Setup warehouse
    setup_warehouse
    
    # Test metastore connection
    test_metastore_connection
    
    # Start Metastore Service
    start_metastore
    
    # Start HiveServer2 (runs in foreground)
    start_hiveserver2
}

# Run main function
main "$@"