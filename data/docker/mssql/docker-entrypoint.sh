#!/bin/bash
set -e

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ENTRYPOINT] $1"
}

# Function to wait for SQL Server to start
wait_for_sql_server() {
    local timeout=60
    local counter=0
    
    log "Waiting for SQL Server to start..."
    
    while [ $counter -lt $timeout ]; do
        if /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -Q "SELECT 1" -C -b > /dev/null 2>&1; then
            log "SQL Server is ready!"
            return 0
        fi
        counter=$((counter + 1))
        sleep 1
    done
    
    log "ERROR: SQL Server failed to start within ${timeout} seconds"
    return 1
}

# Check if required environment variables are set
if [ -z "$SA_PASSWORD" ]; then
    log "ERROR: SA_PASSWORD environment variable must be set"
    exit 1
fi

if [ -z "$ACCEPT_EULA" ] || [ "$ACCEPT_EULA" != "Y" ]; then
    log "ERROR: ACCEPT_EULA must be set to 'Y'"
    exit 1
fi

# Set default values for optional environment variables
export MSSQL_PID=${MSSQL_PID:-Developer}
export MSSQL_AGENT_ENABLED=${MSSQL_AGENT_ENABLED:-false}

log "Starting SQL Server configuration..."

# Debug: Show what's available
log "=== Debug Information ==="
log "Available SQL Server files:"
find /opt /usr -name "*mssql*" -o -name "*sqlservr*" -o -name "*sql*" 2>/dev/null | head -20 || echo "No SQL files found"

# Find the correct path for mssql-conf with more comprehensive search
MSSQL_CONF_PATH=""
for path in "/opt/mssql/bin/mssql-conf" "/usr/bin/mssql-conf" "/opt/mssql-tools/bin/mssql-conf" "/opt/mssql-server/bin/mssql-conf"; do
    if [ -f "$path" ]; then
        MSSQL_CONF_PATH="$path"
        break
    fi
done

# If not found in standard locations, search for it
if [ -z "$MSSQL_CONF_PATH" ]; then
    MSSQL_CONF_PATH=$(find /opt /usr -name "mssql-conf" -type f 2>/dev/null | head -1)
fi

# Configure SQL Server if mssql-conf is available
if [ -n "$MSSQL_CONF_PATH" ] && [ -f "$MSSQL_CONF_PATH" ]; then
    log "Found mssql-conf at: $MSSQL_CONF_PATH"
    
    # Check if we need to initialize SQL Server
    if [ ! -f "/var/opt/mssql/data/master.mdf" ]; then
        log "SQL Server data directory needs initialization"
        log "Setting up SQL Server with provided credentials..."
        
        # Set environment variables for SQL Server setup
        export ACCEPT_EULA=Y
        export MSSQL_SA_PASSWORD="$SA_PASSWORD"
        export MSSQL_PID="$MSSQL_PID"
        
        # Check if we're running as root or mssql user
        if [ "$(id -u)" = "0" ]; then
            log "Running as root - performing SQL Server setup"
            "$MSSQL_CONF_PATH" -n setup accept-eula
        else
            log "Running as mssql user - SQL Server will auto-initialize on first start"
            log "Environment variables are set for automatic setup"
        fi
    else
        log "SQL Server data directory already initialized"
    fi
else
    log "mssql-conf not found, SQL Server will use environment variables for setup"
    
    # Set environment variables for SQL Server
    export ACCEPT_EULA=Y
    export MSSQL_SA_PASSWORD="$SA_PASSWORD"
    export MSSQL_PID="$MSSQL_PID"
fi

# Create necessary directories with proper permissions
mkdir -p /var/opt/mssql/data
mkdir -p /var/opt/mssql/log  
mkdir -p /var/opt/mssql/secrets

# Find the SQL Server binary with comprehensive search
SQLSERVR_PATH=""
for path in "/opt/mssql/bin/sqlservr" "/usr/bin/sqlservr" "/opt/mssql-server/bin/sqlservr"; do
    if [ -f "$path" ]; then
        SQLSERVR_PATH="$path"
        break
    fi
done

# If not found in standard locations, search for it
if [ -z "$SQLSERVR_PATH" ]; then
    SQLSERVR_PATH=$(find /opt /usr -name "sqlservr" -type f 2>/dev/null | head -1)
fi

if [ -z "$SQLSERVR_PATH" ]; then
    log "ERROR: SQL Server binary (sqlservr) not found"
    log "=== Debugging Information ==="
    log "Searching for any SQL Server related files:"
    find /opt /usr -type f \( -name "*sql*" -o -name "*mssql*" \) 2>/dev/null | head -20 || echo "No SQL files found"
    log "Installed packages:"
    rpm -qa | grep -i sql || echo "No SQL packages found"
    log "Directory structure:"
    ls -la /opt/ 2>/dev/null || echo "/opt directory not accessible"
    ls -la /usr/bin/ | grep sql 2>/dev/null || echo "No sql binaries in /usr/bin"
    exit 1
fi

log "Found SQL Server binary at: $SQLSERVR_PATH"

# Run custom initialization scripts if they exist
if [ -d "/opt/mssql/scripts" ]; then
    log "Running initialization scripts..."
    for script in /opt/mssql/scripts/*.sh; do
        if [ -f "$script" ]; then
            log "Running $script"
            chmod +x "$script"
            "$script"
        fi
    done
    
    # Run SQL scripts after SQL Server starts
    if ls /opt/mssql/scripts/*.sql 1> /dev/null 2>&1; then
        log "SQL scripts found, will run after SQL Server starts"
        (
            # Start SQL Server in background for script execution
            "$SQLSERVR_PATH" &
            SQL_PID=$!
            
            # Wait for SQL Server to be ready
            if wait_for_sql_server; then
                log "Executing SQL initialization scripts..."
                for sql_script in /opt/mssql/scripts/*.sql; do
                    if [ -f "$sql_script" ]; then
                        log "Running SQL script: $sql_script"
                        /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -i "$sql_script" -C
                    fi
                done
            fi
            
            # Bring SQL Server to foreground
            wait $SQL_PID
        )
        exit $?
    fi
fi

log "Starting SQL Server..."

# Start SQL Server with proper environment variables
export ACCEPT_EULA=Y
export MSSQL_SA_PASSWORD="$SA_PASSWORD"
export MSSQL_PID="$MSSQL_PID"

# If we have arguments, use them; otherwise use the found binary
if [ $# -eq 0 ]; then
    exec "$SQLSERVR_PATH"
else
    # Replace the binary path in arguments if needed
    if [ "$1" = "/opt/mssql/bin/sqlservr" ]; then
        shift
        exec "$SQLSERVR_PATH" "$@"
    else
        exec "$@"
    fi
fi