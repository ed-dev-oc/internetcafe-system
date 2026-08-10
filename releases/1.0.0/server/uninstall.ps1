$ErrorActionPreference = "Stop"

$APP_NAME = "InternetCafe Server"

$INSTALL_DIR = Join-Path $env:ProgramData "InternetCafe"
$STORAGE_DIR = Join-Path $INSTALL_DIR "storage"
$COMPOSE_FILE = Join-Path $INSTALL_DIR "docker-compose.yml"
$ENV_FILE = Join-Path $INSTALL_DIR ".env"


# ========================================
# Output helpers
# ========================================

function log {
    param (
        [string]$Message
    )

    Write-Host ""
    Write-Host "==> $Message"
}

function success {
    param (
        [string]$Message
    )

    Write-Host "[OK] $Message" -ForegroundColor Green
}

function error_message {
    param (
        [string]$Message
    )

    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function fail {
    param (
        [string]$Message
    )

    error_message $Message
    exit 1
}


# ========================================
# Basic checks
# ========================================

function require_admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)

    if (-not $principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )) {
        fail @"
Please run this uninstaller as Administrator.

Example:

Right-click PowerShell
→ Run as Administrator

Then run:

.\uninstall.ps1
"@
    }
}

function check_installation {
    log "Checking InternetCafe Server installation"

    if (-not (Test-Path -LiteralPath $INSTALL_DIR -PathType Container)) {
        success "InternetCafe Server is not installed"
        exit 0
    }

    success "Installation found at $INSTALL_DIR"
}


# ========================================
# Docker Compose
# ========================================

function compose {
    param (
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    & docker compose `
        --project-directory "$INSTALL_DIR" `
        --env-file "$ENV_FILE" `
        -f "$COMPOSE_FILE" `
        @Arguments

    if ($LASTEXITCODE -ne 0) {
        throw "Docker Compose command failed."
    }
}

function stop_containers {
    log "Stopping InternetCafe Server"

    if (-not (Test-Path -LiteralPath $COMPOSE_FILE -PathType Leaf)) {
        success "Docker Compose configuration not found"
        return
    }

    $dockerCommand = Get-Command docker -ErrorAction SilentlyContinue

    if (-not $dockerCommand) {
        success "Docker is not installed; skipping container cleanup"
        return
    }

    & docker info *> $null

    if ($LASTEXITCODE -ne 0) {
        success "Docker daemon is not running; skipping container cleanup"
        return
    }

    # Docker Compose requires the env file specified with --env-file.
    # If the installation was interrupted before .env was created,
    # create a temporary empty file for cleanup.

    $temporaryEnv = $false

    if (-not (Test-Path -LiteralPath $ENV_FILE -PathType Leaf)) {
        New-Item -ItemType File -Path $ENV_FILE -Force | Out-Null
        $temporaryEnv = $true

        success "Created temporary environment file for cleanup"
    }

    try {
        compose down

        success "InternetCafe Server containers removed"
    }
    finally {
        if ($temporaryEnv -and
            (Test-Path -LiteralPath $ENV_FILE -PathType Leaf)) {

            Remove-Item -LiteralPath $ENV_FILE -Force
        }
    }
}


# ========================================
# Remove application files
# ========================================

function remove_compose_file {
    log "Removing application configuration"

    if (Test-Path -LiteralPath $COMPOSE_FILE -PathType Leaf) {
        Remove-Item -LiteralPath $COMPOSE_FILE -Force

        success "Docker Compose configuration removed"
    }
    else {
        success "Docker Compose configuration already removed"
    }
}


# ========================================
# Full data removal
# ========================================

function confirm_data_removal {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " Remove InternetCafe Server Data"
    Write-Host "========================================"
    Write-Host ""

    Write-Host "The following data will be permanently deleted:"
    Write-Host ""

    Write-Host "  $ENV_FILE"
    Write-Host "  $STORAGE_DIR"
    Write-Host ""

    Write-Host "This may permanently delete:"
    Write-Host ""
    Write-Host "  - Database data"
    Write-Host "  - Application data"
    Write-Host "  - Server configuration"
    Write-Host "  - SMTP credentials"
    Write-Host "  - Rails encryption keys"
    Write-Host ""

    Write-Host "This action cannot be undone." -ForegroundColor Red
    Write-Host ""

    $confirmation = Read-Host `
        "Type DELETE to permanently remove all data"

    if ($confirmation -cne "DELETE") {
        Write-Host ""
        success "Full data removal cancelled"
        return $false
    }

    return $true
}

function remove_data {
    log "Removing InternetCafe Server data"

    if (Test-Path -LiteralPath $ENV_FILE -PathType Leaf) {
        Remove-Item -LiteralPath $ENV_FILE -Force

        success "Configuration removed"
    }

    if (Test-Path -LiteralPath $STORAGE_DIR -PathType Container) {
        Remove-Item -LiteralPath $STORAGE_DIR -Recurse -Force

        success "Application data removed"
    }
}


# ========================================
# Installation directory
# ========================================

function remove_empty_installation_directory {
    if (-not (Test-Path -LiteralPath $INSTALL_DIR -PathType Container)) {
        return
    }

    $remaining = Get-ChildItem `
        -LiteralPath $INSTALL_DIR `
        -Force `
        -ErrorAction SilentlyContinue

    if ($remaining.Count -gt 0) {
        return
    }

    Remove-Item -LiteralPath $INSTALL_DIR -Force

    success "Installation directory removed"
}


# ========================================
# Final messages
# ========================================

function show_preserved_data {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " InternetCafe Server Uninstalled"
    Write-Host "========================================"
    Write-Host ""

    Write-Host "Docker containers and application files"
    Write-Host "have been removed."
    Write-Host ""

    Write-Host "Your configuration and application data"
    Write-Host "have been preserved:"
    Write-Host ""

    Write-Host "  $ENV_FILE"
    Write-Host "  $STORAGE_DIR"
    Write-Host ""

    Write-Host "You can reinstall InternetCafe Server"
    Write-Host "without losing this data."
    Write-Host ""
}

function show_complete_removal {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " InternetCafe Server Completely Removed"
    Write-Host "========================================"
    Write-Host ""

    success "All server data has been permanently removed"
}


# ========================================
# Main
# ========================================

function main {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " $APP_NAME Uninstaller"
    Write-Host "========================================"

    require_admin
    check_installation

    Write-Host ""
    Write-Host "This will:"
    Write-Host ""
    Write-Host "  - Stop the InternetCafe Server"
    Write-Host "  - Remove the Docker containers"
    Write-Host "  - Remove the Docker Compose configuration"
    Write-Host ""

    Write-Host "Your configuration and application data"
    Write-Host "will be preserved."
    Write-Host ""

    $answer = Read-Host "Continue with uninstall? [y/N]"

    if ($answer -ne "y" -and $answer -ne "Y") {
        Write-Host ""
        Write-Host "Uninstallation cancelled."
        exit 0
    }

    stop_containers
    remove_compose_file

    Write-Host ""

    $answer = Read-Host `
        "Do you also want to permanently delete all server data? [y/N]"

    if ($answer -eq "y" -or $answer -eq "Y") {

        if (confirm_data_removal) {
            remove_data
            remove_empty_installation_directory
            show_complete_removal
        }
        else {
            show_preserved_data
        }
    }
    else {
        show_preserved_data
    }
}

main