# Remote User PowerShell Tools Suite - Design Specification

**Date:** 2026-11-20  
**Status:** Approved  
**Author:** Antigravity / System Admin  

## 1. Executive Summary & Why

Remote users and field technicians frequently need setup assistance for remote telephony (VOIP), receipt/barcode printing, and secure internal connectivity. Configuring these manually via phone or remote desktop sessions is time-consuming, prone to error, and requires navigating multiple disparate installers and settings.

This project delivers a streamlined, single-command PowerShell onboarding and maintenance utility. A user or technician simply pastes a one-liner URL into PowerShell (`irm <URL> | iex`), and an interactive, user-friendly terminal menu appears with options to automatically configure VPN, VOIP (MicroSIP), thermal/barcode printer drivers, and a local print server bridge.

---

## 2. Requirements & Architecture

### 2.1 Invocation & Privileges
- **Launch Command**: `irm <URL> | iex` (or shortened alias via TinyURL/Bitly).
- **Execution Policy & Elevation**: Automatically checks if current PowerShell session has Administrator privileges (`WindowsBuiltInRole::Administrator`). If not, it self-elevates via UAC prompt (`Start-Process powershell -Verb RunAs ...`) with `-ExecutionPolicy Bypass`.
- **Operating System Floor**: Windows 10 / Windows 11 / Windows Server 2016+ (64-bit).

### 2.2 Main Menu Options
1. **`[1] Setup OpenVPN`**
   - Installs OpenVPN Community Client MSI.
   - Places the pre-configured profile `IPTSP VPN.ovpn` into `%USERPROFILE%\OpenVPN\config\` and `C:\Program Files\OpenVPN\config\`.
   - Creates a Desktop shortcut for OpenVPN GUI.
2. **`[2] Setup VOIP (MicroSIP)`**
   - Checks if MicroSIP is installed; downloads and installs silently if missing (`/S`).
   - Prompts for **Username**, **Extension**, and **Password**.
   - Displays default SIP Server IP (`182.163.126.253`), allowing the technician to press Enter or type a custom IP/domain.
   - Generates/updates `%APPDATA%\MicroSIP\MicroSIP.ini` with `[Account1]` settings, auto-run enabled, and audio settings.
3. **`[3] Install Printer Driver`**
   - Submenu:
     - `1. Gprinter Driver` (`Gprinter Driver.exe`)
     - `2. Rongta Driver` (`Rongta Driver.exe`)
     - `3. Dotmax Printer Driver` (`Dotmax Printer Driver.exe`)
     - `4. Return to Main Menu`
   - Downloads selected driver to `$env:TEMP\RemoteTools\` with progress tracking.
   - Launches the GUI setup wizard (`Start-Process -Wait`) so technician can select printer model and USB/COM port.
4. **`[4] Install Print Server`**
   - Configures Microsoft Defender exclusion for folder `C:\PrintServer` and process `print_server.exe` (`Add-MpPreference`).
   - Downloads `print_server.exe` into `C:\PrintServer\print_server.exe`.
   - Creates Desktop shortcut for user manual launch.
   - Registers Windows Startup entry to launch `print_server.exe` minimized on boot.
   - Starts `print_server.exe` minimized immediately to establish HTTP bridge on port 4444.
5. **`[5] Exit`**

### 2.3 Binary Hosting & Release Distribution
- Binary assets (`Gprinter Driver.exe` [115MB], `Rongta Driver.exe`, `Dotmax Printer Driver.exe`, `print_server.exe`, OpenVPN MSI, and MicroSIP installer) are hosted in GitHub Releases.
- GitHub hard limit blocks commits >100MB in git history (preventing `Gprinter Driver.exe` from standard git push). `publish-release.ps1` automates tagging and uploading assets directly to GitHub Releases.
- `IPTSP VPN.ovpn` is embedded directly as a fallback within `remote-tools.ps1` so VPN configuration never fails even with restricted web access.

---

## 3. Considered Approaches & Trade-offs

| Approach | Description | Trade-offs & Decision |
| :--- | :--- | :--- |
| **A. Monolithic Single-File Script (`remote-tools.ps1`)** *(Selected)* | Entire interactive menu, helper functions, and self-contained installer logic in one `.ps1` file. | Ideal for `irm <URL> \| iex`. Fast to load, no multi-request overhead before menu renders. Selected. |
| **B. Multi-Module Download Package** | Bootstrap script downloads separate `.psm1` modules over HTTP before running. | Slower to load, multiple points of network failure on remote connections. Rejected. |
| **C. Compiled EXE Wrapper** | Packaging PowerShell script into a compiled `.exe` using PS2EXE. | Defeats the requirement of running via a pasted `irm <URL> \| iex` web one-liner. Rejected. |

---

## 4. Security & Error Handling
- Safe TLS 1.2 / 1.3 enforcement (`[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13`).
- Graceful network error handling with retry and fallback URLs.
- Defender exclusions scoped strictly to `C:\PrintServer` and `print_server.exe`.
- Password input for VOIP uses `-AsSecureString` masked input where supported, writing cleanly to MicroSIP's password field.
