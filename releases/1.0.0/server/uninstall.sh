#!/usr/bin/env bash

set -Eeuo pipefail

APP_NAME="InternetCafe Server"
INSTALL_DIR="/opt/internetcafe"

COMPOSE_FILE="${INSTALL_DIR}/docker-compose.yml"
ENV_FILE="${INSTALL_DIR}/.env"
STORAGE_DIR="${INSTALL_DIR}/storage"

# ========================================
# Output helpers
# ========================================

log() {
    echo
    echo "==> $1"
}

success() {
    echo "✓ $1"
}

error() {
    echo "✗ $1" >&2
}

fail() {
    error "$1"
    exit 1
}

# ========================================
# Basic checks
# ========================================

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        fail "Please run this uninstaller with sudo:

sudo ./uninstall.sh"
    fi
}

check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        success "Docker not found; nothing to stop"
        return
    fi

    if ! docker info >/dev/null 2>&1; then
        success "Docker daemon is not running; nothing to stop"
    else
        success "Docker found"
    fi
}

# ========================================
# Installation checks
# ========================================

check_installation() {
    log "Checking InternetCafe Server installation"

    if [[ ! -d "${INSTALL_DIR}" ]]; then
        success "InternetCafe Server is not installed"
        exit 0
    fi

    success "Installation found at ${INSTALL_DIR}"
}

# ========================================
# Docker Compose
# ========================================

compose() {
    docker compose \
        --project-directory "${INSTALL_DIR}" \
        --env-file "${ENV_FILE}" \
        -f "${COMPOSE_FILE}" \
        "$@"
}

stop_containers() {
    log "Stopping InternetCafe Server"

    if [[ ! -f "${COMPOSE_FILE}" ]]; then
        success "Docker Compose configuration not found"
        return
    fi

    if ! command -v docker >/dev/null 2>&1; then
        success "Docker is not installed; skipping container cleanup"
        return
    fi

    if ! docker info >/dev/null 2>&1; then
        success "Docker daemon is not running; skipping container cleanup"
        return
    fi

    # Docker Compose requires the env file specified with --env-file.
    # If it does not exist, create a temporary empty one for cleanup.
    local temporary_env=false

    if [[ ! -f "${ENV_FILE}" ]]; then
        touch "${ENV_FILE}"
        chmod 600 "${ENV_FILE}"
        temporary_env=true
    fi

    compose down

    if [[ "${temporary_env}" == "true" ]]; then
        rm -f "${ENV_FILE}"
    fi

    success "InternetCafe Server containers removed"
}

# ========================================
# Remove application files
# ========================================

remove_compose_file() {
    log "Removing application configuration"

    if [[ -f "${COMPOSE_FILE}" ]]; then
        rm -f "${COMPOSE_FILE}"
        success "Docker Compose configuration removed"
    else
        success "Docker Compose configuration already removed"
    fi
}

# ========================================
# Data removal
# ========================================

confirm_data_removal() {
    echo
    echo "========================================"
    echo " Remove InternetCafe Server Data"
    echo "========================================"
    echo
    echo "The following data will be permanently deleted:"
    echo
    echo "  ${ENV_FILE}"
    echo "  ${STORAGE_DIR}"
    echo
    echo "This may permanently delete:"
    echo
    echo "  - Database data"
    echo "  - Application data"
    echo "  - Server configuration"
    echo "  - SMTP credentials"
    echo "  - Rails encryption keys"
    echo
    echo "This action cannot be undone."
    echo

    local confirmation

    read -r -p "Type DELETE to permanently remove all data: " confirmation

    if [[ "${confirmation}" != "DELETE" ]]; then
        echo
        success "Full data removal cancelled"
        return 1
    fi

    return 0
}

remove_data() {
    log "Removing InternetCafe Server data"

    if [[ -f "${ENV_FILE}" ]]; then
        rm -f "${ENV_FILE}"
        success "Configuration removed"
    fi

    if [[ -d "${STORAGE_DIR}" ]]; then
        rm -rf "${STORAGE_DIR}"
        success "Application data removed"
    fi
}

# ========================================
# Remove installation directory
# ========================================

remove_empty_installation_directory() {
    if [[ ! -d "${INSTALL_DIR}" ]]; then
        return
    fi

    # At this point .env, storage, and docker-compose.yml
    # have been removed if full removal was selected.
    if find "${INSTALL_DIR}" -mindepth 1 -maxdepth 1 -print -quit | grep -q .; then
        return
    fi

    rmdir "${INSTALL_DIR}"

    success "Installation directory removed"
}

# ========================================
# Normal uninstall
# ========================================

show_preserved_data() {
    echo
    echo "========================================"
    echo " InternetCafe Server Uninstalled"
    echo "========================================"
    echo
    echo "Docker containers and application files"
    echo "have been removed."
    echo
    echo "Your configuration and application data"
    echo "have been preserved:"
    echo
    echo "  ${ENV_FILE}"
    echo "  ${STORAGE_DIR}"
    echo
    echo "You can reinstall InternetCafe Server"
    echo "without losing this data."
    echo
}

# ========================================
# Main
# ========================================

main() {
    echo
    echo "========================================"
    echo " ${APP_NAME} Uninstaller"
    echo "========================================"

    require_root
    check_docker
    check_installation

    echo
    echo "This will:"
    echo
    echo "  - Stop the InternetCafe Server"
    echo "  - Remove the Docker containers"
    echo "  - Remove the Docker Compose configuration"
    echo
    echo "Your configuration and application data"
    echo "will be preserved."
    echo

    local answer

    read -r -p "Continue with uninstall? [y/N]: " answer

    case "${answer}" in
        y|Y)
            ;;
        *)
            echo
            echo "Uninstallation cancelled."
            exit 0
            ;;
    esac

    stop_containers
    remove_compose_file

    echo
    read -r -p "Do you also want to permanently delete all server data? [y/N]: " answer

    case "${answer}" in
        y|Y)
            if confirm_data_removal; then
                remove_data
                remove_empty_installation_directory

                echo
                echo "========================================"
                echo " InternetCafe Server Completely Removed"
                echo "========================================"
                echo
                success "All server data has been permanently removed"
            else
                show_preserved_data
            fi
            ;;
        *)
            show_preserved_data
            ;;
    esac
}

main "$@"
