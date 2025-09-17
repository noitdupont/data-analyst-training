# Use Oracle Database Free (no authentication required)
FROM gvenzl/oracle-free:23-slim
LABEL maintainer="Finbarrs Oketunji <f+dba@finbarrs.eu>"

EXPOSE 1521 5500

WORKDIR /opt/oracle

# Copy optional initialization scripts (uncomment if you have any)
# COPY init-scripts/ /opt/oracle/scripts/setup/

# Healthcheck: uses the ORACLE_PASSWORD provided at container runtime.
# Provide ORACLE_PASSWORD via docker-compose env_file, -e, or a secrets mechanism.
HEALTHCHECK --interval=30s --timeout=10s --retries=5 \
  CMD sh -c 'if [ -z "$ORACLE_PASSWORD" ]; then exit 1; fi; \
    echo "SELECT 1 FROM dual;" | sqlplus -s system/"$ORACLE_PASSWORD"@localhost:1521/FREE >/dev/null 2>&1 || exit 1'

# Build and run commands:
# docker build -t my-oracle-db .
# docker run -d -p 1521:1521 -p 5500:5500 --name oracle-db -e ORACLE_PASSWORD=AGIWHATNOT28 my-oracle-db