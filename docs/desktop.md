# InternetCafe Desktop

InternetCafe Desktop is the Windows workstation application for InternetCafe System.

It is installed on each café client PC and communicates with the InternetCafe Server to manage the workstation, display the café interface, synchronize sessions, and maintain the PC's operating state.

The Desktop application is distributed as **one Windows installer** containing the required Desktop components.

> **Source Code:** [InternetCafe Desktop Repository](https://github.com/ed-dev-oc/InternetCafeSystem)

## Components

The Desktop installation contains three applications:

```text
InternetCafe Desktop
│
├── InternetCafe.UI
├── InternetCafe.Agent
└── SystemMonitor
```

### InternetCafe.UI

`InternetCafe.UI` is the user-facing Windows kiosk application.

It:

* Displays the InternetCafe interface.
* Hosts Rails pages through Microsoft WebView2.
* Provides the device registration screen during first-time setup.
* Displays the normal kiosk interface after registration.
* Responds to the PC's locked, unlocked, maintenance, and compact states.
* Communicates with `InternetCafe.Agent` through a Windows named pipe.
* Displays an offline page when the server or local network cannot be reached.

When the PC has not yet been registered, the application displays the registration form. Once device configuration exists, it starts the main kiosk interface.

## InternetCafe.Agent

`InternetCafe.Agent` is the background component responsible for communication and workstation management.

It:

* Runs as a Windows Service in production.
* Registers the workstation with InternetCafe Server.
* Maintains the workstation's device configuration.
* Communicates with the InternetCafe Server.
* Sends signed requests to the server.
* Synchronizes session state.
* Sends and receives workstation status information.
* Provides communication endpoints for the UI and SystemMonitor.
* Maintains local state when temporary server connectivity problems occur.

The Agent is intended to run continuously in the background.

## SystemMonitor

`SystemMonitor` is the Desktop watchdog.

It:

* Monitors `InternetCafe.UI`.
* Restarts the UI when it unexpectedly stops.
* Sends heartbeat messages to the Agent.
* Monitors communication with the Agent.
* Attempts recovery when the Agent becomes unavailable.

The watchdog helps keep the café workstation operational without requiring staff to manually restart the application.

## Architecture

```text
                         InternetCafe Server
                                  │
                                  │ HTTP / REST
                                  │
                                  ▼
                       ┌─────────────────────┐
                       │ InternetCafe.Agent  │
                       │                     │
                       │ Background service  │
                       │ Server communication│
                       │ Session state       │
                       └──────────┬──────────┘
                                  │
                    Named Pipe    │
                                  │
                         ┌────────▼────────┐
                         │ InternetCafe.UI │
                         │                 │
                         │ WinForms kiosk  │
                         │ WebView2        │
                         └─────────────────┘
                                  ▲
                                  │
                         Process monitoring
                                  │
                         ┌────────┴────────┐
                         │  SystemMonitor  │
                         │                 │
                         │    Watchdog     │
                         └─────────────────┘
```

The Desktop application communicates with the InternetCafe Server through the Agent. The UI does not need to communicate with the Rails server directly for its device-management operations.

The UI and Agent communicate locally using the Windows named pipe:

```text
InternetCafeSystemPipe
```

## Requirements

Each café workstation should have:

* Windows 10 or newer
* 64-bit Windows
* InternetCafe Server available on the local network
* Microsoft WebView2 Runtime
* Network connectivity to the InternetCafe Server

The Desktop application is intended for Windows café workstations.

## Installation

InternetCafe Desktop is distributed using a single Windows installer.

Example:

```text
InternetCafeDesktop-1.0.0.exe
```

The installer installs the required Desktop applications together.

The customer does **not** need to install the Agent, UI, and SystemMonitor separately.

```text
InternetCafeDesktop-1.0.0.exe
             │
             ▼
       Desktop Installer
             │
       ┌─────┴─────┐
       │           │
       ▼           ▼
     Agent         UI
       │
       ▼
  SystemMonitor
```

The installer package is built using Advanced Installer.

## First-Time Setup

After installation, a workstation that has not yet been registered displays the device registration screen.

The registration process collects the workstation information required to identify the PC and connect it to the InternetCafe Server.

The UI communicates with the Agent during registration.

```text
InternetCafe.UI
       │
       │ RegisterDevice
       ▼
InternetCafe.Agent
       │
       │ HTTP request
       ▼
InternetCafe Server
       │
       │ Registration response
       ▼
InternetCafe.Agent
       │
       │ DeviceRegistered
       ▼
InternetCafe.UI
```

Once registration succeeds, the workstation stores its device configuration locally and can operate as a registered café PC.

## Device Configuration

The Desktop application stores its device configuration under:

```text
%ProgramData%\InternetCafeSystem\config\device.json
```

The configuration is managed by the Desktop application's configuration store.

Do not manually modify this file unless specifically instructed by the release documentation.

## Local Security Data

The Desktop application also stores its local IPC security key under:

```text
%ProgramData%\InternetCafeSystem\ipc\auth.key
```

This key is used to authenticate communication between the Desktop components.

It should not be shared between workstations.

Each workstation should maintain its own configuration and security data.

## Session State

The Desktop application maintains local session state under:

```text
%ProgramData%\InternetCafeSystem\session\state.dat
```

The local state allows the workstation to retain relevant session information during temporary communication problems with the server.

## Server Connection

The Desktop application requires the InternetCafe Server to be reachable from the workstation.

The server normally runs on a machine on the café's local network.

For example:

```text
InternetCafe Server
        │
        │ LAN
        ▼
┌───────────────────────────────┐
│ Café Network                  │
│                               │
│ PC 01 ── InternetCafe Desktop │
│ PC 02 ── InternetCafe Desktop │
│ PC 03 ── InternetCafe Desktop │
│ PC 04 ── InternetCafe Desktop │
└───────────────────────────────┘
```

The server should preferably use a **static IP address or a DHCP reservation**.

This prevents the server's address from unexpectedly changing and disconnecting the café workstations.

For example:

```text
Server IP:
192.168.1.100
```

The customer should configure the router or server so that this address remains stable.

> **Important:** The Desktop application depends on the InternetCafe Server address. Before registering the café workstations, make sure the server has a stable local IP address.

## Normal Operation

During normal operation:

1. The Agent runs in the background.
2. The UI displays the kiosk interface.
3. The Agent communicates with the InternetCafe Server.
4. The Agent synchronizes workstation and session state.
5. The UI receives runtime state from the Agent.
6. SystemMonitor continuously watches the UI.
7. SystemMonitor sends heartbeats to the Agent.
8. If the UI stops unexpectedly, SystemMonitor attempts to restart it.

## Kiosk States

The Desktop application can operate in different runtime states.

These include:

* Locked
* Unlocked
* Compact
* Maintenance

When a session is active, the UI can be unlocked according to the state received from the server.

When no active session exists, the workstation can remain locked.

The exact state behavior is controlled by the InternetCafe Server.

## Offline and Network Problems

The Desktop application includes handling for temporary connectivity problems.

If the local network or InternetCafe Server cannot be reached:

* The UI displays an offline page.
* Agent requests to the server may fail temporarily.
* The Agent logs communication failures.
* Local session state can be used where supported.
* The application retries communication when connectivity returns.

The Desktop application does not replace the InternetCafe Server. Server-dependent functionality requires the server to become reachable again.

## Automatic Recovery

SystemMonitor provides automatic recovery for common workstation failures.

### UI stopped

If `InternetCafe.UI` is no longer running, SystemMonitor can start it again.

### Agent communication failure

SystemMonitor monitors the Agent through its monitoring communication channel.

If the Agent becomes unavailable, the watchdog can attempt the configured recovery process.

This allows the workstation to recover from some application failures without requiring staff intervention.

## Logs

The Desktop components maintain local logs under the Windows ProgramData directory.

The UI logs are stored under:

```text
%ProgramData%\InternetCafeSystem\Internet Cafe\logs
```

If troubleshooting is required, these logs may be useful when diagnosing workstation problems.

## Repair and Reinstallation

The Desktop application is installed as a single product.

When a new Desktop installer is provided, use the installer appropriate for the desired version.

For example:

```text
InternetCafeDesktop-1.0.0.exe
InternetCafeDesktop-1.0.1.exe
InternetCafeDesktop-1.1.0.exe
```

The Desktop installer should be treated as the deployment package for all three Desktop components.

Do not manually replace only one executable unless the release instructions specifically require it.

## Uninstallation

InternetCafe Desktop is removed as one installed product.

Uninstalling the Desktop application removes the Desktop components installed by the Desktop installer.

Before uninstalling a workstation, make sure any information required for troubleshooting or re-registration has been preserved.

The InternetCafe Server's database and server storage are **not located on the workstation** and are not removed by uninstalling the Desktop application.

## Troubleshooting

### Server cannot be reached

Check that:

1. The InternetCafe Server is running.
2. The workstation is connected to the same local network.
3. The server's IP address has not changed.
4. The server's port is accessible.
5. The workstation has the correct registration/configuration.

### UI is not displayed

Check whether `InternetCafe.UI` is running.

SystemMonitor normally monitors the UI and attempts to restart it if it stops.

If the problem persists, check the Desktop logs.

### Workstation is not registered

If the device configuration is missing, the UI should display the registration screen.

If registration fails:

1. Confirm the InternetCafe Server is running.
2. Confirm the server address is reachable.
3. Confirm the workstation is connected to the correct network.
4. Retry registration.

### Server IP changed

If the InternetCafe Server receives a different IP address, registered workstations may no longer be able to communicate with it.

Configure the server with a stable IP address or DHCP reservation and update the workstation configuration according to the release instructions.

## Versioning

InternetCafe Desktop uses explicit release versions.

Examples:

```text
1.0.0
1.0.1
1.1.0
```

The Desktop release represents the complete Desktop installer and its included components.

For example:

```text
InternetCafe Desktop 1.1.0
```

may contain:

```text
InternetCafe.Agent
InternetCafe.UI
SystemMonitor
```

The customer installs the Desktop release as a single package.

## Relationship to InternetCafe Server

InternetCafe Desktop and InternetCafe Server are separate products.

```text
InternetCafe Server
        │
        │ HTTP / REST
        ▼
InternetCafe Desktop
        │
        ├── InternetCafe.Agent
        ├── InternetCafe.UI
        └── SystemMonitor
```

The Server provides the central café management system.

The Desktop application provides the Windows workstation functionality.

Both must be compatible with the release being deployed.

Always check the release documentation when upgrading either component.

## Related Projects

### InternetCafe Server

The central Rails server responsible for café management, PCs, sessions, users, coin slots, and server-side communication.

### InternetCafe ESP

ESP-based devices used for hardware functionality such as coin-slot communication.

The ESP devices communicate with the InternetCafe Server separately from the Windows Desktop application.

## Project Status

InternetCafe Desktop is actively developed.

Installation behavior, supported Windows versions, workstation functionality, and communication protocols may change between releases.

Always use the documentation provided with the specific Desktop release.

## License

InternetCafe Desktop is licensed under the MIT License.

See the `LICENSE` file for the complete license.
