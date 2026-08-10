# InternetCafe System

InternetCafe System is a self-hosted Internet café management system designed to manage café computers, user sessions, coin-operated access, and communication between the server, desktop clients, and ESP8266 coin-slot controllers.

The system is composed of three main components:

```text
                    InternetCafe System
                           │
             ┌─────────────┼─────────────┐
             │             │             │
             ▼             ▼             ▼
        Server          Desktop          ESP
       (Rails)        (Windows)       (ESP8266)
             │             │             │
             │             │             │
             └─────────────┼─────────────┘
                           │
                      Café Network
```

## Components

### InternetCafe Server

The server is the central application of the system.

It provides:

* User authentication
* Owner and administrator management
* PC management
* Session management
* Coin-slot management
* PC status monitoring
* REST/HTTP API
* Real-time updates using Turbo Streams
* Background job processing
* Email delivery
* Communication with desktop clients and ESP devices

The server runs as a Dockerized Rails application.

See:

[`docs/server.md`](docs/server.md)

### InternetCafe Desktop

The desktop application runs on each café client PC.

It provides the Windows-specific functionality required by the café computers, including:

* Displaying the InternetCafe interface
* PC locking and unlocking
* Session handling
* Restart and shutdown operations
* Client monitoring
* Communication with the InternetCafe Server

The desktop software is distributed through a single Windows installer that installs the required desktop components.

See:

[`docs/desktop.md`](docs/desktop.md)

### InternetCafe ESP

The ESP component is firmware for an ESP8266-based coin-slot controller.

It provides:

* Wi-Fi connectivity
* Device configuration
* Coin pulse detection
* Coin relay control
* Device registration
* Server heartbeat communication
* Queued outbound tasks
* HMAC-signed communication
* Remote configuration
* Device reboot support

The current hardware target is a NodeMCU v2 / ESP-12E.

See:

[`docs/esp.md`](docs/esp.md)

---

# System Architecture

A typical Internet café deployment looks like this:

```text
                         InternetCafe Server
                        ┌────────────────────┐
                        │   Rails Application│
                        │                    │
                        │  Web + API + Jobs  │
                        └─────────┬──────────┘
                                  │
                    ┌─────────────┼─────────────┐
                    │             │             │
                    │             │             │
                    ▼             ▼             ▼
                Café PC 1     Café PC 2     Café PC N
                Desktop       Desktop       Desktop
                    │             │             │
                    │             │             │
                    └─────────────┼─────────────┘
                                  │
                               LAN/Wi-Fi
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
                    ▼                           ▼
              ESP Coin Slot 1             ESP Coin Slot N
```

The server should normally be connected to the café's local network using a **static IP address** or a DHCP reservation.

This allows desktop clients and ESP devices to consistently locate the server.

---

# Repositories

The system is divided into separate repositories/components.

| Component       | Purpose                                |
| --------------- | -------------------------------------- |
| Server          | Central Rails application and API      |
| Desktop         | Windows client software                |
| ESP             | ESP8266 coin-slot firmware             |
| Main repository | Documentation and release distribution |

The main repository contains the documentation and customer release packages.

---

# Repository Structure

The main repository is organized as follows:

```text
internetcafe-system/
│
├── docs/
│   ├── server.md
│   ├── desktop.md
│   └── esp.md
│
├── releases/
│   └── 1.0.0/
│       └── ...
│
└── README.md
```

## Documentation

Detailed documentation is separated by system component:

```text
docs/
├── server.md
├── desktop.md
└── esp.md
```

### Server Documentation

[`docs/server.md`](docs/server.md)

Contains:

* Server requirements
* Linux installation
* Windows installation
* Docker configuration
* SMTP configuration
* Owner account setup
* Repair installation
* Updating
* Troubleshooting
* Storage
* Security
* Backup information
* Uninstallation

### Desktop Documentation

[`docs/desktop.md`](docs/desktop.md)

Contains:

* Desktop application architecture
* Windows components
* Installation
* Configuration
* Communication with the server
* Client PC behavior
* Troubleshooting

### ESP Documentation

[`docs/esp.md`](docs/esp.md)

Contains:

* ESP8266 hardware requirements
* Firmware installation
* Hardware wiring
* Wi-Fi configuration
* Device registration
* Coin pulse handling
* Relay operation
* Firmware development
* Release firmware information

---

# Releases

Customer-facing releases are stored under:

```text
releases/
```

