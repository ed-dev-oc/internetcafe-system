# InternetCafe System — Release 1.0.0

This directory contains the distribution files for **InternetCafe System version 1.0.0**.

InternetCafe System consists of three main components:

* **InternetCafe Server** — central Rails server
* **InternetCafe Desktop** — Windows desktop application installed on café PCs
* **InternetCafe ESP** — ESP8266 firmware for coin slot controllers

This release contains the specific files required to deploy version `1.0.0`.

## Downloads

Choose the component you want to install.

### InternetCafe Server

The server runs the central Rails application used by the InternetCafe System.

**Linux**

[Download `linux.zip`](./server/linux.zip)

Run:

```bash
chmod +x install.sh
sudo ./install.sh
```

**Windows**

[Download `windows.zip`](./server/windows.zip)

Run PowerShell as Administrator and execute:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

.\install.ps1
```

See the [Server Documentation](../../docs/server.md) for installation and configuration instructions.

---

### InternetCafe Desktop

The desktop application is installed on the café client PCs.

[Download InternetCafe Desktop 1.0.0](./desktop/InternetCafeDesktop-1.0.0.exe)

The desktop installer installs the required desktop components together.

See the [Desktop Documentation](../../docs/desktop.md) for installation and configuration instructions.

---

### InternetCafe ESP

The ESP8266 firmware is used by the coin slot controller.

[Download ESP8266 Firmware 1.0.0](./esp/firmware-1.0.0.bin)

The firmware is intended for the NodeMCU v2 / ESP-12E ESP8266 platform.

See the [ESP Documentation](../../docs/esp.md) for hardware setup, firmware flashing, and device configuration.

## Release Components

| Component            | Version | Platform        |
| -------------------- | ------- | --------------- |
| InternetCafe Server  | 1.0.0   | Linux / Windows |
| InternetCafe Desktop | 1.0.0   | Windows         |
| InternetCafe ESP     | 1.0.0   | ESP8266         |

## Installation Order

For a new InternetCafe System installation, the recommended order is:

1. Install the **InternetCafe Server**.
2. Configure the server's network and owner account.
3. Install the **InternetCafe Desktop** application on the café PCs.
4. Flash and configure the **ESP8266** coin slot controllers.
5. Register the desktop clients and ESP devices with the server.
6. Verify communication between all components.

## Documentation

* [Server Documentation](../../docs/server.md)
* [Desktop Documentation](../../docs/desktop.md)
* [ESP Documentation](../../docs/esp.md)

## Release Notes

See the release-specific documentation and project changelog for changes included in version 1.0.0.

---

## Release Components

```text
releases/
└── 1.0.0/
    ├── server/
    ├── desktop/
    └── esp/
```

Each component is installed separately.

The recommended deployment order is:

```text
1. Server
   ↓
2. Desktop
   ↓
3. ESP devices
```

The server should be configured and accessible from the café's local network before configuring the desktop applications and ESP devices.

---

# 1. Server

The InternetCafe Server provides the central system used by the desktop applications and ESP devices.

The server runs as a Dockerized Rails application.

## Requirements

### Linux

Supported configuration:

* Ubuntu 22.04 or newer
* AMD64 / x64
* ARM64
* Docker
* Docker Compose v2
* Internet connection during installation

### Windows

Windows installation uses Docker Desktop with WSL2.

Required:

* Windows 10 or newer
* AMD64 / x64
* Docker Desktop
* WSL2
* Internet connection during installation

The server must be connected to the café's local network.

## Installation

### Linux

Run:

```bash
chmod +x install.sh
sudo ./install.sh
```

### Windows

Open PowerShell in the server release directory and run:

```powershell
.\install.ps1
```

If Windows prevents the script from running because of the PowerShell execution policy, the administrator may need to adjust the execution policy according to their organization's security policy.

## Configuration

The installer asks for SMTP configuration and generates the required Rails secrets automatically.

A new installation also requires an owner account.

The installer preserves the existing `.env` configuration and application storage when performing a repair installation.

## Static IP

The server should use a **static IP address or a DHCP reservation**.

The desktop applications and ESP devices need to know the server's network address.

After installation, configure the server's IP address so that it does not unexpectedly change.

A DHCP reservation on the café's router is recommended when available.

The installer displays the detected server IP after installation.

For example:

```text
Server URL:
  http://192.168.1.100:3000
