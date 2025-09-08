#!/usr/bin/env bash
#
# Script Name: docker-cli.sh
# Description: Standard template for deploying Docker containers with common features.
#              Supports SSL, port mapping, volume mapping, and environment variables.
# Author: [Your Name] <[your.email@example.com]>
# Version: 1.0.0
# Created: $(date +%Y-%m-%d)
# Last Modified: $(date +%Y-%m-%d)
# License: MIT
#
# Usage: ./docker-cli.sh [OPTIONS]
# Environment Variables: (See CONFIGURATION section below)
#
# Options:
#   -h, --help      Show this help message
#   -v, --version   Show version information
#   -d, --debug     Enable debug mode
#   --dry-run       Show what would be done without actually doing it
#
# Example:
#   ./docker-cli.sh
#   DEBUG=true ./docker-cli.sh --dry-run

set -euo pipefail

###############################################################################
#                              CONFIGURATION                                  #
#         Override these variables by setting them in your environment        #
###############################################################################

# MinIO
MINIO_ROOT_USER="${MINIO_ROOT_USER:-"root"}"             # MinIO root user
MINIO_ROOT_PASSWORD="${MINIO_ROOT_PASSWORD:-"changeit"}" # 
MINIO_DOMAIN="${MINIO_DOMAIN:-"minio.example.net"}"      #
MINIO_VOLUMES="${MINIO_VOLUMES:-"/data/minio"}"          #

# Container configuration
CONTAINER_NAME="${CONTAINER_NAME:-"minio"}"              # Name of the Docker container
REGISTRY="${REGISTRY:-"docker.io"}"                      # Docker registry
IMAGE_NAME="${IMAGE_NAME:-"minio/minio"}"                # Docker image name
IMAGE_TAG="${IMAGE_TAG:-"RELEASE.2025-09-07T16-13-09Z"}" # Docker image tag

# Network configuration
PORTS="${PORTS:-"9000:9000 9001:9001 8021:8021 30000-40000:30000-40000"}" # Port mappings
NETWORK="${NETWORK:-}"       # Docker network name
C_HOSTNAME="${C_HOSTNAME:-}" # Container hostname

# Volume configuration
VOLUMES="${VOLUMES:-"./data:${MINIO_VOLUMES} ./config.env:/etc/config.env:ro"}" # Volume mappings
DATA_DIR="${DATA_DIR:-"./data"}"                                                # Default data directory

# SSL configuration
SSL_ENABLED="${SSL_ENABLED:-true}" # Enable SSL certificate generation
CERTS_DIR="${CERTS_DIR:-./certs}"  # SSL certificates directory
SSL_SUBJECT="${SSL_SUBJECT:-/C=CN/ST=Beijing/L=Beijing/O=MyOrg/CN=localhost}"

# Environment variables (comma-separated KEY=VALUE pairs)
ENV_VARS="${ENV_VARS:-"MINIO_CONFIG_ENV_FILE='/etc/config.env'"}"

# Container options
RESTART_POLICY="${RESTART_POLICY:-unless-stopped}" # Docker restart policy
EXTRA_OPTIONS="${EXTRA_OPTIONS:-}"                 # Extra Docker options

###############################################################################
#                             INTERNAL VARIABLES                              #
#                  Generally no need to modify these                          #
###############################################################################

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="1.0.0"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Flags
DEBUG="${DEBUG:-false}"
DRY_RUN="${DRY_RUN:-false}"

###############################################################################
#                               FUNCTIONS                                     #
###############################################################################

log() {
    local color=$1
    local message=$2
    echo -e "${color}[$(date '+%Y-%m-%d %H:%M:%S')] ${message}${NC}"
}

info() {
    log "${BLUE}" "INFO: $1"
}

success() {
    log "${GREEN}" "SUCCESS: $1"
}

warning() {
    log "${YELLOW}" "WARNING: $1"
}

error() {
    log "${RED}" "ERROR: $1"
    exit 1
}

# Debug output (only shown when DEBUG=true)
debug() {
    if [[ "${DEBUG}" == "true" ]]; then
        log "${YELLOW}" "DEBUG: $1"
    fi
}