Each release uses its own version directory.

Example:

```text
releases/
└── 1.0.0/
```

A release contains the files required to deploy that specific version of the system.

For example:

```text
releases/
└── 1.0.0/
    ├── server/
    │   ├── install.sh
    │   ├── install.ps1
    │   └── docker-compose.yml
    │
    ├── desktop/
    │   └── InternetCafe-Desktop-Setup.exe
    │
    └── esp/
        └── firmware-1.0.0.bin
```

The exact contents may change between releases.

## Server Release

The server release provides installers for supported operating systems.

### Linux

```bash
sudo ./install.sh
```

### Windows

Run PowerShell as an administrator and execute:

```powershell
.\install.ps1
```

The Windows server installation uses Docker Desktop with WSL2 integration.

See [`docs/server.md`](docs/server.md) for complete instructions.

## Desktop Release

The desktop application is distributed as a Windows installer.

The installer installs the required desktop applications together as a single installation.

See [`docs/desktop.md`](docs/desktop.md).

## ESP Release

The ESP firmware is distributed as a binary file.

Example:

```text
firmware-1.0.0.bin
```

The firmware can be flashed using the supported ESP flashing tool.

See [`docs/esp.md`](docs/esp.md) for hardware and flashing instructions.

---

# Installation Overview

A typical new café installation follows this order:

```text
1. Prepare the Server
        │
        ▼
2. Configure a Static IP
        │
        ▼
3. Install InternetCafe Server
        │
        ▼
4. Configure the Owner Account
        │
        ▼
5. Install InternetCafe Desktop
   on each café PC
        │
        ▼
6. Flash and Configure ESP
   coin-slot controllers
        │
        ▼
7. Register PCs and ESP devices
   with the Server
        │
        ▼
8. Test sessions and coin operation
```

The server should be installed and accessible from the café LAN before configuring the desktop clients and ESP devices.

---

# Network Requirements

InternetCafe System is primarily designed for operation on a local café network.

The recommended network arrangement is:

```text
                Router
                  │
        ┌─────────┴─────────┐
        │                   │
     Server              Café LAN
   Static IP                │
                            ├── PC 1
                            ├── PC 2
                            ├── PC 3
                            └── ESP devices
```

## Server IP Address

The server should use a **static IP address** or a DHCP reservation.

For example:

```text
Server IP: 192.168.1.100
Port:      3000
```

Clients can then consistently communicate with:

```text
http://192.168.1.100:3000
```

The exact address depends on the customer's network.

The server installer does not automatically configure the customer's router or Windows/Linux network interface.

The customer should configure the server's IP address as static before deploying the desktop clients and ESP devices.

---

# Versioning

InternetCafe System uses explicit release versions.

Example:

```text
1.0.0
1.1.0
1.2.0
```

Server Docker images also use explicit version tags.

Example:

```text
eddev42525/pc_timer_rails:1.0.0
```

Installers and firmware should correspond to the same system release whenever possible.

For example:

```text
InternetCafe System 1.0.0

Server:  1.0.0
Desktop: 1.0.0
ESP:     1.0.0
```

This makes it easier to identify which versions are deployed at a customer's site.

---

# Security

The system is intended primarily for use on a trusted café network.

Administrators should:

* Keep the server behind the café's network firewall
* Protect server credentials
* Protect Rails encryption keys
* Protect SMTP credentials
* Avoid exposing the Docker daemon to the public Internet
* Use secure owner passwords
* Keep production systems updated
* Back up important application data

The `.env` file used by the server contains sensitive credentials and encryption keys and must not be committed to source control.

---

# Development

Each component has its own development environment.

### Server

The server is built with:

* Ruby on Rails
* Docker
* Docker Compose
* SQLite
* Turbo Streams
* Background jobs

See [`docs/server.md`](docs/server.md).

### Desktop

The desktop application is built for Windows and contains the Windows-specific client components.

See [`docs/desktop.md`](docs/desktop.md).

### ESP

The ESP firmware is built using:

* C++
* Arduino
* PlatformIO
* ESP8266
* ArduinoJson
* LittleFS

See [`docs/esp.md`](docs/esp.md).

---

# Project Status

InternetCafe System is actively developed.

The server, desktop application, and ESP firmware may evolve independently between releases.

Always use the documentation and release files corresponding to the version being deployed.

---

# License

InternetCafe System is licensed under the MIT License.

See [`LICENSE`](LICENSE) for the complete license.
