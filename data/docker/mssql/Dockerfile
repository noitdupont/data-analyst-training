# Use Rocky Linux 8 (RHEL 8 compatible, officially supported by Microsoft)
# Force x64 platform since SQL Server doesn't support ARM64
FROM --platform=linux/amd64 rockylinux:8
LABEL maintainer="Finbarrs Oketunji <f+dba@finbarrs.eu>"

# Environment variables (SA_PASSWORD will be provided at runtime)
ENV ACCEPT_EULA=Y \
    MSSQL_PID=Developer \
    MSSQL_AGENT_ENABLED=false

# Expose SQL Server port
EXPOSE 1433

# Install prerequisites and Microsoft signing key
RUN dnf update -y \
    && dnf install -y \
        curl \
        wget \
        python3 \
        openssl \
        compat-openssl10 \
        glibc \
        rpm \
        gnupg2 \
    && dnf clean all

# Configure DNF for better network handling
RUN echo "timeout=30" >> /etc/dnf/dnf.conf \
    && echo "retries=5" >> /etc/dnf/dnf.conf \
    && echo "minrate=1000" >> /etc/dnf/dnf.conf

# Create Microsoft repository files directly (without GPG validation)
RUN cat > /etc/yum.repos.d/mssql-server.repo << 'EOF'
[packages-microsoft-com-mssql-server-2022]
name=packages-microsoft-com-mssql-server-2022
baseurl=https://packages.microsoft.com/rhel/8/mssql-server-2022/
enabled=1
gpgcheck=0
EOF

RUN cat > /etc/yum.repos.d/msprod.repo << 'EOF'
[packages-microsoft-com-prod]
name=packages-microsoft-com-prod  
baseurl=https://packages.microsoft.com/rhel/8/prod/
enabled=1
gpgcheck=0
EOF

# Create mssql user and directories
RUN useradd -r -s /bin/false -d /var/opt/mssql mssql \
    && mkdir -p /var/opt/mssql/data \
    && mkdir -p /var/opt/mssql/log \
    && mkdir -p /var/opt/mssql/secrets \
    && chown -R mssql:mssql /var/opt/mssql

# Clean DNF cache and update repository metadata
RUN dnf clean all && dnf makecache --refresh

# Install SQL Server with explicit error handling
RUN set -e && \
    echo "Installing SQL Server..." && \
    ACCEPT_EULA=Y dnf install -y mssql-server && \
    echo "SQL Server installation completed" && \
    ls -la /opt/mssql/bin/ || echo "No /opt/mssql/bin directory" && \
    find /opt -name "sqlservr" -type f 2>/dev/null || echo "sqlservr not found in /opt" && \
    dnf clean all

# Install SQL Server command-line tools
RUN set -e && \
    echo "Installing SQL Server tools..." && \
    ACCEPT_EULA=Y dnf install -y mssql-tools18 unixODBC-devel && \
    echo "SQL Server tools installation completed" && \
    ls -la /opt/mssql-tools18/bin/ || echo "No /opt/mssql-tools18/bin directory" && \
    echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> /etc/bashrc && \
    dnf clean all

# Verify installations
RUN echo "=== Installation Verification ===" && \
    echo "SQL Server binary:" && \
    find /opt /usr -name "sqlservr" -type f 2>/dev/null || echo "sqlservr binary not found" && \
    echo "mssql-conf tool:" && \
    find /opt /usr -name "mssql-conf" -type f 2>/dev/null || echo "mssql-conf not found" && \
    echo "Available packages:" && \
    rpm -qa | grep mssql || echo "No mssql packages found" && \
    echo "Directory contents:" && \
    ls -la /opt/ 2>/dev/null || echo "/opt directory not accessible"

# Setup configuration
WORKDIR /opt/mssql

# Copy entry script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=5 \
    CMD /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -Q "SELECT 1" -C -b || exit 1

# Switch to mssql user
USER mssql

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Build and run:
# Build with explicit x64 platform
# docker build --platform linux/amd64 -t mssql-rocky . --no-cache

# Run with explicit x64 platform  
# docker run --platform linux/amd64 -d -p 1433:1433 --name mssql-server \
#   -e SA_PASSWORD='MyComplexPass123!@#' \
#   mssql-rocky