# Show usage information
usage() {
    cat << EOF
${SCRIPT_NAME} - Docker Container Deployment Script

Usage: ${SCRIPT_NAME} [OPTIONS]

Options:
  -h, --help      Show this help message
  -v, --version   Show version information
  -d, --debug     Enable debug mode
  --dry-run       Show what would be done without actually doing it

Environment Variables:
  MINIO_ROOT_USER     MinIO root username
  MINIO_ROOT_PASSWORD MinIO root password
  MINIO_DOMAIN        MinIO domain
  MINIO_VOLUMES       MinIO mount volume
  CONTAINER_NAME      Name of the Docker container
  IMAGE_NAME          Docker image name
  IMAGE_TAG           Docker image tag
  PORTS               Port mappings (space-separated)
  VOLUMES             Volume mappings (space-separated)
  ENV_VARS            Environment variables (comma-separated KEY=VALUE pairs)
  SSL_ENABLED         Enable SSL (true/false)

Example:
  CONTAINER_NAME=myapp IMAGE_NAME=nginx IMAGE_TAG=alpine PORTS="8080:80" ${SCRIPT_NAME}
  ${SCRIPT_NAME} --dry-run
EOF
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--version)
                echo "${SCRIPT_NAME} v${VERSION}"
                exit 0
                ;;
            -d|--debug)
                DEBUG="true"
                shift
                ;;
            --dry-run)
                DRY_RUN="true"
                shift
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
}

# Validate required dependencies
validate_dependencies() {
    local deps=("docker")

    if [[ "${SSL_ENABLED}" == "true" ]]; then
        deps+=("openssl")
    fi

    for dep in "${deps[@]}"; do
        if ! command -v "${dep}" >/dev/null 2>&1; then
            error "${dep} is required but not installed"
        fi
    done
    info "All dependencies are available"
}

# Validate configuration
validate_configuration() {
    if [[ -z "${IMAGE_NAME}" ]]; then
        error "IMAGE_NAME is required"
    fi

    if [[ "${SSL_ENABLED}" == "true" && -z "${SSL_SUBJECT}" ]]; then
        error "SSL_SUBJECT is required when SSL_ENABLED=true"
    fi

    info "Configuration validation passed"
}

# Create necessary directories
create_directories() {
    local dirs=("${DATA_DIR}")

    if [[ "${SSL_ENABLED}" == "true" ]]; then
        dirs+=("${CERTS_DIR}")
    fi

    for dir in "${dirs[@]}"; do
        if [[ ! -d "${dir}" ]]; then
            info "Creating directory: ${dir}"
            if [[ "${DRY_RUN}" != "true" ]]; then
                mkdir -p "${dir}"
            fi
        fi
    done
}

