# Remote User PowerShell Tools Suite 🛠️

A modern, menu-driven PowerShell onboarding and support utility designed for remote users and field technicians. Users launch the tool instantly by pasting a single one-liner command into PowerShell.

```powershell
irm https://raw.githubusercontent.com/Ismail-Saihan/powershell-tools/main/remote-tools.ps1 | iex
```
*(Or via a custom TinyURL link such as `irm https://tinyurl.com/your-tools | iex`)*

---

## 🚀 Key Features

* **Instant Web Execution**: Runs directly in memory via `irm | iex` with zero pre-installation required.
* **Automatic Administrator Elevation**: Detects user privileges and prompts for UAC elevation automatically if required.
* **1. OpenVPN Client & Profile Setup**:
  * Silently installs OpenVPN Community Client.
  * Automatically deploys and configures the `IPTSP VPN.ovpn` profile into `%USERPROFILE%\OpenVPN\config\` and `C:\Program Files\OpenVPN\config\`.
  * Creates an OpenVPN GUI Desktop shortcut.
* **2. VOIP Setup (MicroSIP)**:
  * Detects MicroSIP; downloads and installs silently if missing.
  * Prompts the user/technician for **Display Name**, **Extension / User ID**, and **SIP Password**.
  * Pre-configures SIP Server IP (defaulted to `182.163.126.250` with interactive override).
  * Automatically writes account settings and enables Windows auto-start in `MicroSIP.ini`.
* **3. Printer Driver Installation**:
  * Interactive sub-menu for popular thermal, label, and POS printers:
    * `1. Gprinter Driver` (Barcode & Label Printer - `Gprinter Driver.exe`)
    * `2. Rongta Driver` (Receipt & POS Printer - `Rongta Driver.exe`)
    * `3. Dotmax Driver` (Dot Matrix & Form Printer - `Dotmax Printer Driver.exe`)
  * Downloads installer with progress tracking and launches the vendor setup wizard for port/model selection.
* **4. Barcode Print Server Bridge**:
  * Automatically configures Microsoft Defender exclusions for `C:\PrintServer` folder and `print_server.exe` process.
  * Deploys `print_server.exe` to `C:\PrintServer`.
  * Creates a Desktop shortcut for manual launch.
  * Configures Windows Startup to run `print_server.exe` **automatically and minimized** on boot via a background VBScript runner.
  * Launches the HTTP bridge immediately on port `4444`.

---

## 📋 Quick Start Guide

### For Remote Users
1. Open Windows PowerShell (or right-click and choose **Run as administrator**).
2. Paste your one-liner and press **Enter**:
   ```powershell
   irm https://raw.githubusercontent.com/Ismail-Saihan/powershell-tools/main/remote-tools.ps1 | iex
   ```
3. The interactive menu will appear:
   ```text
   ==================================================================
          REMOTE USER ONBOARDING & SUPPORT TOOLS SUITE               
   ==================================================================
    Computer Name : DESKTOP-USER01
    Current User  : WORKGROUP\User
    Privileges    : Administrator (Elevated)
    Version       : 1.0.0
   ==================================================================

   Select an option from the menu below:

     [1] Setup OpenVPN (Install client + import IPTSP profile)
     [2] Setup VOIP (MicroSIP auto-install + configure credentials)
     [3] Install Printer Driver (Gprinter, Rongta, Dotmax)
     [4] Install Print Server (Defender exclusion + minimized startup)
     [5] Exit
   ```

---

## ⚙️ Administrator Setup & Publishing Guide

### Step 1: Create Your GitHub Repository
1. Create a new repository on [GitHub](https://github.com/new) named `powershell-tools`.
2. Connect your local git repository:
   ```powershell
   git remote add origin https://github.com/Ismail-Saihan/powershell-tools.git
   git branch -M main
   git push -u origin main
   ```

### Step 2: Publish Installer Assets to GitHub Releases
> **Important Note on File Sizes:** GitHub rejects normal git commits containing files larger than 100 MB. Because `Gprinter Driver.exe` is ~115 MB, installer executables are distributed via GitHub Releases.

Run the included automated release helper:
```powershell
.\publish-release.ps1 -GitHubUser "Ismail-Saihan" -GitHubRepo "powershell-tools" -Tag "v1.0.0" -UpdateScriptConfig
```

This helper will:
1. Update `remote-tools.ps1` with your GitHub username and repository name.
2. If GitHub CLI (`gh`) is installed, automatically create release `v1.0.0` and upload:
   * `print_server.exe`
   * `Printer Driver\Gprinter Driver.exe`
   * `Printer Driver\Rongta Driver.exe`
   * `Printer Driver\Dotmax Printer Driver.exe`
   * `IPTSP VPN.ovpn`
3. If `gh` is not installed, it provides instructions to drag-and-drop the files into GitHub's Web UI release editor.

### Step 3: Create a TinyURL Shortcut (Optional)
To make the command easy for users to type or copy from a message:
1. Copy your raw GitHub URL:
   `https://raw.githubusercontent.com/Ismail-Saihan/powershell-tools/main/remote-tools.ps1`
2. Go to [TinyURL](https://tinyurl.com) or [Bitly](https://bitly.com).
3. Paste the URL and create a custom alias, e.g. `tinyurl.com/carrybee-tools`.
4. Remote users can now simply run:
   ```powershell
   irm https://tinyurl.com/carrybee-tools | iex
   ```

---

## 🧪 Testing and Verification

A comprehensive automated test suite is included in `tests/`:

```powershell
# Run the complete test suite
powershell -ExecutionPolicy Bypass -File tests/run_all_tests.ps1
```

The test runner validates:
* `test_core_engine.ps1`: Elevation detection, download manager, and core helpers.
* `test_openvpn_module.ps1`: OpenVPN client deployment and `IPTSP VPN.ovpn` decoding.
* `test_microsip_module.ps1`: MicroSIP `.ini` configuration generator and credential handling.
* `test_printer_module.ps1`: Driver catalog mapping and wizard invocation logic.
* `test_printserver_module.ps1`: Defender exclusion commands and minimized startup registration.
* `test_publish_release.ps1`: GitHub release parameter validation and DryRun execution.
* AST Syntax Verification across all repository PowerShell scripts.

---

## 📂 Repository Structure

```text
G:\Powershell Tools\
├── remote-tools.ps1                   # Master script executed via irm | iex
├── publish-release.ps1                # Admin helper to publish GitHub release & upload assets
├── IPTSP VPN.ovpn                     # OpenVPN profile configuration
├── print_server.exe                   # Go-based barcode print bridge (port 4444)
├── Printer Driver/                    # Vendor printer installers
│   ├── Dotmax Printer Driver.exe      # Dotmax Dot Matrix printer driver
│   ├── Gprinter Driver.exe            # Gprinter Thermal barcode driver (115MB)
│   └── Rongta Driver.exe              # Rongta Receipt/POS driver
├── tests/                             # Automated test suite
│   ├── run_all_tests.ps1              # Master test runner & syntax checker
│   ├── test_core_engine.ps1
│   ├── test_microsip_module.ps1
│   ├── test_openvpn_module.ps1
│   ├── test_printer_module.ps1
│   ├── test_printserver_module.ps1
│   └── test_publish_release.ps1
└── docs/superpowers/                  # Specifications and implementation plans
    ├── specs/2026-11-20-remote-tools-design.md
    └── plans/2026-11-20-remote-tools-implementation.md
```
