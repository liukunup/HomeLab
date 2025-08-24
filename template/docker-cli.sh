#!/usr/bin/env bash
#
# Script Name: docker-cli.sh
# Description: Deploys a Syncthing Docker container for file synchronization.
#              Maps necessary ports and volumes for configuration and data storage.
# Author: Liu Kun <liukunup@outlook.com>
# Version: 1.0
# Created: 2025-08-24
# Last Modified: 2025-08-24
# License: MIT
#
# Usage: ./docker-cli.sh
# Environment Variables:
#   CONFIG_DIR - Path to Syncthing configuration directory (default: ./config)
#   DATA_DIR   - Path to data synchronization directory (default: ./data)
#   REGISTRY   - Docker registry (default: docker.io)
#
# Example:
#   CONFIG_DIR=/mnt/syncthing/config DATA_DIR=/mnt/syncthing/data ./docker-cli.sh

set -euo pipefail

# Set default directories if not provided
CONFIG_DIR="${CONFIG_DIR:-./config}"
DATA_DIR="${DATA_DIR:-./data}"
REGISTRY="${REGISTRY:-docker.io}"

echo "=== Syncthing Docker Container Deployment ==="
echo ""

# Create directories if they don't exist
echo "Creating directory structure..."
mkdir -p "${CONFIG_DIR}" "${DATA_DIR}"
echo "✓ Configuration directory: ${CONFIG_DIR}"
echo "✓ Data directory: ${DATA_DIR}"
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
  echo "❌ Error: Docker is not installed or not in PATH"
  exit 1
fi
echo "✓ Docker is available"
echo ""

# Check if container already exists
if docker ps -a --format '{{.Names}}' | grep -q '^syncthing$'; then
  echo "⚠️  Syncthing container already exists. Removing existing container..."
  docker rm -f syncthing > /dev/null 2>&1
  echo "✓ Removed existing container"
  echo ""
fi

echo "Starting Syncthing container deployment..."
echo "Port mappings:"
echo "  - Web GUI: 8384/tcp"
echo "  - Sync protocol: 22000/tcp, 22000/udp" 
echo "  - Discovery: 21027/udp"
echo ""

# Deploy the Docker container
echo "🚀 Deploying Syncthing container..."
docker run -d \
  --name=syncthing \
  -p 8384:8384 \
  -p 22000:22000/tcp \
  -p 22000:22000/udp \
  -p 21027:21027/udp \
  -v "${CONFIG_DIR}:/var/syncthing" \
  -v "${DATA_DIR}:/var/syncthing/Sync" \
  --restart unless-stopped \
  "${REGISTRY}/syncthing/syncthing:latest"

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "=== Next Steps ==="
echo "1. Access Syncthing web interface: http://localhost:8384"
echo "2. Configure your synchronization folders in the web UI"
echo "3. Add remote devices to start syncing files"
echo ""
echo "Container status:"
docker ps --filter "name=syncthing" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "To view logs: docker logs syncthing"
echo "To stop container: docker stop syncthing"
echo "To remove container: docker rm syncthing"
