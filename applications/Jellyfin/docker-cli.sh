#!/usr/bin/env bash
#
# Script Name: docker-cli.sh
# Description: Deploys a Jellyfin media server Docker container with proper volume mounts.
#              Configures media directories and runs with host networking for optimal performance.
# Author: Liu Kun <liukunup@outlook.com>
# Version: 1.0
# Created: 2025-08-24
# Last Modified: 2025-08-24
# License: MIT
#
# Usage: ./docker-cli.sh [MEDIA_DIRECTORY1] [MEDIA_DIRECTORY2]
# Environment Variables:
#   JELLYFIN_CONFIG_DIR - Path to Jellyfin configuration directory (default: ./jellyfin-config)
#   JELLYFIN_CACHE_DIR  - Path to Jellyfin cache directory (default: ./jellyfin-cache)
#   REGISTRY            - Docker registry (default: docker.io)
#
# Example:
#   ./docker-cli.sh /mnt/media/movies /mnt/media/tvshows
#   JELLYFIN_CONFIG_DIR=/opt/jellyfin/config ./docker-cli.sh /media/content

set -euo pipefail

# Set default directories if not provided
JELLYFIN_CONFIG_DIR="${JELLYFIN_CONFIG_DIR:-./jellyfin-config}"
JELLYFIN_CACHE_DIR="${JELLYFIN_CACHE_DIR:-./jellyfin-cache}"
REGISTRY="${REGISTRY:-docker.io}"
IMAGE="liukunup/jellyfin:10.10.3"

# Get media directories from arguments or use defaults
MEDIA_DIR1="${1:-/path/to/media1}"
MEDIA_DIR2="${2:-/path/to/media2}"

echo "=== Jellyfin Media Server Deployment ==="
echo ""

# Create directories if they don't exist
echo "Creating directory structure..."
mkdir -p "${JELLYFIN_CONFIG_DIR}" "${JELLYFIN_CACHE_DIR}"
echo "✓ Configuration directory: ${JELLYFIN_CONFIG_DIR}"
echo "✓ Cache directory: ${JELLYFIN_CACHE_DIR}"
echo "✓ Media directory 1: ${MEDIA_DIR1}"
echo "✓ Media directory 2: ${MEDIA_DIR2}"
echo ""

# Check if media directories exist
if [[ ! -d "${MEDIA_DIR1}" ]]; then
    echo "⚠️  Warning: Media directory 1 does not exist: ${MEDIA_DIR1}"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        exit 1
    fi
fi

if [[ ! -d "${MEDIA_DIR2}" ]]; then
    echo "⚠️  Warning: Media directory 2 does not exist: ${MEDIA_DIR2}"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        exit 1
    fi
fi

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed or not in PATH"
    exit 1
fi
echo "✓ Docker is available"
echo ""

# Check if container already exists
if docker ps -a --format '{{.Names}}' | grep -q '^jellyfin$'; then
    echo "⚠️  Jellyfin container already exists. Removing existing container..."
    docker rm -f jellyfin > /dev/null 2>&1
    echo "✓ Removed existing container"
    echo ""
fi

echo "Starting Jellyfin container deployment..."
echo "Configuration:"
echo "  - Network mode: host (for best performance)"
echo "  - User: 1000:1000 (run as non-root)"
echo "  - Restart policy: always"
echo "  - Media directory 1: ${MEDIA_DIR1} (read-write)"
echo "  - Media directory 2: ${MEDIA_DIR2} (read-only)"
echo ""

# Deploy the Docker container
echo "🚀 Deploying Jellyfin container..."
docker run -d \
  --volume "${JELLYFIN_CONFIG_DIR}:/config" \
  --volume "${JELLYFIN_CACHE_DIR}:/cache" \
  --mount "type=bind,source=${MEDIA_DIR1},target=/media1" \
  --mount "type=bind,source=${MEDIA_DIR2},target=/media2,readonly" \
  --name=jellyfin \
  --restart=always \
  --user=1000:1000 \
  --net=host \
  "${IMAGE}"

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "=== Next Steps ==="
echo "1. Access Jellyfin web interface: http://localhost:8096"
echo "2. Complete the initial setup wizard"
echo "3. Configure your media libraries in Settings > Libraries"
echo "4. Add media folders: /media1 and /media2"
echo ""
echo "Container status:"
docker ps --filter "name=jellyfin" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "To view logs: docker logs jellyfin"
echo "To stop container: docker stop jellyfin"
echo "To remove container: docker rm jellyfin"
echo "To update container: pull new image and re-run this script"
echo ""
echo "Note: Jellyfin is running with host networking on port 8096"
