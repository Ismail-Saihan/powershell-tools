<#
.SYNOPSIS
    Automated GitHub Release Publisher & Asset Uploader
.DESCRIPTION
    Packages and uploads large installer binaries (print_server.exe, printer drivers, OpenVPN profile)
    as GitHub Release assets. This bypasses the GitHub 100MB git commit limit while providing
    high-speed HTTPS downloads for remote users running remote-tools.ps1.
.EXAMPLE
    .\publish-release.ps1 -GitHubUser "yourusername" -GitHubRepo "Powershell-Tools" -Tag "v1.0.0"
#>

param(
    [string]$GitHubUser,
    [string]$GitHubRepo,
    [string]$Tag = "v1.0.0",
    [string]$Title = "Remote User Tools v1.0.0",
    [string]$Token,
    [switch]$DryRun,
    [switch]$UpdateScriptConfig
)

$ErrorActionPreference = "Stop"

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "        GITHUB RELEASE PUBLISHER & ASSET UPLOADER                 " -ForegroundColor White
Write-Host "==================================================================" -ForegroundColor Cyan

# Detect GitHub credentials from remote git if not provided
if (-not $GitHubUser -or -not $GitHubRepo) {
    try {
        $remoteUrl = git config --get remote.origin.url
        if ($remoteUrl -match "github\.com[:/]([^/]+)/([^/\.]+)") {
            if (-not $GitHubUser) { $GitHubUser = $matches[1] }
            if (-not $GitHubRepo) { $GitHubRepo = $matches[2] }
            Write-Host "  -> Detected GitHub repository from git remote: $GitHubUser/$GitHubRepo" -ForegroundColor Green
        }
    } catch {
        # git remote not configured
    }
}

if (-not $GitHubUser) { $GitHubUser = "YourUsername" }
if (-not $GitHubRepo) { $GitHubRepo = "Powershell-Tools" }

Write-Host " Target Repository : $GitHubUser/$GitHubRepo" -ForegroundColor Gray
Write-Host " Release Tag       : $Tag" -ForegroundColor Gray
Write-Host " Release Title     : $Title" -ForegroundColor Gray
if ($DryRun) {
    Write-Host " Execution Mode    : [DryRun Mode Active]" -ForegroundColor Yellow
}
Write-Host "==================================================================" -ForegroundColor Cyan

# Define Assets Inventory
$rootDir = $PSScriptRoot
$requiredAssets = @(
    (Join-Path $rootDir "print_server.exe"),
    (Join-Path $rootDir "Printer Driver\Dotmax Printer Driver.exe"),
    (Join-Path $rootDir "Printer Driver\Gprinter Driver.exe"),
    (Join-Path $rootDir "Printer Driver\Rongta Driver.exe"),
    (Join-Path $rootDir "IPTSP VPN.ovpn")
)

Write-Host "`nScanning Asset Inventory..." -ForegroundColor Cyan
$assetsToUpload = @()
foreach ($assetPath in $requiredAssets) {
    if (Test-Path $assetPath) {
        $item = Get-Item $assetPath
        $sizeMb = [math]::Round($item.Length / 1MB, 2)
        Write-Host "  [FOUND] $($item.Name) ($sizeMb MB)" -ForegroundColor Green
        $assetsToUpload += $assetPath
    } else {
        Write-Warning "Missing asset file: $assetPath"
    }
}

if ($assetsToUpload.Count -eq 0) {
    throw "No assets found to upload. Please ensure files exist in workspace."
}

# Update remote-tools.ps1 config if requested or if valid user/repo provided
$remoteToolsScript = Join-Path $rootDir "remote-tools.ps1"
if ($UpdateScriptConfig -and (Test-Path $remoteToolsScript)) {
    Write-Host "`nUpdating remote-tools.ps1 with target repository configuration..." -ForegroundColor Cyan
    $scriptContent = Get-Content $remoteToolsScript -Raw
    $scriptContent = $scriptContent -replace 'GitHubUser\s*=\s*"[^"]+"', "GitHubUser        = `"$GitHubUser`""
    $scriptContent = $scriptContent -replace 'GitHubRepo\s*=\s*"[^"]+"', "GitHubRepo        = `"$GitHubRepo`""
    $scriptContent = $scriptContent -replace 'ReleaseTag\s*=\s*"[^"]+"', "ReleaseTag        = `"$Tag`""
    [System.IO.File]::WriteAllText($remoteToolsScript, $scriptContent, [System.Text.Encoding]::UTF8)
    Write-Host "  [OK] remote-tools.ps1 configuration updated!" -ForegroundColor Green
}

if ($DryRun) {
    Write-Host "`n[DryRun Mode Active] Skipping actual GitHub API release creation." -ForegroundColor Yellow
    Write-Host "Summary of assets that would be published:" -ForegroundColor White
    foreach ($a in $assetsToUpload) {
        Write-Host "  - $(Split-Path $a -Leaf)" -ForegroundColor DarkGray
    }
    return
}

# Check for GitHub CLI 'gh'
$ghAvailable = $false
try {
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        $ghAvailable = $true
    }
} catch {}

if ($ghAvailable) {
    Write-Host "`nGitHub CLI (gh) detected! Creating release and uploading assets..." -ForegroundColor Cyan
    $quotedAssets = $assetsToUpload | ForEach-Object { "`"$_`"" }
    $cmd = "gh release create $Tag $quotedAssets --title `"$Title`" --notes `"Automated release of remote tools and installer binaries.`" --repo `"$GitHubUser/$GitHubRepo`""
    Write-Host "  Running: $cmd" -ForegroundColor DarkGray
    Invoke-Expression $cmd
    Write-Host "`n[SUCCESS] Release $Tag published successfully via GitHub CLI!" -ForegroundColor Green
} else {
    Write-Host "`n[INFO] GitHub CLI (gh) not detected." -ForegroundColor Yellow
    Write-Host "To publish this release to GitHub manually or using a token:" -ForegroundColor White
    Write-Host "  1. Install GitHub CLI: winget install GitHub.cli" -ForegroundColor DarkGray
    Write-Host "  2. Or create the release in browser at: https://github.com/$GitHubUser/$GitHubRepo/releases/new" -ForegroundColor DarkGray
    Write-Host "  3. Drag and drop the following files into the release:" -ForegroundColor DarkGray
    foreach ($a in $assetsToUpload) {
        Write-Host "     - $(Split-Path $a -Leaf)" -ForegroundColor White
    }
}

# Display remote user command
$rawUrl = "https://raw.githubusercontent.com/$GitHubUser/$GitHubRepo/main/remote-tools.ps1"
Write-Host "`n==================================================================" -ForegroundColor Cyan
Write-Host " REMOTE USER ONE-LINER COMMAND:" -ForegroundColor Yellow
Write-Host " irm $rawUrl | iex" -ForegroundColor White
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "TIP: Shorten this link on https://tinyurl.com (e.g. https://tinyurl.com/your-tools)" -ForegroundColor DarkGray
