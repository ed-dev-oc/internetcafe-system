# InternetCafe Server

InternetCafe Server is a self-hosted server application for managing an Internet café.

It provides the central server for managing computers, user accounts, sessions, coin slots, PC status, and communication with client devices.

The server runs as a Dockerized Rails application and is designed to operate on a local café network.

> **Source Code:** [InternetCafe Server Repository](https://github.com/ed-dev-oc/pc-timer-rails)

## Features

* Login and authentication
* User management
* Owner and administrator roles
* PC management
* Session management
* Coin slot management
* Dashboard
* PC status monitoring
* ESP communication
* PC lock and unlock
* Restart and shutdown commands
* REST/HTTP API
* Real-time updates using Turbo Streams
* Background job processing
* Email delivery for password reset and future notifications

## Architecture

InternetCafe Server runs as two Docker services:

```text
                    InternetCafe Server
                           │
             ┌─────────────┴─────────────┐
             │                           │
          web service                jobs service
             │                           │
       Rails application           Background jobs
             │
       REST / HTTP API
             │
       ┌─────┴─────────┐
       │               │
 Desktop Apps       ESP Devices
       │               │
    Café PCs       Coin Slots
```

The server is intended to run on a computer or server that is accessible by the café's local network.

The desktop application and ESP devices are separate projects and are not included in this repository.

---

# Requirements

## Linux

Currently supported:

* Ubuntu 22.04 or newer
* 64-bit AMD64
* 64-bit ARM64
* Docker
* Docker Compose v2
* Internet connection during installation

The Linux installer checks the operating system and CPU architecture before continuing.

> Other Linux distributions may work with Docker, but are not currently part of the officially tested configuration.

## Windows

Windows installation uses Docker Desktop.

Required:

* Windows 10 or newer
* 64-bit AMD64 / x64
* Docker Desktop
* WSL2
* WSL2 integration enabled in Docker Desktop
* Internet connection during installation

The Windows installer is provided as:

```text
install.ps1
```

Docker Desktop must be running before starting the installer.

### Docker Desktop WSL2 Integration

Open Docker Desktop and make sure WSL2 is enabled.

The Windows installer does not install Docker Desktop automatically.

Docker Desktop provides the Docker Engine and Docker Compose used by the InternetCafe Server.

> Windows ARM64 is not currently supported by the InternetCafe Server installer.

---

# Installation

The distribution contains the installation files required for the server:

```text
internetcafe-server/
├── install.sh
├── install.ps1
├── docker-compose.yml
├── .env.example
├── README.md
└── LICENSE
```

The same distribution contains both Linux and Windows installers.

Only use the installer appropriate for the operating system.

---

## Linux Installation

Make the installer executable:

```bash
chmod +x install.sh
```

Run the installer:

```bash
sudo ./install.sh
```

The installer checks:

1. Operating system
2. CPU architecture
3. Docker
4. Docker Compose
5. Required commands
6. Internet connectivity
7. Distribution files

It then prepares the server installation.

### Linux Installation Directory

The default Linux installation directory is:

```text
/opt/internetcafe
```

The directory contains:

```text
/opt/internetcafe/
├── .env
├── docker-compose.yml
└── storage/
```

The installer creates the directory automatically.

---

## Windows Installation

Open PowerShell in the directory containing the installer:

```powershell
cd "C:\path\to\internetcafe-server"
```

Run:

```powershell
.\install.ps1
```

If PowerShell blocks the script because of the execution policy, you can allow the script for the current PowerShell process:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Then run:

```powershell
.\install.ps1
```

The installer checks:

1. Windows version
2. CPU architecture
3. Docker
4. Docker Compose
5. Internet connectivity
6. Distribution files

Docker Desktop must already be installed and running.

### Windows Installation Directory

The default Windows installation directory is:

```text
C:\ProgramData\InternetCafe
```

The directory contains:

```text
C:\ProgramData\InternetCafe\
├── .env
├── docker-compose.yml
└── storage\
```

The installer creates the directory automatically.

---

# Configuration

During a new installation, the installer creates the `.env` file.

The installer generates the required Rails encryption secrets automatically.

Example:

```dotenv
SECRET_KEY_BASE=

ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=
```

These values are generated locally by the installer and should not be shared or committed to source control.

---

## SMTP

During a new installation, the installer asks for SMTP configuration.

Example:

```dotenv
SMTP_ADDRESS=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=user@example.com
SMTP_PASSWORD=your-password
SMTP_DOMAIN=example.com
SMTP_FROM=user@example.com
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true
```

SMTP is currently used for features such as password reset emails.

Additional notification features may use the same SMTP configuration in future releases.

### SMTP Password

The SMTP password is entered interactively by the installer.

The password is not displayed while typing.

The resulting password is stored in the server's `.env` file.

Protect the `.env` file because it contains sensitive credentials.

---

## `.env.example`

The distribution includes:

```text
.env.example
```

This file contains the available configuration keys without real credentials or secrets.

The installer does not copy secrets from `.env.example`.

Instead, it:

1. Generates the Rails encryption keys.
2. Requests SMTP configuration.
3. Creates the `.env` file.
4. Stores the resulting configuration in the installation directory.

---

# Interrupted Installation

The installer is designed to handle an installation that is interrupted before configuration is completed.

For example, if the user presses `Ctrl+C` while entering SMTP configuration, the `.env` file may not be created or may not represent a completed installation.

When the installer is run again, it checks whether the installation is actually configured before treating the directory as a valid existing installation.

This allows an interrupted installation to be safely continued instead of incorrectly entering the normal repair flow.

> Do not manually create an incomplete `.env` file unless you understand the required configuration.

---

# Owner Account

A new installation requires an owner account.

During installation, the installer asks for:

```text
Owner email:
Owner password:
Confirm password:
```

The account is created with the `owner` role.

The owner account is required before the server can be used.

---

## Existing Owner

If the installer detects an existing owner account, it does not automatically replace it.

Instead, the installer asks:

```text
Would you like to update the owner account? [y/N]:
```

Choosing `N` keeps the existing owner.

Choosing `Y` allows the owner email and password to be updated.

This allows the installer to safely be used for repairs without unexpectedly replacing an existing administrator account.

---

# Docker

The application uses two Docker services:

```text
web
jobs
```

## Web

The `web` service runs the Rails application.

## Jobs

The `jobs` service runs the background job worker.

Both services use the application's persistent storage.

The application image is published as a multi-architecture Docker image:

```text
eddev42525/pc_timer_rails:<version>
```

For example:

```text
eddev42525/pc_timer_rails:1.0.0
```

Docker automatically selects the appropriate image architecture.

Currently supported image architectures are:

* `linux/amd64`
* `linux/arm64`

---

# Docker Compose

The distribution includes:

```text
docker-compose.yml
```

The installer copies this file into the installation directory.

The Compose project is then run from the installation directory.

The default configuration exposes the Rails server on port `3000`:

```text
3000:80
```

After installation, the server can normally be accessed at:

```text
http://SERVER-IP:3000
```

For example:

```text
http://192.168.1.100:3000
```

The actual IP address depends on the server's local network configuration.

---

# Storage

The application uses persistent local storage.

## Linux

```text
/opt/internetcafe/storage
```

## Windows

```text
C:\ProgramData\InternetCafe\storage
```

The storage directory contains the application's SQLite databases.

The storage directory is intentionally kept outside the Docker image so that rebuilding, replacing, or updating the container does not remove the application's data.

### Important

Do not delete the `storage` directory unless you intentionally want to delete the server's data.

---

# Database

InternetCafe Server currently uses SQLite.

SQLite databases are stored inside the persistent storage directory.

The database is therefore independent of the Docker container itself.

This allows the container to be recreated without losing application data.

---

# Network

InternetCafe Server should normally be installed on a machine connected to the café's local network.

Client PCs and ESP devices communicate with the server over the LAN.

The server also requires Internet access for operations such as:

* Downloading Docker images
* SMTP communication
* Future external services

Internet access is not required for every local operation, but some features depend on external connectivity.

---

# Desktop Application

The InternetCafe desktop application is a separate project.

It is installed on the café's client PCs and communicates with InternetCafe Server using REST/HTTP APIs.

The desktop application consists of separate Windows components responsible for functions such as:

* Displaying the Rails interface
* PC locking and unlocking
* Restarting the PC
* Shutting down the PC
* Monitoring the client application
* Communicating with the server

The desktop application is **not included in this repository**.

It has its own repository, installer, and documentation.

---

# Real-Time Communication

The Rails web application uses Turbo Streams for real-time updates.

The desktop application displays the Rails interface through a WebView.

This allows the café operator to see changes such as PC and session status without manually refreshing the page.

The desktop application also communicates with the server independently through the REST API when Windows-specific operations are required.

---

# Offline Behavior

Some components are designed to tolerate temporary server connectivity problems.

## Coin Slot

Coin slot devices periodically send heartbeat information to the server.

When communication is temporarily unavailable, commands can be queued for later delivery.

## Client PC

When a PC has an active session, the desktop application maintains a local snapshot of the session state.

This allows the client PC to retain information about its active session if the server temporarily becomes unavailable or restarts.

The WebView interface itself requires the Rails server to be available.

Future versions may provide a local offline/error page in the desktop application when the server is unavailable.

---

# Repair Installation

The installer can be run again after an existing installation has already been created.

## Linux

```bash
sudo ./install.sh
```

## Windows

```powershell
.\install.ps1
```

If an existing installation is detected, the installer asks:

```text
Continue with repair? [y/N]:
```

If repair is selected, the installer stops the existing Docker Compose services before starting the installation again.

The installer preserves the existing:

### Linux

```text
/opt/internetcafe/.env
/opt/internetcafe/storage/
```

### Windows

```text
C:\ProgramData\InternetCafe\.env
C:\ProgramData\InternetCafe\storage\
```

The repair process does not intentionally remove application data.

It does **not** use:

```bash
docker compose down -v
```

Docker volumes are therefore not intentionally removed by the repair process.

---

# Updating

InternetCafe Server uses explicit Docker image versions.

For example:

```text
eddev42525/pc_timer_rails:1.0.0
```

Customers are not required to upgrade simply because a newer version becomes available.

A customer may continue running the version they installed.

When upgrading is desired, the customer can explicitly install the newer release.

### Important

Application upgrades may include database migrations or other changes.

Do not manually change the Docker image tag without following the upgrade instructions for that release.

Upgrade instructions will be provided with releases that require special migration steps.

---

# Versioning Policy

Docker image versions use explicit release tags.

Example:

```text
1.0.0
1.1.0
1.2.0
```

The distribution installer references a specific version rather than automatically using `latest`.

For example, version `1.0.0` uses:

```text
eddev42525/pc_timer_rails:1.0.0
```

A future `1.1.0` release will reference:

```text
eddev42525/pc_timer_rails:1.1.0
```

This prevents a customer's installation from unexpectedly changing when a new image is published.

---

# Checking the Installation

## Linux

Go to the installation directory:

```bash
cd /opt/internetcafe
```

Check the running services:

```bash
sudo docker compose ps
```

View all logs:

```bash
sudo docker compose logs -f
```

View the Rails application:

```bash
sudo docker compose logs -f web
```

View background jobs:

```bash
sudo docker compose logs -f jobs
```

## Windows

Go to the installation directory:

```powershell
cd "C:\ProgramData\InternetCafe"
```

Check the running services:

```powershell
docker compose ps
```

View all logs:

```powershell
docker compose logs -f
```

View the Rails application:

```powershell
docker compose logs -f web
```

View background jobs:

```powershell
docker compose logs -f jobs
```

---

# Troubleshooting

## Docker is not running

### Linux

Check Docker:

```bash
sudo docker info
```

If Docker is not running:

```bash
sudo systemctl start docker
```

### Windows

Open Docker Desktop and make sure it is running.

Then check:

```powershell
docker info
```

If Docker Desktop is running but Docker commands fail, verify that WSL2 integration is enabled.

---

## Check Docker Compose

Linux and Windows:

```bash
docker compose version
```

PowerShell:

```powershell
docker compose version
```

---

## Check Containers

### Linux

```bash
cd /opt/internetcafe
sudo docker compose ps
```

### Windows

```powershell
cd "C:\ProgramData\InternetCafe"
docker compose ps
```

---

## View Rails Errors

### Linux

```bash
sudo docker compose logs web
```

### Windows

```powershell
docker compose logs web
```

---

## View Background Job Errors

### Linux

```bash
sudo docker compose logs jobs
```

### Windows

```powershell
docker compose logs jobs
```

---

## Port 3000 Is Already in Use

The Rails server uses port `3000` by default.

### Linux

Check which process is using port `3000`:

```bash
sudo ss -ltnp | grep :3000
```

If another InternetCafe Server installation is already running, do not start another copy manually.

Run the installer and select the repair option instead.

### Windows

Check which process is using port `3000`:

```powershell
Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue
```

If another InternetCafe Server installation is already running, do not start another copy manually.

Run the installer and select the repair option instead.

---

## SQLite Database Is Locked

If the server was recently restarted or multiple containers are starting simultaneously, wait a few seconds and check the container logs.

### Linux

```bash
sudo docker compose logs web
```

### Windows

```powershell
docker compose logs web
```

If the problem persists, restart the application:

```bash
docker compose restart
```

---

# Security

The `.env` file contains sensitive information including:

* Rails secret keys
* Active Record encryption keys
* SMTP credentials

Protect this file.

### Linux

The installer protects the `.env` file with restricted permissions.

You can verify:

```bash
sudo ls -l /opt/internetcafe/.env
```

If necessary:

```bash
sudo chmod 600 /opt/internetcafe/.env
```

### Windows

The `.env` file is stored under:

```text
C:\ProgramData\InternetCafe\.env
```

Protect access to the installation directory using normal Windows filesystem permissions.

Do not:

* Commit `.env` to Git
* Publish `.env`
* Share SMTP passwords
* Share Rails encryption keys
* Expose the Docker daemon to the public Internet

The server should normally be accessible only from the café's trusted network.

---

# Backup

Backup support is planned but is not currently included in the installer.

The application's persistent data is located under:

### Linux

```text
/opt/internetcafe/storage/
```

### Windows

```text
C:\ProgramData\InternetCafe\storage\
```

Until an official backup procedure is provided, administrators should understand that deleting this directory can result in permanent data loss.

Do not rely on the Docker image as a backup.

The Docker image contains the application, not the customer's database data.

---

# Uninstallation

Uninstallation is not currently automated.

Before removing the server, make sure any required data has been backed up.

The installation directory is:

### Linux

```text
/opt/internetcafe
```

### Windows

```text
C:\ProgramData\InternetCafe
```

Removing the installation directory, particularly the `storage` directory, can permanently delete the application's database.

---

# Open Source

InternetCafe Server is open-source software released under the MIT License.

See the `LICENSE` file for the complete license.

The source code is available for inspection, modification, and redistribution according to the terms of the license.

---

# Related Projects

## InternetCafe Server

This repository contains the server distribution and installation files.

## InternetCafe Desktop Application

The desktop application is installed on individual café PCs.

It communicates with the server and provides Windows-specific functionality.

The desktop application is maintained separately and has its own documentation and installer.

## ESP Firmware

ESP-based devices such as coin slot controllers are maintained separately from the server.

They communicate with InternetCafe Server over the network.

The ESP firmware is not included in this repository.

---

# Project Status

InternetCafe Server is actively developed.

Features, installation procedures, configuration options, and supported platforms may change between releases.

Always refer to the documentation included with the specific version being installed.

Current release:

```text
1.0.0
```

---

# License

InternetCafe Server is licensed under the MIT License.

See `LICENSE` for details.
