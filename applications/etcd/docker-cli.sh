#!/usr/bin/env bash
#
# Script Name: docker-cli.sh
# Description: Deploys a single-node etcd Docker container for development and testing.
#              Maps necessary ports and volumes for configuration and data storage.
# Author: Liu Kun <liukunup@outlook.com>
# Version: 1.0
# Created: 2025-09-04
# Last Modified: 2025-09-04
# License: MIT
#
# Usage: ./docker-cli.sh
# Environment Variables:
#   DATA_DIR       - Path to etcd data directory (default: ./data)
#   REGISTRY       - Docker registry (default: docker.io)
#   ETCD_VERSION   - etcd image version (default: latest)
#   HOST_IP        - Host IP for client advertisements (default: 127.0.0.1)
#   CLIENT_PORT    - Client API port (default: 2379)
#   PEER_PORT      - Peer communication port (default: 2380)
#
# Example:
#   DATA_DIR=/mnt/etcd/data HOST_IP=192.168.1.100 ./docker-cli.sh

set -euo pipefail

# Set default values if not provided
DATA_DIR="${DATA_DIR:-./data}"
REGISTRY="${REGISTRY:-docker.io}"
ETCD_VERSION="${ETCD_VERSION:-latest}"
HOST_IP="${HOST_IP:-127.0.0.1}"
CLIENT_PORT="${CLIENT_PORT:-2379}"
PEER_PORT="${PEER_PORT:-2380}"
CONTAINER_NAME="${CONTAINER_NAME:-etcd-server}"

echo "=== etcd Docker Container Deployment (Single Node) ==="
echo ""

# Create data directory if it doesn't exist
echo "Creating directory structure..."
mkdir -p "${DATA_DIR}"
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
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "⚠️  etcd container '${CONTAINER_NAME}' already exists. Removing existing container..."
  docker rm -f "${CONTAINER_NAME}" > /dev/null 2>&1
  echo "✓ Removed existing container"
  echo ""
fi

echo "Starting etcd container deployment..."
echo "Configuration:"
echo "  - Host IP: ${HOST_IP}"
echo "  - Container Name: ${CONTAINER_NAME}"
echo "  - etcd Version: ${ETCD_VERSION}"
echo ""
echo "Port mappings:"
echo "  - Client API: ${CLIENT_PORT}:2379/tcp"
echo "  - Peer Communication: ${PEER_PORT}:2380/tcp"
echo ""
echo "Volume mappings:"
echo "  - Data: ${DATA_DIR}:/bitnami/etcd/data"
echo ""

# Deploy the Docker container
echo "🚀 Deploying etcd container..."
docker run -d \
  --name="${CONTAINER_NAME}" \
  --publish "${CLIENT_PORT}:2379" \
  --publish "${PEER_PORT}:2380" \
  --env ALLOW_NONE_AUTHENTICATION=yes \
  --env ETCD_ADVERTISE_CLIENT_URLS="http://${HOST_IP}:${CLIENT_PORT}" \
  --env ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379" \
  --env ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380" \
  --env ETCD_NAME="etcd-single" \
  --env ETCD_DATA_DIR="/bitnami/etcd/data" \
  --volume "${DATA_DIR}:/bitnami/etcd/data" \
  --restart unless-stopped \
  "${REGISTRY}/bitnami/etcd:${ETCD_VERSION}"

echo ""
echo "✅ Deployment completed successfully!"
echo ""

# Wait a moment for etcd to start
echo "Waiting for etcd to initialize..."
sleep 3

echo ""
echo "=== Verification ==="
# Test etcd connectivity
if docker exec "${CONTAINER_NAME}" etcdctl put test_key "Hello etcd"; then
  echo "✓ etcd is responding correctly"
  docker exec "${CONTAINER_NAME}" etcdctl get test_key
else
  echo "⚠️  etcd might be starting up slowly, check logs with: docker logs ${CONTAINER_NAME}"
fi

echo ""
echo "=== Next Steps ==="
echo "1. etcd client API is available at: http://${HOST_IP}:${CLIENT_PORT}"
echo "2. Use etcdctl to interact with the server:"
echo "   docker exec ${CONTAINER_NAME} etcdctl put key value"
echo "   docker exec ${CONTAINER_NAME} etcdctl get key"
echo "   docker exec ${CONTAINER_NAME} etcdctl member list"
echo "3. Or connect from host using etcdctl (if installed):"
echo "   ETCDCTL_API=3 etcdctl --endpoints=http://${HOST_IP}:${CLIENT_PORT} get key"
echo ""

echo "Container status:"
docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "To view logs: docker logs ${CONTAINER_NAME}"
echo "To stop container: docker stop ${CONTAINER_NAME}"
echo "To remove container: docker rm ${CONTAINER_NAME}"
echo "To access shell: docker exec -it ${CONTAINER_NAME} bash"