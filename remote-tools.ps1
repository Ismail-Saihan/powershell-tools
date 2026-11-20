<#
.SYNOPSIS
    Remote User Onboarding & Support Tools Suite
.DESCRIPTION
    An interactive menu-driven PowerShell tool for remote users to set up
    OpenVPN, VOIP (MicroSIP), Printer Drivers, and Barcode Print Server.
.EXAMPLE
    irm https://raw.githubusercontent.com/YourUsername/Powershell-Tools/main/remote-tools.ps1 | iex
#>

param(
    [switch]$TestMode,
    [string]$Action
)

# Enforce TLS 1.2 / TLS 1.3 for secure web downloads
try {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    if ([enum]::GetNames([System.Net.SecurityProtocolType]) -contains 'Tls13') {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls13
    }
} catch {
    # Fallback to default security protocol if TLS 1.3 is unsupported by runtime
}

# Global Configuration
$global:RemoteToolsConfig = @{
    ToolName          = "Remote User Support Tools"
    Version           = "1.0.0"
    GitHubUser        = "YourUsername"
    GitHubRepo        = "Powershell-Tools"
    ReleaseTag        = "v1.0.0"
    DefaultSipServer  = "182.163.126.253"
    DefaultSipPort    = 5060
    PrintServerDir    = "C:\PrintServer"
    PrintServerPort   = 4444
    TempDir           = (Join-Path $env:TEMP "RemoteTools")
}

# -------------------------------------------------------------------------
# Core Helper Functions
# -------------------------------------------------------------------------

function Test-IsAdmin {
    <#
    .SYNOPSIS
        Checks if the current PowerShell process has administrative rights.
    #>
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-SelfElevation {
    <#
    .SYNOPSIS
        Re-launches the current script as Administrator via UAC.
    #>
    Write-Host "`n[!] Administrator privileges required. Requesting elevation via UAC..." -ForegroundColor Yellow
    
    $powershellExe = (Get-Process -Id $PID).Path
    $scriptContent = $MyInvocation.MyCommand.Definition

    if ($scriptContent -and (Test-Path $scriptContent)) {
        # Script was executed from a saved file
        Start-Process -FilePath $powershellExe -Verb RunAs -ArgumentList "-NoExit -ExecutionPolicy Bypass -File `"$scriptContent`""
    } else {
        # Script was executed in-memory via irm | iex
        $downloadUrl = "https://raw.githubusercontent.com/$($global:RemoteToolsConfig.GitHubUser)/$($global:RemoteToolsConfig.GitHubRepo)/main/remote-tools.ps1"
        $command = "irm $downloadUrl | iex"
        Start-Process -FilePath $powershellExe -Verb RunAs -ArgumentList "-NoExit -ExecutionPolicy Bypass -Command `"$command`""
    }
    Exit
}

function Get-ReleaseAssetUrl {
    param([string]$Filename)
    return "https://github.com/$($global:RemoteToolsConfig.GitHubUser)/$($global:RemoteToolsConfig.GitHubRepo)/releases/download/$($global:RemoteToolsConfig.ReleaseTag)/$Filename"
}

function Invoke-DownloadWithProgress {
    param(
        [Parameter(Mandatory=$true)][string]$Url,
        [Parameter(Mandatory=$true)][string]$DestinationPath,
        [string]$Description = "File"
    )

    $parentDir = Split-Path -Parent $DestinationPath
    if (-not (Test-Path $parentDir)) {
        $null = New-Item -ItemType Directory -Path $parentDir -Force
    }

    # If already downloaded and valid, return
    if ((Test-Path $DestinationPath) -and ((Get-Item $DestinationPath).Length -gt 0)) {
        Write-Host "  -> Cached file found: $(Split-Path $DestinationPath -Leaf)" -ForegroundColor Green
        return $true
    }

    $tempDest = "$DestinationPath.download"
    if (Test-Path $tempDest) { Remove-Item $tempDest -Force }

    Write-Host "  -> Downloading $Description from:" -ForegroundColor Cyan
    Write-Host "     $Url" -ForegroundColor DarkGray

    try {
        $webClient = New-Object System.Net.WebClient
        # Attach event for download progress
        $webClient.Headers.Add("User-Agent", "RemoteTools-PowerShell/1.0")
        $webClient.DownloadFile($Url, $tempDest)
        $webClient.Dispose()

        Move-Item -Path $tempDest -Destination $DestinationPath -Force
        Write-Host "  [OK] Download completed successfully: $(Split-Path $DestinationPath -Leaf)" -ForegroundColor Green
        return $true
    } catch {
        if (Test-Path $tempDest) { Remove-Item $tempDest -Force }
        Write-Warning "Failed to download $Description. Error: $($_.Exception.Message)"
        return $false
    }
}

function Show-Header {
    Clear-Host
    $isAdmin = Test-IsAdmin
    $adminStatus = if ($isAdmin) { "Administrator (Elevated)" } else { "Standard User (Not Elevated)" }
    $adminColor = if ($isAdmin) { "Green" } else { "Yellow" }

    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host "       REMOTE USER ONBOARDING & SUPPORT TOOLS SUITE               " -ForegroundColor White
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host " Computer Name : $env:COMPUTERNAME" -ForegroundColor Gray
    Write-Host " Current User  : $env:USERDOMAIN\$env:USERNAME" -ForegroundColor Gray
    Write-WritePrompt " Privileges    : " $adminStatus $adminColor
    Write-Host " Version       : $($global:RemoteToolsConfig.Version)" -ForegroundColor Gray
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-WritePrompt {
    param($Label, $Value, $Color)
    Write-Host $Label -NoNewline -ForegroundColor Gray
    Write-Host $Value -ForegroundColor $Color
}

function Show-MainMenu {
    Show-Header
    Write-Host "Select an option from the menu below:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] Setup OpenVPN (Install client + import IPTSP profile)" -ForegroundColor White
    Write-Host "  [2] Setup VOIP (MicroSIP auto-install + configure credentials)" -ForegroundColor White
    Write-Host "  [3] Install Printer Driver (Gprinter, Rongta, Dotmax)" -ForegroundColor White
    Write-Host "  [4] Install Print Server (Defender exclusion + minimized startup)" -ForegroundColor White
    Write-Host "  [5] Exit" -ForegroundColor Red
    Write-Host ""
}

# -------------------------------------------------------------------------
# Main Execution Entry Point
# -------------------------------------------------------------------------
if (-not $TestMode) {
    if (-not (Test-IsAdmin)) {
        Invoke-SelfElevation
    }

    do {
        Show-MainMenu
        $choice = Read-Host "Enter option number [1-5]"
        switch ($choice) {
            "1" { Write-Host "`nFeature 1 selected" -ForegroundColor Cyan; Start-Sleep -Seconds 1 }
            "2" { Write-Host "`nFeature 2 selected" -ForegroundColor Cyan; Start-Sleep -Seconds 1 }
            "3" { Write-Host "`nFeature 3 selected" -ForegroundColor Cyan; Start-Sleep -Seconds 1 }
            "4" { Write-Host "`nFeature 4 selected" -ForegroundColor Cyan; Start-Sleep -Seconds 1 }
            "5" { Write-Host "`nExiting Remote Tools. Goodbye!" -ForegroundColor Green; break }
            default { Write-Host "Invalid option. Please choose between 1 and 5." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    } while ($choice -ne "5")
}
