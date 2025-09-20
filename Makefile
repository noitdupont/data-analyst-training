# Database Management Makefile
# Usage: make [target]

# Docker Database Targets
.PHONY: db2-build db2-run db2-clean mssql-build mssql-run mssql-clean oracle-build oracle-run oracle-clean
.PHONY: mysql-setup postgres-setup help

# IBM DB2 Commands
db2-build:
	@echo "Building IBM DB2 Docker image..."
	docker build --platform linux/amd64 -t my-db2-db ./data/docker/ibm_db2

db2-run:
	@echo "Creating DB2 volume and running container..."
	docker volume create db2data
	docker run -d \
	  --privileged \
	  --platform linux/amd64 \
	  -p 50000:50000 -p 55000:55000 \
	  --name db2-database \
	  -v db2data:/database \
	  -e LICENSE=accept \
	  -e DB2INSTANCE=db2inst1 \
	  -e DB2INST1_PASSWORD=AGIWHATNOT28 \
	  -e DBNAME=TESTDB \
	  -e BLU=false \
	  -e ENABLE_ORACLE_COMPATIBILITY=false \
	  -e UPDATEAVAIL=NO \
	  -e TO_CREATE_SAMPLEDB=false \
	  -e HADR_ENABLED=false \
	  -e ETCD_ENDPOINT= \
	  -e ETCD_USERNAME= \
	  -e ETCD_PASSWORD= \
	  my-db2-db

db2-clean:
	@echo "Stopping and removing DB2 container and volume..."
	-docker stop db2-database
	-docker rm db2-database
	-docker volume rm db2data

# MSSQL Commands
mssql-build:
	@echo "Building MSSQL Docker image..."
	docker build --platform linux/amd64 -t mssql-rocky ./data/docker/mssql --no-cache

mssql-run:
	@echo "Running MSSQL container..."
	docker run --platform linux/amd64 -d -p 1433:1433 --name mssql-server \
	  -e SA_PASSWORD='MyComplexPass123!@#' \
	  mssql-rocky

mssql-clean:
	@echo "Stopping and removing MSSQL container..."
	-docker stop mssql-server
	-docker rm mssql-server

# Oracle Commands
oracle-build:
	@echo "Building Oracle Docker image..."
	docker build -t my-oracle-db ./data/docker/oracle

oracle-run:
	@echo "Running Oracle container..."
	docker run -d -p 1521:1521 --name oracle-db my-oracle-db

oracle-clean:
	@echo "Stopping and removing Oracle container..."
	-docker stop oracle-db
	-docker rm oracle-db

# macOS Database Setup Commands
mysql-setup:
	@echo "Setting up MySQL on macOS..."
	@if [ "$$(uname)" != "Darwin" ]; then \
		echo "This command is only supported on macOS"; \
		exit 1; \
	fi
	brew install mysql
	brew services start mysql
	@echo "MySQL installed and started. Run 'mysql -u root' to connect"

postgres-setup:
	@echo "Setting up PostgreSQL on macOS..."
	@if [ "$$(uname)" != "Darwin" ]; then \
		echo "This command is only supported on macOS"; \
		exit 1; \
	fi
	brew install postgresql@15
	brew services start postgresql@15
	initdb /opt/homebrew/var/postgres
	@echo "PostgreSQL installed and started. Run 'psql postgres' to connect"

# Utility Commands
clean-all:
	@echo "Cleaning all database containers..."
	make db2-clean
	make mssql-clean
	make oracle-clean

help:
	@echo "Database Management Makefile"
	@echo ""
	@echo "Docker Database Targets:"
	@echo "  db2-build      - Build IBM DB2 Docker image"
	@echo "  db2-run        - Run IBM DB2 container"
	@echo "  db2-clean      - Stop and remove DB2 container"
	@echo "  mssql-build    - Build MSSQL Docker image"
	@echo "  mssql-run      - Run MSSQL container"
	@echo "  mssql-clean    - Stop and remove MSSQL container"
	@echo "  oracle-build   - Build Oracle Docker image"
	@echo "  oracle-run     - Run Oracle container"
	@echo "  oracle-clean   - Stop and remove Oracle container"
	@echo "  clean-all      - Clean all database containers"
	@echo ""
	@echo "macOS Setup Targets:"
	@echo "  mysql-setup    - Install and setup MySQL on macOS"
	@echo "  postgres-setup - Install and setup PostgreSQL on macOS"
	@echo ""
	@echo "Usage: make [target]"