# Remote User PowerShell Tools Suite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a robust, interactive, single-command PowerShell onboarding tool (`remote-tools.ps1`) for remote users to install OpenVPN, configure VOIP (MicroSIP), install printer drivers, and configure a minimized background print server bridge.

**Architecture:** Monolithic PowerShell script hosted via GitHub Raw / URL shortener, loaded via `irm <url> | iex`. Self-elevates to Administrator, presents an ANSI color menu, downloads heavy binaries from GitHub Releases to temp/target directories on demand, and configures Windows settings (Defender exclusions, MicroSIP.ini, Startup shortcuts).

**Tech Stack:** PowerShell 5.1 / PowerShell 7+ on Windows, Windows Defender API (`Add-MpPreference`), Windows Shell COM (`WScript.Shell`), OpenVPN Community Client MSI, MicroSIP, Go-based `print_server.exe`, Vendor Printer Drivers.

**Spec:** `docs/superpowers/specs/2026-11-20-remote-tools-design.md`

## Global Constraints
- Must be executable directly via `irm <URL> | iex` in a fresh Windows PowerShell prompt.
- Must self-elevate to Administrator without crashing or losing session context.
- Large executables (>100MB like `Gprinter Driver.exe`) must not be committed to Git history; must be managed via GitHub Releases.
- Defender exclusions must be specifically targeted to `C:\PrintServer` and `print_server.exe`.
- Profile `IPTSP VPN.ovpn` must be safely deployable offline/embedded or via web.

## Review Focus
1. User runs in non-elevated PowerShell: must trigger UAC and continue with menu cleanly.
2. Network interrupted during 115MB driver download: must catch error, show retry message, not leave corrupted partial executable.
3. MicroSIP running while writing `MicroSIP.ini`: must terminate or reload MicroSIP gracefully to prevent file lock.
4. Microsoft Defender actively blocking `print_server.exe`: exclusion must execute before writing or launching the binary.
5. Print server launching on reboot: must run strictly minimized without flashing a persistent black terminal window.

---

### Task 1: Repository Scaffolding & Git Configuration
**Files:**
- Create: `.gitignore`
- Create: `src/config/embed_ovpn.ps1`
- Test: Verify `.gitignore` ignores `*.exe` and that git tracks scripts and docs.

**Interfaces:**
- Produces: Clean git repo avoiding the >100MB GitHub commit rejection.

- [ ] **Step 1: Write `.gitignore` to protect git repository from >100MB files**
- [ ] **Step 2: Commit initial documentation and scaffolding**
- [ ] **Step 3: Run git status to verify large `.exe` files are excluded from commit history**

---

### Task 2: Core Engine & Self-Elevation (`remote-tools.ps1`)
**Files:**
- Create: `remote-tools.ps1`
- Test: `tests/test_core_engine.ps1`

**Interfaces:**
- Produces: `Test-IsAdmin`, `Invoke-SelfElevation`, `Show-MainMenu`, `Invoke-DownloadWithProgress`.

- [ ] **Step 1: Write unit tests for admin detection and download validation**
- [ ] **Step 2: Implement core elevation check and ANSI banner in `remote-tools.ps1`**
- [ ] **Step 3: Implement `Invoke-DownloadWithProgress` with TLS 1.2/1.3 and retry logic**
- [ ] **Step 4: Verify core functions pass tests**

---

### Task 3: OpenVPN Client & IPTSP Profile Setup
**Files:**
- Modify: `remote-tools.ps1`
- Test: `tests/test_openvpn_module.ps1`

**Interfaces:**
- Consumes: `Invoke-DownloadWithProgress`
- Produces: `Install-OpenVPNModule`

- [ ] **Step 1: Write tests for OpenVPN config folder location and `.ovpn` deployment**
- [ ] **Step 2: Embed `IPTSP VPN.ovpn` fallback in `remote-tools.ps1`**
- [ ] **Step 3: Implement silent OpenVPN MSI installation and config deployment**
- [ ] **Step 4: Verify OpenVPN deployment tests pass**

---

### Task 4: VOIP (MicroSIP) Setup & Automation
**Files:**
- Modify: `remote-tools.ps1`
- Test: `tests/test_microsip_module.ps1`

**Interfaces:**
- Produces: `Install-VoipModule`, `Set-MicroSipConfig`

- [ ] **Step 1: Write test for generating valid `MicroSIP.ini` configuration**
- [ ] **Step 2: Implement MicroSIP installation check and silent installer downloader**
- [ ] **Step 3: Implement interactive credential prompts and `MicroSIP.ini` writer with default SIP server `182.163.126.253`**
- [ ] **Step 4: Run MicroSIP tests and verify `.ini` syntax matches MicroSIP schema**

---

### Task 5: Printer Driver Submenu & Wizard Launcher
**Files:**
- Modify: `remote-tools.ps1`
- Test: `tests/test_printer_module.ps1`

**Interfaces:**
- Consumes: `Invoke-DownloadWithProgress`
- Produces: `Show-PrinterDriverMenu`, `Install-PrinterDriver`

- [ ] **Step 1: Write test for driver submenu selection and path mapping**
- [ ] **Step 2: Implement submenu for Gprinter, Rongta, and Dotmax drivers**
- [ ] **Step 3: Implement driver download and GUI wizard execution (`Start-Process -Wait`)**
- [ ] **Step 4: Verify printer driver module tests pass**

---

### Task 6: Print Server Configuration & Minimized Startup
**Files:**
- Modify: `remote-tools.ps1`
- Test: `tests/test_printserver_module.ps1`

**Interfaces:**
- Produces: `Install-PrintServerModule`, `Add-DefenderExclusion`, `Register-MinimizedStartup`

- [ ] **Step 1: Write test for Defender exclusion and startup shortcut creation**
- [ ] **Step 2: Implement `Add-MpPreference` exclusion for `C:\PrintServer` and `print_server.exe`**
- [ ] **Step 3: Implement copying `print_server.exe` to `C:\PrintServer` and Desktop shortcut**
- [ ] **Step 4: Implement minimized startup launcher (VBScript wrapper to prevent black cmd window on boot)**
- [ ] **Step 5: Implement immediate service launch and verify port 4444 listener**

---

### Task 7: Release Automation Helper (`publish-release.ps1`)
**Files:**
- Create: `publish-release.ps1`
- Test: `tests/test_publish_release.ps1`

**Interfaces:**
- Produces: Automated GitHub release creation and asset uploader for `.exe` files.

- [ ] **Step 1: Implement `publish-release.ps1` using GitHub CLI `gh` or GitHub REST API**
- [ ] **Step 2: Add validation for binary existence before attempting release upload**
- [ ] **Step 3: Test release script parameter validation**

---

### Task 8: End-to-End Verification & Comprehensive Test Suite
**Files:**
- Create: `tests/run_all_tests.ps1`

- [ ] **Step 1: Execute all unit and integration test suites**
- [ ] **Step 2: Verify PowerShell AST syntax parsing on `remote-tools.ps1` and all scripts**
- [ ] **Step 3: Verify clean exit and error trapping**

---

### Task 9: Documentation & Quick-Start Guides
**Files:**
- Create: `README.md`

- [ ] **Step 1: Write comprehensive `README.md` with:
      - Quick copy-paste command for remote users
      - TinyURL creation walkthrough
      - Admin deployment and GitHub Release setup instructions
      - Troubleshooting and manual overrides**
- [ ] **Step 2: Review all files and verify full deliverables**
