#!/usr/bin/env bash
#
# Script Name: docker-cli.sh
# Description: Standard template for deploying Docker containers with common features.
#              Supports SSL, volume mapping, environment variables, and health checks.
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

# Container configuration
CONTAINER_NAME="${CONTAINER_NAME:-my-container}"  # Name of the Docker container
IMAGE_NAME="${IMAGE_NAME:-my-image}"              # Docker image name
IMAGE_TAG="${IMAGE_TAG:-latest}"                  # Docker image tag
REGISTRY="${REGISTRY:-docker.io}"                 # Docker registry

# Network configuration
PORTS="${PORTS:-}"                                # Port mappings (e.g., "8080:80 8443:443")
NETWORK="${NETWORK:-}"                            # Docker network name
HOSTNAME="${HOSTNAME:-}"                          # Container hostname

# Volume configuration
VOLUMES="${VOLUMES:-}"                            # Volume mappings (e.g., "./data:/app/data")
DATA_DIR="${DATA_DIR:-./data}"                    # Default data directory
CONFIG_DIR="${CONFIG_DIR:-./config}"              # Default config directory

# SSL configuration
SSL_ENABLED="${SSL_ENABLED:-false}"               # Enable SSL certificate generation
CERTS_DIR="${CERTS_DIR:-./certs}"                 # SSL certificates directory
SSL_SUBJECT="${SSL_SUBJECT:-/C=CN/ST=Beijing/L=Beijing/O=MyOrg/CN=localhost}"

# Environment variables (comma-separated KEY=VALUE pairs)
ENV_VARS="${ENV_VARS:-}"

# Container options
RESTART_POLICY="${RESTART_POLICY:-unless-stopped}" # Docker restart policy
EXTRA_OPTIONS="${EXTRA_OPTIONS:-}"                 # Extra Docker options

# Health check configuration
HEALTHCHECK_ENABLED="${HEALTHCHECK_ENABLED:-true}" # Enable health check
HEALTHCHECK_CMD="${HEALTHCHECK_CMD:-}"             # Custom health check command
HEALTHCHECK_INTERVAL="${HEALTHCHECK_INTERVAL:-30}" # Health check interval in seconds
HEALTHCHECK_TIMEOUT="${HEALTHCHECK_TIMEOUT:-10}"   # Health check timeout in seconds
HEALTHCHECK_RETRIES="${HEALTHCHECK_RETRIES:-3}"    # Health check retries

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

# Print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}[$(date '+%Y-%m-%d %H:%M:%S')] ${message}${NC}"
}

# Print info message
info() {
    print_status "${BLUE}" "INFO: $1"
}

# Print success message
success() {
    print_status "${GREEN}" "SUCCESS: $1"
}

# Print warning message
warning() {
    print_status "${YELLOW}" "WARNING: $1"
}

# Print error message and exit
error() {
    print_status "${RED}" "ERROR: $1"
    exit 1
}

# Debug output (only shown when DEBUG=true)
debug() {
    if [[ "${DEBUG}" == "true" ]]; then
        print_status "${YELLOW}" "DEBUG: $1"
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
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
  CONTAINER_NAME    Name of the Docker container
  IMAGE_NAME        Docker image name
  IMAGE_TAG         Docker image tag
  PORTS             Port mappings (space-separated)
  VOLUMES           Volume mappings (space-separated)
  SSL_ENABLED       Enable SSL (true/false)
  ENV_VARS          Environment variables (comma-separated KEY=VALUE pairs)

Example:
  CONTAINER_NAME=myapp IMAGE_NAME=nginx IMAGE_TAG=alpine PORTS="8080:80" ${SCRIPT_NAME}
  ${SCRIPT_NAME} --dry-run
EOF
}

# Show version information
show_version() {
    echo "${SCRIPT_NAME} v${VERSION}"
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
                show_version
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
        if ! command_exists "${dep}"; then
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
    local dirs=("${DATA_DIR}" "${CONFIG_DIR}")
    
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
    if [[ -n "${HOSTNAME}" ]]; then
        cmd+=" --hostname=${HOSTNAME}"
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
        cmd+=" -v ${CERTS_DIR}/ca.pem:/etc/ssl/certs/ca.pem:ro"
        cmd+=" -v ${CERTS_DIR}/server.pem:/etc/ssl/certs/server.pem:ro"
        cmd+=" -v ${CERTS_DIR}/server.key:/etc/ssl/private/server.key:ro"
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

# Wait for container to be healthy
wait_for_container() {
    local max_attempts=30
    local attempt=1

    info "Waiting for container to be ready..."
    
    if [[ "${DRY_RUN}" == "true" ]]; then
        info "Would wait for container readiness (dry run)"
        return 0
    fi

    while [[ $attempt -le $max_attempts ]]; do
        if docker ps --filter "name=${CONTAINER_NAME}" --filter "health=healthy" --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
            success "Container is healthy"
            return 0
        fi

        if ! docker ps --filter "name=${CONTAINER_NAME}" --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
            error "Container ${CONTAINER_NAME} is not running"
        fi

        debug "Attempt $attempt/$max_attempts: Container not ready yet..."
        sleep 2
        attempt=$((attempt + 1))
    done

    error "Container did not become healthy within $((max_attempts * 2)) seconds"
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
  Ports:       ${PORTS:-None}
  Network:     ${NETWORK:-default}
  Hostname:    ${HOSTNAME:-auto}

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
        
        wait_for_container
        verify_deployment
    fi

    show_summary
    success "Deployment process completed"
}

# Run main function with all arguments
main "$@"