#!/usr/bin/env bash
#
# Script Name: docker-cli.sh
# Description: Deploys a MySQL Docker container with self-signed SSL certificates.
#              Maps necessary ports and volumes for configuration and data storage.
# Author: Liu Kun <liukunup@outlook.com>
# Version: 1.0
# Created: 2025-09-08
# Last Modified: 2025-09-08
# License: MIT
#
# Usage: ./docker-cli.sh
# Environment Variables:
#   MYSQL_ROOT_PASSWORD - MySQL root password (required)
#   MYSQL_DATABASE      - MySQL database name (default: testing)
#   MYSQL_USER          - MySQL user name (default: testuser)
#   MYSQL_PASSWORD      - MySQL user password (default: changeit)
#   DATA_DIR            - Path to MySQL data directory (default: ./data)
#   CERTS_DIR           - Path to SSL certificates directory (default: ./certs)
#   REGISTRY            - Docker registry (default: docker.io)
#
# Example:
#   MYSQL_ROOT_PASSWORD=secret MYSQL_DATABASE=appdb DATA_DIR=/mnt/mysql/data ./docker-cli.sh

set -euo pipefail

# Set default values
MYSQL_DATABASE="${MYSQL_DATABASE:-testing}"
MYSQL_USER="${MYSQL_USER:-testuser}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-changeit}"
DATA_DIR="${DATA_DIR:-./data}"
CERTS_DIR="${CERTS_DIR:-./certs}"
REGISTRY="${REGISTRY:-docker.io}"

echo "=== MySQL Docker Container Deployment with SSL ==="
echo ""

# Validate required environment variables
if [[ -z "${MYSQL_ROOT_PASSWORD}" ]]; then
  echo "❌ Error: MYSQL_ROOT_PASSWORD is required"
  echo "  Usage: MYSQL_ROOT_PASSWORD=your_password ./docker-cli.sh"
  exit 1
fi

# Create directories if they don't exist
echo "Creating directory structure..."
mkdir -p "${DATA_DIR}" "${CERTS_DIR}"
echo "✓ Data directory: ${DATA_DIR}"
echo "✓ SSL certificates directory: ${CERTS_DIR}"
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
  echo "❌ Error: Docker is not installed or not in PATH"
  exit 1
fi
echo "✓ Docker is available"
echo ""

# Generate self-signed SSL certificates if they don't exist
if [[ ! -f "${CERTS_DIR}/ca.pem" ]] || [[ ! -f "${CERTS_DIR}/server.pem" ]] || [[ ! -f "${CERTS_DIR}/server.key" ]]; then
  echo "Generating SSL certificates..."

  # Check if OpenSSL is available for certificate generation
  if ! command -v openssl &> /dev/null; then
    echo "❌ Error: OpenSSL is required but not installed"
    exit 1
  fi

  # Generate CA private key and certificate
  openssl genrsa 4096 > "${CERTS_DIR}/ca.key" 2>/dev/null
  openssl req -new -x509 -nodes -sha512 -days 3650 \
    -key "${CERTS_DIR}/ca.key" \
    -out "${CERTS_DIR}/ca.pem" \
    -subj "/C=CN/ST=Beijing/L=Beijing/O=MyOrg/OU=IT/CN=MySQL CA" 2>/dev/null

  # Generate server private key and certificate
  openssl req -newkey rsa:4096 -nodes -sha512 -days 3650 \
    -keyout "${CERTS_DIR}/server.key" \
    -out "${CERTS_DIR}/server.csr" \
    -subj "/C=CN/ST=Beijing/L=Beijing/O=MyOrg/OU=IT/CN=mysql-server" 2>/dev/null

  openssl x509 -req -in "${CERTS_DIR}/server.csr" -days 3650 \
    -CA "${CERTS_DIR}/ca.pem" -CAkey "${CERTS_DIR}/ca.key" \
    -set_serial 01 -out "${CERTS_DIR}/server.pem" 2>/dev/null

  # Clean up temporary files
  rm -f "${CERTS_DIR}/server.csr"

  echo "✓ SSL certificates generated successfully"
else
  echo "✓ SSL certificates already exist, skipping generation"
fi
echo ""

# Set proper permissions for SSL files
chmod 600 "${CERTS_DIR}"/*.key
chmod 644 "${CERTS_DIR}"/*.pem

# Check if container already exists
if docker ps -a --format '{{.Names}}' | grep -q '^mysql-server$'; then
  echo "⚠️  MySQL container already exists. Removing existing container..."
  docker rm -f mysql-server > /dev/null 2>&1
  echo "✓ Removed existing container"
  echo ""
fi

echo "Starting MySQL container deployment..."
echo "Port mapping: 3306/tcp"
echo "SSL configuration: Enabled"
echo ""

# Deploy the Docker container
echo "🚀 Deploying MySQL container with SSL..."
docker run -d \
  --name=mysql-server \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}" \
  -e MYSQL_DATABASE="${MYSQL_DATABASE}" \
  -e MYSQL_USER="${MYSQL_USER}" \
  -e MYSQL_PASSWORD="${MYSQL_PASSWORD}" \
  -v "${DATA_DIR}:/var/lib/mysql" \
  -v "${CERTS_DIR}:/etc/mysql/ssl" \
  -v "${CERTS_DIR}/ca.pem:/etc/mysql/ssl/ca.pem:ro" \
  -v "${CERTS_DIR}/server.pem:/etc/mysql/ssl/server.pem:ro" \
  -v "${CERTS_DIR}/server.key:/etc/mysql/ssl/server.key:ro" \
  --restart unless-stopped \
  "${REGISTRY}/mysql:8" \
  --ssl-ca=/etc/mysql/ssl/ca.pem \
  --ssl-cert=/etc/mysql/ssl/server.pem \
  --ssl-key=/etc/mysql/ssl/server.key \
  --require_secure_transport=ON

echo ""
echo "✅ Deployment completed successfully!"
echo ""

# Wait for MySQL to start
echo "Waiting for MySQL to start..."
sleep 10

# Verify SSL connection
echo "=== Verifying SSL Configuration ==="
if docker exec mysql-server mysql --ssl-mode=REQUIRED -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW STATUS LIKE 'Ssl_cipher';" 2>/dev/null; then
  echo ""
  echo "✓ SSL connection established successfully"
else
  echo ""
  echo "⚠️  SSL connection test failed. Checking container logs..."
  docker logs mysql-server --tail 10
  exit 1
fi

echo ""
echo "=== Connection Information ==="
echo "Host: localhost:3306"
echo "Root user: root"
echo "Database: ${MYSQL_DATABASE}"
echo "User: ${MYSQL_USER}"
echo "SSL: Enabled (self-signed certificate)"
echo ""

echo "=== Next Steps ==="
echo "1. Connect to MySQL with SSL:"
echo "   mysql --ssl -h localhost -u root -p"
echo "2. To use the generated CA certificate: ${CERTS_DIR}/ca.pem"
echo "3. For application connections, use SSL mode and provide CA certificate"
echo ""

echo "Container status:"
docker ps --filter "name=mysql-server" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "To view logs: docker logs mysql-server"
echo "To stop container: docker stop mysql-server"
echo "To remove container: docker rm mysql-server"