# Generate SSL certificates
generate_ssl_certificates() {
    if [[ "${SSL_ENABLED}" != "true" ]]; then
        return 0
    fi

    info "Generating SSL certificates in ${CERTS_DIR}"
    
    if [[ "${DRY_RUN}" == "true" ]]; then
        info "Would generate SSL certificates (dry run)"
        return 0
    fi

    # Generate CA
    openssl genrsa -out "${CERTS_DIR}/ca.key" 4096 2>/dev/null || {
        error "Failed to generate CA private key"
    }

    openssl req -new -x509 -nodes -sha512 -days 3650 \
        -key "${CERTS_DIR}/ca.key" \
        -out "${CERTS_DIR}/ca.pem" \
        -subj "${SSL_SUBJECT}" 2>/dev/null || {
        error "Failed to generate CA certificate"
    }

    # Generate server certificate
    openssl genrsa -out "${CERTS_DIR}/server.key" 4096 2>/dev/null || {
        error "Failed to generate server private key"
    }

    openssl req -new -sha512 -days 3650 \
        -key "${CERTS_DIR}/server.key" \
        -out "${CERTS_DIR}/server.csr" \
        -subj "${SSL_SUBJECT}" 2>/dev/null || {
        error "Failed to generate certificate signing request"
    }

    openssl x509 -req -in "${CERTS_DIR}/server.csr" -days 3650 \
        -CA "${CERTS_DIR}/ca.pem" -CAkey "${CERTS_DIR}/ca.key" \
        -CAcreateserial -out "${CERTS_DIR}/server.pem" 2>/dev/null || {
        error "Failed to generate server certificate"
    }

    # Set permissions
    chmod 600 "${CERTS_DIR}"/*.key
    chmod 644 "${CERTS_DIR}"/*.pem

    # Cleanup
    rm -f "${CERTS_DIR}/server.csr" "${CERTS_DIR}/ca.srl"

    success "SSL certificates generated successfully"
}

# Remove existing container if it exists
remove_existing_container() {
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        warning "Container ${CONTAINER_NAME} already exists. Removing..."
        if [[ "${DRY_RUN}" != "true" ]]; then
            docker rm -f "${CONTAINER_NAME}" > /dev/null 2>&1 || {
                error "Failed to remove existing container ${CONTAINER_NAME}"
            }
        fi
        info "Removed existing container ${CONTAINER_NAME}"
    fi
}

# Build MinIO config.env file
build_config_env() {

    cat << EOF > config.env
MINIO_OPTS=' --address=":9000" --console-address=":9001" --ftp="address=:8021" --ftp="passive-port-range=30000-40000" --certs-dir="/opt/minio/certs" '
MINIO_ROOT_USER='${MINIO_ROOT_USER}'
MINIO_ROOT_PASSWORD='${MINIO_ROOT_PASSWORD}'
MINIO_DOMAIN='${MINIO_DOMAIN}'
MINIO_VOLUMES='${MINIO_VOLUMES}'
EOF

    success "MinIO config.env generated successfully"
}

# Build Docker run command
build_docker_command() {
    local cmd="docker run -d --name=${CONTAINER_NAME}"

    # Add port mappings
    if [[ -n "${PORTS}" ]]; then
        for port in ${PORTS}; do
            cmd+=" -p ${port}"
        done
    fi

    # Add network
    if [[ -n "${NETWORK}" ]]; then
        cmd+=" --network=${NETWORK}"
    fi

    # Add hostname
    if [[ -n "${C_HOSTNAME}" ]]; then
        cmd+=" --hostname=${C_HOSTNAME}"
    fi

    # Add volume mappings
    if [[ -n "${VOLUMES}" ]]; then
        for volume in ${VOLUMES}; do
            cmd+=" -v ${volume}"
        done
    fi

    # Add environment variables
    if [[ -n "${ENV_VARS}" ]]; then
        IFS=',' read -ra env_array <<< "${ENV_VARS}"
        for env_var in "${env_array[@]}"; do
            cmd+=" -e ${env_var}"
        done
    fi

    # Add SSL volumes if enabled
    if [[ "${SSL_ENABLED}" == "true" ]]; then
        cmd+=" -v ${CERTS_DIR}/ca.pem:/opt/minio/certs/CAs/ca.crt:ro"
        cmd+=" -v ${CERTS_DIR}/server.pem:/opt/minio/certs/public.crt:ro"
        cmd+=" -v ${CERTS_DIR}/server.key:/opt/minio/certs/private.key:ro"
    fi

    # Add restart policy
    cmd+=" --restart=${RESTART_POLICY}"

    # Add extra options
    if [[ -n "${EXTRA_OPTIONS}" ]]; then
        cmd+=" ${EXTRA_OPTIONS}"
    fi

    # Add image
    cmd+=" ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

    echo "${cmd}"
}

# Verify container deployment
verify_deployment() {
    info "Verifying deployment..."
    
    if [[ "${DRY_RUN}" == "true" ]]; then
        info "Would verify deployment (dry run)"
        return 0
    fi

    if docker ps --filter "name=${CONTAINER_NAME}" --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        success "Container ${CONTAINER_NAME} is running"
    else
        error "Container ${CONTAINER_NAME} is not running"
    fi
}

# Show deployment summary
show_summary() {
    cat << EOF

=== DEPLOYMENT SUMMARY ===
Container:     ${CONTAINER_NAME}
Image:         ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
Status:        $(if [[ "${DRY_RUN}" == "true" ]]; then echo "DRY RUN"; else echo "DEPLOYED"; fi)

Network:
  Ports:       ${EXTRA_PORTS:-None}
  Network:     ${NETWORK:-default}
  Hostname:    ${C_HOSTNAME:-auto}

Volumes:
  Data:        ${DATA_DIR}
  Config:      ${CONFIG_DIR}
  SSL:         ${SSL_ENABLED} $( [[ "${SSL_ENABLED}" == "true" ]] && echo "(${CERTS_DIR})" )

SSL:           ${SSL_ENABLED}
$(if [[ "${SSL_ENABLED}" == "true" ]]; then
echo "  CA Certificate: ${CERTS_DIR}/ca.pem"
echo "  Server Certificate: ${CERTS_DIR}/server.pem"
echo "  Server Key: ${CERTS_DIR}/server.key"
fi)

Next Steps:
  1. Check container status: docker ps -f name=${CONTAINER_NAME}
  2. View container logs: docker logs ${CONTAINER_NAME}
  3. Stop container: docker stop ${CONTAINER_NAME}
  4. Remove container: docker rm ${CONTAINER_NAME}

EOF
}

###############################################################################
#                               MAIN EXECUTION                                #
###############################################################################

main() {
    parse_arguments "$@"
    
    info "Starting Docker container deployment"
    debug "Debug mode enabled"
    [[ "${DRY_RUN}" == "true" ]] && info "Dry run mode enabled"

    validate_dependencies
    validate_configuration
    create_directories
    
    if [[ "${SSL_ENABLED}" == "true" ]]; then
        generate_ssl_certificates
    fi

    remove_existing_container
    build_config_env

    local docker_cmd
    docker_cmd=$(build_docker_command)
    
    info "Docker command:"
    echo "  ${docker_cmd}"
    echo

    if [[ "${DRY_RUN}" != "true" ]]; then
        info "Starting container..."
        eval "${docker_cmd}" || {
            error "Failed to start container"
        }
        
        # Wait for container to start
        echo "Waiting for ${CONTAINER_NAME} to start..."
        sleep 10

        verify_deployment
    fi

    show_summary
    success "Deployment process completed"
}

# Run main function with all arguments
main "$@"