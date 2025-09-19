# Regulated sectors (mostly finance) and government agencies still use IBM Db2 ;)
# Use IBM Db2 Community Edition (force AMD64 platform)
FROM --platform=linux/amd64 ibmcom/db2:latest

LABEL maintainer="Finbarrs Oketunji <f+dba@finbarrs.eu>"

EXPOSE 50000 55000
WORKDIR /database

# Environment variables for Db2 setup (non-sensitive)
ENV DB2INSTANCE=db2inst1
ENV DBNAME=TESTDB
ENV BLU=false

# Note: DB2INST1_PASSWORD should be set at runtime via docker run -e
# This removes the password from the image for security

# Healthcheck: verifies Db2 instance is running and database is accessible
HEALTHCHECK --interval=30s --timeout=10s --retries=5 \
CMD su - ${DB2INSTANCE} -c "db2 connect to ${DBNAME} >/dev/null 2>&1 && echo 'SELECT 1 FROM SYSIBM.SYSDUMMY1;' | db2 -t >/dev/null 2>&1" || exit 1

# Build and run commands:
# docker build --platform linux/amd64 -t my-db2-db .
# 
# Create a named volume first
# docker volume create db2data

# Run with the volume and additional settings
# docker run -d \
#   --privileged \
#   --platform linux/amd64 \
#   -p 50000:50000 -p 55000:55000 \
#   --name db2-database \
#   -v db2data:/database \
#   -e LICENSE=accept \
#   -e DB2INSTANCE=db2inst1 \
#   -e DB2INST1_PASSWORD=AGIWHATNOT28 \
#   -e DBNAME=TESTDB \
#   -e BLU=false \
#   -e ENABLE_ORACLE_COMPATIBILITY=false \
#   -e UPDATEAVAIL=NO \
#   -e TO_CREATE_SAMPLEDB=false \
#   -e HADR_ENABLED=false \
#   -e ETCD_ENDPOINT= \
#   -e ETCD_USERNAME= \
#   -e ETCD_PASSWORD= \
#   my-db2-db