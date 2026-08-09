$ErrorActionPreference = "Stop"

$APP_NAME = "InternetCafe Server"
$APP_VERSION = "1.0.0"

$DOCKER_IMAGE = "eddev42525/pc_timer_rails:1.0.0"

$INSTALL_DIR = Join-Path -Path $env:ProgramData -ChildPath "InternetCafe"
$STORAGE_DIR = Join-Path -Path $INSTALL_DIR -ChildPath "storage"

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

$COMPOSE_SOURCE = Join-Path -Path $SCRIPT_DIR -ChildPath "docker-compose.yml"
$COMPOSE_FILE = Join-Path -Path $INSTALL_DIR -ChildPath "docker-compose.yml"
$CONFIG_FILE = Join-Path -Path $INSTALL_DIR -ChildPath ".env"

$REPAIR_INSTALLATION = $false

function log {
    param ([string]$Message)
    Write-Host ""
    Write-Host "==> $Message"
}

function success {
    param ([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function error_message {
    param ([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function fail {
    param ([string]$Message)
    error_message $Message
    exit 1
}

function check_windows {
    $version = [System.Environment]::OSVersion.Version

    if ($version.Major -lt 10) {
        fail "Windows 10 or newer is required."
    }

    success "Supported Windows version: $version"
}

function check_architecture {
    $architecture = $null

    # Preferred method.
    try {
        $runtimeInfo = [System.Runtime.InteropServices.RuntimeInformation]

        if ($null -ne $runtimeInfo) {
            $architecture = $runtimeInfo::OSArchitecture.ToString()
        }
    }
    catch {
        $architecture = $null
    }

    # Fallback for Windows PowerShell environments.
    if ([string]::IsNullOrWhiteSpace($architecture)) {
        $architecture = $env:PROCESSOR_ARCHITEW6432

        if ([string]::IsNullOrWhiteSpace($architecture)) {
            $architecture = $env:PROCESSOR_ARCHITECTURE
        }
    }

    switch ($architecture.ToUpperInvariant()) {
        "X64" {
            success "Supported architecture: amd64 / x64"
            return
        }

        "AMD64" {
            success "Supported architecture: amd64 / x64"
            return
        }

        "ARM64" {
            success "Supported architecture: arm64"
            return
        }

        default {
            fail @"
Unable to determine a supported architecture.

Detected architecture: $architecture

InternetCafe Server currently supports:

  amd64 / x64
  arm64
"@
        }
    }
}

function check_command {
    param (
        [string]$Command,
        [string]$Name
    )

    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        success "$Name found"
    }
    else {
        fail "$Name is required but was not found."
    }
}

function check_docker {
    check_command "docker" "Docker"

    docker info *> $null

    if ($LASTEXITCODE -ne 0) {
        fail "Docker is installed but the Docker daemon is not running. Please start Docker Desktop."
    }

    $version = docker version --format '{{.Server.Version}}'

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($version)) {
        fail "Unable to determine the Docker server version."
    }

    success "Docker $version"
    success "Docker daemon is running"
}

function check_compose {
    $version = docker compose version --short 2>$null

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($version)) {
        fail "Docker Compose is required but was not found."
    }

    success "Docker Compose $version"
}

function check_internet {
    try {
        $response = Invoke-WebRequest `
            -Uri "https://www.google.com" `
            -Method Head `
            -TimeoutSec 10 `
            -UseBasicParsing

        if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400) {
            success "Internet connection available"
            return
        }
    }
    catch {
    }

    fail "Unable to access the Internet."
}

function check_distribution_files {
    if (-not (Test-Path -LiteralPath $COMPOSE_SOURCE -PathType Leaf)) {
        fail @"
docker-compose.yml was not found next to install.ps1.

Expected:

$COMPOSE_SOURCE
"@
    }

    success "Distribution files found"
}

function compose {
    param (
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    $composeArguments = @(
        "compose"
        "--project-directory"
        $INSTALL_DIR
        "--env-file"
        $CONFIG_FILE
        "-f"
        $COMPOSE_FILE
    )

    $composeArguments += $Arguments

    Write-Host ""
    Write-Host "Compose env file: $CONFIG_FILE" -ForegroundColor DarkGray

    & docker @composeArguments

    if ($LASTEXITCODE -ne 0) {
        throw "Docker Compose command failed."
    }
}

function test_valid_env {
    if (-not (Test-Path -LiteralPath $CONFIG_FILE -PathType Leaf)) {
        return $false
    }

    $content = Get-Content -LiteralPath $CONFIG_FILE -Raw -ErrorAction SilentlyContinue

    if ([string]::IsNullOrWhiteSpace($content)) {
        return $false
    }

    $requiredVariables = @(
        "SECRET_KEY_BASE",
        "ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY",
        "ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY",
        "ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT",
        "SMTP_ADDRESS",
        "SMTP_PORT",
        "SMTP_USERNAME",
        "SMTP_PASSWORD",
        "SMTP_DOMAIN",
        "SMTP_FROM"
    )

    foreach ($variable in $requiredVariables) {
        if ($content -notmatch "(?m)^$variable=.+$") {
            return $false
        }
    }

    return $true
}

function check_existing_installation {
    log "Checking existing installation"

    if (-not (Test-Path -LiteralPath $INSTALL_DIR -PathType Container)) {
        success "No existing installation found"
        return
    }

    $envExists = Test-Path -LiteralPath $CONFIG_FILE -PathType Leaf
    $composeExists = Test-Path -LiteralPath $COMPOSE_FILE -PathType Leaf
    $storageExists = Test-Path -LiteralPath $STORAGE_DIR -PathType Container

    # Completely empty installation directory.
    if (-not $envExists -and -not $composeExists -and -not $storageExists) {
        success "Installation directory exists but is empty"
        return
    }

    # An installation directory exists but configuration
    # was never successfully completed.
    if (-not (test_valid_env)) {
        Write-Host ""
        Write-Host "========================================"
        Write-Host " Incomplete Installation Detected"
        Write-Host "========================================"
        Write-Host ""
        Write-Host "The previous installation did not"
        Write-Host "finish configuration."
        Write-Host ""
        Write-Host "The installer will continue from the"
        Write-Host "configuration stage."
        Write-Host ""

        if ($envExists) {
            Remove-Item -LiteralPath $CONFIG_FILE -Force
            success "Incomplete configuration removed"
        }

        return
    }

    # At this point we have a valid .env,
    # so this is a real existing installation.
    Write-Host ""
    Write-Host "========================================"
    Write-Host " Existing Installation Detected"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "An InternetCafe Server installation"
    Write-Host "already exists at:"
    Write-Host ""
    Write-Host "  $INSTALL_DIR"
    Write-Host ""
    Write-Host "Your configuration and database will"
    Write-Host "be preserved."
    Write-Host ""

    $answer = Read-Host "Continue with repair? [y/N]"

    if ($answer -eq "y" -or $answer -eq "Y") {
        $script:REPAIR_INSTALLATION = $true
        success "Repair installation selected"
    }
    else {
        Write-Host ""
        Write-Host "Installation cancelled."
        exit 0
    }
}

function stop_existing_installation {
    log "Stopping existing InternetCafe Server"

    if (-not (Test-Path -LiteralPath $COMPOSE_FILE -PathType Leaf)) {
        success "No existing Docker Compose installation found"
        return
    }

    compose down

    success "Existing InternetCafe Server stopped"
}

function prepare_directories {
    log "Preparing installation directory"

    New-Item -ItemType Directory -Path $INSTALL_DIR -Force | Out-Null
    New-Item -ItemType Directory -Path $STORAGE_DIR -Force | Out-Null

    success "Installation directory: $INSTALL_DIR"
    success "Storage directory prepared"
}

function install_compose_file {
    log "Installing Docker Compose configuration"

    Copy-Item -LiteralPath $COMPOSE_SOURCE -Destination $COMPOSE_FILE -Force

    success "Docker Compose configuration installed"
}

function validate_compose {
    log "Validating Docker Compose configuration"

    compose config *> $null

    if ($LASTEXITCODE -ne 0) {
        fail "Docker Compose configuration is invalid."
    }

    success "Docker Compose configuration valid"
}

function generate_secret {
    param (
        [int]$Bytes = 32
    )

    $buffer = New-Object byte[] $Bytes
    $random = [System.Security.Cryptography.RandomNumberGenerator]::Create()

    try {
        $random.GetBytes($buffer)
    }
    finally {
        $random.Dispose()
    }

    return (
        [System.BitConverter]::ToString($buffer) `
            -replace "-", ""
    ).ToLowerInvariant()
}

function prompt_required {
    param ([string]$Prompt)

    while ($true) {
        $value = Read-Host $Prompt

        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return $value
        }
    }
}

function prompt_default {
    param (
        [string]$Prompt,
        [string]$Default
    )

    $value = Read-Host "$Prompt [$Default]"

    if ([string]::IsNullOrWhiteSpace($value)) {
        return $Default
    }

    return $value
}

function secure_string_to_plaintext {
    param ([Security.SecureString]$SecureString)

    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)

    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
    }
}

function prompt_password {
    param ([string]$Prompt)

    while ($true) {
        $secure = Read-Host $Prompt -AsSecureString
        $value = secure_string_to_plaintext $secure

        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return $value
        }
    }
}

function prompt_owner_password {
    while ($true) {
        $password = prompt_password "Owner password"
        $confirmation = prompt_password "Confirm password"

        if ($password -ceq $confirmation) {
            return $password
        }

        Write-Host "Passwords do not match. Please try again." -ForegroundColor Yellow
    }
}

function create_env {
    log "Configuring InternetCafe Server"

    if (Test-Path -LiteralPath $CONFIG_FILE -PathType Leaf) {
        success "Existing .env found; keeping current configuration"
        return
    }

    Write-Host ""
    Write-Host "SMTP Configuration"
    Write-Host "------------------"
    Write-Host ""

    $smtp_address = prompt_required "SMTP server"
    $smtp_port = prompt_default "SMTP port" "587"
    $smtp_username = prompt_required "SMTP username"
    $smtp_password = prompt_password "SMTP password"
    $smtp_domain = prompt_required "SMTP domain"
    $smtp_from = prompt_required "Sender email"

    $secret_key_base = generate_secret 32
    $encryption_primary_key = generate_secret 16
    $encryption_deterministic_key = generate_secret 16
    $encryption_key_derivation_salt = generate_secret 16

    $content = @"
SECRET_KEY_BASE=$secret_key_base
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=$encryption_primary_key
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=$encryption_deterministic_key
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=$encryption_key_derivation_salt

SMTP_ADDRESS=$smtp_address
SMTP_PORT=$smtp_port
SMTP_USERNAME=$smtp_username
SMTP_PASSWORD=$smtp_password
SMTP_DOMAIN=$smtp_domain
SMTP_FROM=$smtp_from
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true
"@

    Set-Content -LiteralPath $CONFIG_FILE -Value $content -Encoding UTF8

    success "Environment configuration created"
}

function pull_image {
    log "Pulling InternetCafe Server image"

    docker pull $DOCKER_IMAGE

    if ($LASTEXITCODE -ne 0) {
        fail "Unable to download Docker image."
    }

    success "Docker image downloaded"
}

function start_web {
    log "Starting Rails server"

    compose up -d web

    success "Rails server container started"
}

function wait_for_web {
    log "Waiting for Rails server"

    $attempts = 30

    for ($i = 1; $i -le $attempts; $i++) {
        try {
            $response = Invoke-WebRequest `
                -Uri "http://127.0.0.1:3000/" `
                -Method Get `
                -TimeoutSec 2 `
                -UseBasicParsing

            if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400) {
                success "Rails server is responding"
                return
            }
        }
        catch {
        }

        Start-Sleep -Seconds 2
    }

    error_message "Rails server did not become ready."

    Write-Host ""
    Write-Host "Recent Rails logs:"
    Write-Host ""

    compose logs --tail=100 web

    exit 1
}

function owner_exists {
    try {
        $result = & docker compose `
            --project-directory $INSTALL_DIR `
            --env-file $CONFIG_FILE `
            -f $COMPOSE_FILE `
            exec -T `
            web `
            bin/rails installation:owner_exists `
            2>$null

        if ($LASTEXITCODE -ne 0) {
            return $false
        }

        return (($result -join "`n").Trim() -eq "true")
    }
    catch {
        return $false
    }
}

function create_owner {
    log "Creating owner account"

    $owner_email = prompt_required "Owner email"
    $owner_password = prompt_owner_password

    try {
        & docker compose `
            --project-directory $INSTALL_DIR `
            --env-file $CONFIG_FILE `
            -f $COMPOSE_FILE `
            exec -T `
            -e "OWNER_EMAIL=$owner_email" `
            -e "OWNER_PASSWORD=$owner_password" `
            web `
            bin/rails installation:configure_owner

        if ($LASTEXITCODE -ne 0) {
            fail "Unable to create owner account."
        }
    }
    finally {
        Remove-Item Env:\OWNER_EMAIL -ErrorAction SilentlyContinue
        Remove-Item Env:\OWNER_PASSWORD -ErrorAction SilentlyContinue
    }

    success "Owner account created"
}

function update_owner {
    log "Updating owner account"

    $current_email = (
        & docker compose `
            --project-directory $INSTALL_DIR `
            --env-file $CONFIG_FILE `
            -f $COMPOSE_FILE `
            exec -T `
            web `
            bin/rails installation:owner_email
    ) -join "`n"

    $current_email = $current_email.Trim()

    Write-Host ""
    Write-Host "Current owner email:"
    Write-Host "  $current_email"
    Write-Host ""

    $owner_email = Read-Host "New owner email [$current_email]"

    if ([string]::IsNullOrWhiteSpace($owner_email)) {
        $owner_email = $current_email
    }

    $secure_password = Read-Host "New owner password (leave empty to keep current)" -AsSecureString
    $owner_password = secure_string_to_plaintext $secure_password

    & docker compose `
        --project-directory $INSTALL_DIR `
        --env-file $CONFIG_FILE `
        -f $COMPOSE_FILE `
        exec -T `
        -e "OWNER_EMAIL=$owner_email" `
        -e "OWNER_PASSWORD=$owner_password" `
        web `
        bin/rails installation:configure_owner

    if ($LASTEXITCODE -ne 0) {
        fail "Unable to update owner account."
    }

    success "Owner account updated"
}

function configure_owner {
    log "Checking owner account"

    if (-not (owner_exists)) {
        Write-Host ""
        Write-Host "No owner account exists."
        Write-Host ""
        Write-Host "An owner account is required to use"
        Write-Host "the InternetCafe Server."
        Write-Host ""

        create_owner
        return
    }

    success "Owner account already exists"

    Write-Host ""
    $answer = Read-Host "Would you like to update the owner account? [y/N]"

    if ($answer -eq "y" -or $answer -eq "Y") {
        update_owner
    }
    else {
        success "Existing owner account preserved"
    }
}

function start_jobs {
    log "Starting background jobs"

    compose up -d jobs

    success "Background jobs started"
}

function get_server_ip {
    try {
        $addresses = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object {
                $_.IPAddress -notlike "127.*" -and
                $_.IPAddress -notlike "169.254.*"
            }

        $ip = $addresses | Select-Object -First 1 -ExpandProperty IPAddress

        if (-not [string]::IsNullOrWhiteSpace($ip)) {
            return $ip
        }
    }
    catch {
    }

    return "localhost"
}

function show_success {
    $server_ip = get_server_ip

    Write-Host ""
    Write-Host "========================================"
    Write-Host " InternetCafe Server Installed!"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Server URL:"
    Write-Host "  http://${server_ip}:3000"
    Write-Host ""
    Write-Host "Installation directory:"
    Write-Host "  $INSTALL_DIR"
    Write-Host ""
    Write-Host "Configuration:"
    Write-Host "  $CONFIG_FILE"
    Write-Host ""
    Write-Host "Storage:"
    Write-Host "  $STORAGE_DIR"
    Write-Host ""
    Write-Host "Useful commands:"
    Write-Host ""
    Write-Host "  cd `"$INSTALL_DIR`""
    Write-Host "  docker compose ps"
    Write-Host "  docker compose logs -f"
    Write-Host ""
}

function main {
    Write-Host ""
    Write-Host "========================================"
    Write-Host "       $APP_NAME Installer"
    Write-Host "              v$APP_VERSION"
    Write-Host "========================================"

    log "Checking prerequisites"

    check_windows
    check_architecture
    check_docker
    check_compose
    check_internet
    check_distribution_files

    check_existing_installation

    if ($REPAIR_INSTALLATION) {
        stop_existing_installation
    }

    prepare_directories
    install_compose_file
    create_env
    validate_compose

    pull_image

    start_web
    wait_for_web

    configure_owner

    start_jobs

    show_success
}

main