```

Record this address before configuring the desktop applications and ESP devices.

For complete server installation and configuration information, see:

```text
docs/server.md
```

---

# 2. Desktop

The InternetCafe Desktop application is installed on each café client PC.

The desktop distribution uses a single installer that installs the required desktop applications together.

The desktop applications communicate with the InternetCafe Server over the local network.

## Requirements

The client PC should:

* Run a supported Windows version
* Be connected to the same local network as the server
* Be able to reach the server's IP address
* Have the required Windows components for the desktop applications

## Installation

Run the desktop installer included in the `desktop` release directory.

The installer installs the required desktop applications together.

After installation, configure the desktop application to communicate with the InternetCafe Server.

Use the server address obtained during server installation.

Example:

```text
http://192.168.1.100:3000
```

Each café PC should be configured to communicate with the same server.

For complete desktop installation and configuration information, see:

```text
docs/desktop.md
```

---

# 3. ESP8266 Firmware

InternetCafe ESP is the firmware used by the coin slot controller.

Release `1.0.0` includes:

```text
esp/
└── firmware-1.0.0.bin
```

The firmware targets:

* ESP8266
* NodeMCU v2 / ESP-12E
* `nodemcuv2`

## Flashing

The firmware can be flashed using the Espressif Flash Download Tool.

Use the firmware file:

```text
firmware-1.0.0.bin
```

The appropriate flash configuration must be used for the firmware release.

Do not rename or modify the firmware binary before flashing.

After flashing, configure the ESP device's Wi-Fi and server settings through its device configuration interface.

## Hardware

The current firmware expects:

| Function          | ESP8266 Pin |  GPIO | Direction |
| ----------------- | ----------- | ----: | --------- |
| Coin pulse input  | D2          | GPIO4 | Input     |
| Coin relay output | D1          | GPIO5 | Output    |

The firmware uses:

* Coin selector / coin acceptor
* Relay module
* ESP8266 board such as NodeMCU v2 / ESP-12E

For complete firmware, hardware, configuration, and flashing information, see:

```text
docs/esp.md
```

---

# Deployment Order

For a new café installation, follow this order.

## Step 1 — Install the Server

Install InternetCafe Server on the machine that will act as the café server.

Confirm that the Rails application is running.

Check that the server can be reached from another machine on the local network.

Example:

```text
http://192.168.1.100:3000
```

## Step 2 — Configure the Server Network

Configure the server to use a stable IP address.

Preferably configure a DHCP reservation on the router or configure a static IP on the server.

Do not allow the server address to change unexpectedly.

## Step 3 — Install the Desktop Application

Install the desktop package on each café PC.

Configure each PC to use the server address.

For example:

```text
http://192.168.1.100:3000
```

Verify that the desktop application can communicate with the server.

## Step 4 — Flash the ESP Devices

Flash:

```text
firmware-1.0.0.bin
```

to each ESP8266 coin slot controller.

Configure the device's:

* Wi-Fi
* Device name
* Server URL
* Network settings
* Other device configuration

## Step 5 — Test the System

Before putting the system into production, verify:

* Server is reachable from the LAN
* Owner can log in
* Desktop applications can communicate with the server
* PCs appear correctly in the server
* ESP devices can register
* ESP heartbeat communication works
* Coin pulse detection works
* Coin relay control works
* PC locking and unlocking works
* Session management works
* Background jobs are running

---

# Version

This release is:

```text
InternetCafe System 1.0.0
```

Server image:

```text
eddev42525/pc_timer_rails:1.0.0
```

ESP firmware:

```text
firmware-1.0.0.bin
```

All components should use the corresponding `1.0.0` release when deploying a new system.

---

# Release Files

The release directory is organized by component:

```text
1.0.0/
├── server/
│   ├── install.sh
│   ├── install.ps1
│   ├── docker-compose.yml
│   └── .env.example
│
├── desktop/
│   └── <desktop installer>
│
└── esp/
    └── firmware-1.0.0.bin
```

The exact desktop installer filename depends on the installer package generated for this release.

---

# Documentation

Detailed documentation is maintained separately from the release files.

### Server

```text
docs/server.md
```

Contains server requirements, installation, configuration, Docker, networking, storage, repair installation, updating, troubleshooting, security, backup, and uninstallation information.

### Desktop

```text
docs/desktop.md
```

Contains desktop application installation, configuration, components, and operation information.

### ESP

```text
docs/esp.md
```

Contains ESP8266 firmware installation, flashing, hardware setup, network configuration, routes, and development information.

---

# Important Deployment Notes

### Server IP

The server should have a stable LAN IP address.

If the server's IP changes, desktop applications and ESP devices configured with the previous address may no longer be able to communicate with it.

### Version Consistency

When deploying a new café installation, use matching component versions whenever possible.

For this release:

```text
Server:  1.0.0
Desktop: 1.0.0
ESP:     1.0.0
```

### Data

The server's application data is stored separately from the Docker image.

Do not delete the server's persistent storage directory unless the server data is intentionally being removed.

### Network

The server, desktop PCs, and ESP devices should normally be connected to the same trusted café LAN.

Do not expose the Docker daemon or unnecessary management interfaces directly to the public Internet.

---

# Upgrade

Customers should not automatically upgrade to a newer version simply because a newer Docker image or firmware becomes available.

Release versions are explicit.

For example:

```text
1.0.0
1.1.0
1.2.0
```

Upgrade only when the corresponding release documentation has been reviewed.

Some releases may require:

* Database migrations
* Server configuration changes
* Desktop updates
* ESP firmware updates
* Additional deployment steps

Follow the documentation provided with the target release.

---

# Support / Troubleshooting

If a component does not work correctly, first determine which part of the system is affected:

```text
                 InternetCafe System
                         │
          ┌──────────────┼──────────────┐
          │              │              │
        Server         Desktop          ESP
          │              │              │
       Rails API       Windows PC     ESP8266
          │              │              │
       Database       PC control     Coin slot
```

Check the corresponding documentation:

```text
Server  → docs/server.md
Desktop → docs/desktop.md
ESP     → docs/esp.md
```

For server problems, check the Docker containers and logs.

For desktop problems, verify Windows installation and server connectivity.

For ESP problems, verify power, wiring, Wi-Fi configuration, server URL, and firmware installation.

---

# License

InternetCafe System is licensed under the MIT License.

See the repository `LICENSE` file for the complete license.
