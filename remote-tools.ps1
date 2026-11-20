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
    GitHubUser        = "Ismail-Saihan"
    GitHubRepo        = "powershell-tools"
    ReleaseTag        = "v1.0.0"
    DefaultSipServer  = "182.163.126.250"
    DefaultSipPort    = 5060
    PrintServerDir    = "C:\PrintServer"
    PrintServerPort   = 4444
    TempDir           = (Join-Path $env:TEMP "RemoteTools")
    OpenVpnMsiUrl     = "https://swupdate.openvpn.net/community/releases/OpenVPN-2.6.12-I001-amd64.msi"
    OpenVpnBackupUrl  = "https://build.openvpn.net/downloads/releases/OpenVPN-2.6.12-I001-amd64.msi"
    MicroSipUrl       = "https://www.microsip.org/download/MicroSIP-3.21.3.exe"
}

# Printer Drivers Definition Catalog
$global:PrinterDrivers = @{
    "1" = @{ Name = "Gprinter Driver"; Filename = "Gprinter Driver.exe"; Description = "Gprinter Thermal/Barcode Printer Driver" }
    "2" = @{ Name = "Rongta Driver"; Filename = "Rongta Driver.exe"; Description = "Rongta Receipt/Label Printer Driver" }
    "3" = @{ Name = "Dotmax Driver"; Filename = "Dotmax Printer Driver.exe"; Description = "Dotmax Dot Matrix/POS Printer Driver" }
}

# Embedded Base64 for IPTSP VPN Profile (offline/portable fallback)
$global:EmbeddedIptspOvpn = "ZGV2IHR1bgpwZXJzaXN0LXR1bgpwZXJzaXN0LWtleQpkYXRhLWNpcGhlcnMgQUVTLTI1Ni1HQ006QUVTLTEyOC1HQ006Q0hBQ0hBMjAtUE9MWTEzMDU6QUVTLTI1Ni1DQkMKZGF0YS1jaXBoZXJzLWZhbGxiYWNrIEFFUy0yNTYtQ0JDCmF1dGggU0hBMjU2CnRscy1jbGllbnQKY2xpZW50CnJlc29sdi1yZXRyeSBpbmZpbml0ZQpyZW1vdGUgMTgyLjE2My4xMjYuMjUzIDExOTQgdWRwNApub2JpbmQKdmVyaWZ5LXg1MDktbmFtZSAiQ2FycnkgQmVlIiBuYW1lCmF1dGgtdXNlci1wYXNzCnJlbW90ZS1jZXJ0LXRscyBzZXJ2ZXIKZXhwbGljaXQtZXhpdC1ub3RpZnkKCjxjYT4KLS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUVLVENDQXhHZ0F3SUJBZ0lJQlJnVGIrWTFDdzB3RFFZSktvWklodmNOQVFFTEJRQXdaekVVTUJJR0ExVUUKQXhNTGFXNTBaWEp1WVd3dFkyRXhDekFKQmdOVkJBWVRBa0pFTVE0d0RBWURWUVFJRXdWRWFHRnJZVEVRTUE0RwpBMVVFQnhNSFVtOWhaQzB5TWpFU01CQUdBMVVFQ2hNSlEyRnljbmtnUW1WbE1Rd3dDZ1lEVlFRTEV3TXhNREF3CkhoY05NalV4TURJNU1EWXpNekExV2hjTk16VXhNREkzTURZek16QTFXakJuTVJRd0VnWURWUVFERXd0cGJuUmwKY201aGJDMWpZVEVMTUFrR0ExVUVCaE1DUWtReERqQU1CZ05WQkFnVEJVUm9ZV3RoTVJBd0RnWURWUVFIRXdkUwpiMkZrTFRJeU1SSXdFQVlEVlFRS0V3bERZWEp5ZVNCQ1pXVXhEREFLQmdOVkJBc1RBekV3TURDQ0FTSXdEUVlKCktvWklodmNOQVFFQkJRQURnZ0VQQURDQ0FRb0NnZ0VCQUtjTVJQMk1LbU51QkZDN0pZN2N5VmloMHpSd010aTQKMkJOMW11aDNmOG1UdWk1Wm54ZlBwc0FCNDIrSW1KN3g4emQ4elB0bkJHOHhyUWtKdk1oZjBjQ3R2MzVJRVNkSwp2R0ljcGpla3Vray9TRjk0dE5JUEZBSWg3SHZ3QWpVOHZGajFGTWlDeHpQdUp6NlVXY0l0eE1qN3lQYW9wbVduCkQxZUNYRGFGVUh6dVdmVzBBck9Ic0dGZjJPR1RKVVpKbkhMUWFWcENUVU5YL1l3UkJsY0RpMmxEOXRrelg1ZHgKTStjdzNnZ3ozTUZ4OUU4SEV2SzFDQVN4eXRZeDZhYnFraTF0QzR3cjVZSzJPU0pZSWVGMllHRTVDRDdvczlzNQpyQUllRHIzNUdYN3djRWVNZVpsUGxJaTNsWnZxZDlwamR3cFFIQnl3K1FNbnZ0OTdKNnF6NEVjQ0F3RUFBYU9CCjJEQ0IxVEFkQmdOVkhRNEVGZ1FVK1VqSkJjUWxMWitOY21tS0pJYlFWNDRsZExRd2daZ0dBMVVkSXdTQmtEQ0IKallBVStVakpCY1FsTForTmNtbUtKSWJRVjQ0bGRMU2hhNlJwTUdjeEZEQVNCZ05WQkFNVEMybHVkR1Z5Ym1GcwpMV05oTVFzd0NRWURWUVFHRXdKQ1JERU9NQXdHQTFVRUNCTUZSR2hoYTJFeEVEQU9CZ05WQkFjVEIxSnZZV1F0Ck1qSXhFakFRQmdOVkJBb1RDVU5oY25KNUlFSmxaVEVNTUFvR0ExVUVDeE1ETVRBd2dnZ0ZHQk52NWpVTERUQU0KQmdOVkhSTUVCVEFEQVFIL01Bc0dBMVVkRHdRRUF3SUJCakFOQmdrcWhraUc5dzBCQVFzRkFBT0NBUUVBWTZLZwpMeUhuRFNwYTZFaHgvWjRYMzU4YUpnUnM0S29HSm5zd0trekxBbE52ZHRyREVVL1k1dWs1Ukt3V0FJdjNaK2MrCnpZNFFpVzZxek5Hbm9BMmFESkRSTkxWWFJuN1dsZW1ZNW8wdjJNRzdIU0E0UXNNK0l5QlNOdUFJcUMvbUVDNVQKTi9MbHhNNWkrMVlXdlVMQXYwQUdkT3dhMi9XUUVpb0RNTTlxY0Vpcm9lWGNmbE9ZK3NVY3ZMalBtMnNWYmlzbwo0Mkx5a2E0c1oyeDZndWVSKzV1TnVSN3VOS0NIRWFXcTVRaERtNDB1YVBYOVRDZHlUS2JBUVkwa2tncjI2ZlhjClNxQkhkR1dHN3YzVmlTK0FCWWJ5NkE5MUtKRnpCZ1l5MCs1KzlybjQyV2dLQnRGZ1J2U2Z6QkZsellYaHRqaEYKeEZIQldEODZ3enZLQW9NOERBPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo8L2NhPgo8Y2VydD4KLS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUVlekNDQTJPZ0F3SUJBZ0lCQWpBTkJna3Foa2lHOXcwQkFRc0ZBREJuTVJRd0VnWURWUVFERXd0cGJuUmwKY201aGJDMWpZVEVMTUFrR0ExVUVCaE1DUWtReERqQU1CZ05WQkFnVEJVUm9ZV3RoTVJBd0RnWURWUVFIRXdkUwpiMkZrTFRJeU1SSXdFQVlEVlFRS0V3bERZWEp5ZVNCQ1pXVXhEREFLQmdOVkJBc1RBekV3TURBZUZ3MHlOVEV3Ck1qa3dOalEyTlRWYUZ3MHpOVEV3TWpjd05qUTJOVFZhTUdReEN6QUpCZ05WQkFZVEFrSkVNUTR3REFZRFZRUUkKRXdWRWFHRnJZVEVRTUE0R0ExVUVCeE1IVW05aFpDMHlNakVTTUJBR0ExVUVDaE1KUTJGeWNua2dRbVZsTVF3dwpDZ1lEVlFRTEV3TXhNREF4RVRBUEJnTlZCQU1UQ0dOaGNuSjVZbVZsTUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGCkFBT0NBUThBTUlJQkNnS0NBUUVBNEIzbEtLd0h1UUF4OHNCd3hqbDFSZE54VGhDZTJaUjlyQUo2RXRuVGZwV2YKRzN0S2tUVFM0aW9sakZOQ0RlZ2xlbEtkcmJMcVJHcks2WDhJa0JNRThEWlFlMkVzMFBGU2hsa05CTVAxZ0dtbApKZGlUSFpqL2VmWVd5NXhUNXRVSkg3azFCK3B6Q0JtYmU1V3RpQjQ5VjRUc3VDVjdDL2RzaTNIZHladW1EMmtZCjV3Sm9vZXpVL09SMEJpU0pDZytFMUhKWFJPRFk1dXZPeGJNSUNPVU1VSFJUTTJYSHM1eFFaYnRkNTMwRUl0cTMKZHRqUTBqQklhUnJnQ1pRQU5IMTU4bm1kdkhoejVXRnltVDFlL0xwU0JzYTVJM0ZETFV3emMzWkE1S3NrSFZVNwp5Y1VNK0RUdjF3VGFETlpFY0xwVkxOMWNGcU52UEdCUTdKcTUwNDZmblFJREFRQUJvNElCTXpDQ0FTOHdDUVlEClZSMFRCQUl3QURBTEJnTlZIUThFQkFNQ0JlQXdNUVlKWUlaSUFZYjRRZ0VOQkNRV0lrOXdaVzVUVTB3Z1IyVnUKWlhKaGRHVmtJRlZ6WlhJZ1EyVnlkR2xtYVdOaGRHVXdIUVlEVlIwT0JCWUVGR1huTG5keWxpbHAyS1ZSaEFYbAorTlZXdXoyOE1JR1lCZ05WSFNNRWdaQXdnWTJBRlBsSXlRWEVKUzJmalhKcGlpU0cwRmVPSlhTMG9XdWthVEJuCk1SUXdFZ1lEVlFRREV3dHBiblJsY201aGJDMWpZVEVMTUFrR0ExVUVCaE1DUWtReERqQU1CZ05WQkFnVEJVUm8KWVd0aE1SQXdEZ1lEVlFRSEV3ZFNiMkZrTFRJeU1SSXdFQVlEVlFRS0V3bERZWEp5ZVNCQ1pXVXhEREFLQmdOVgpCQXNUQXpFd01JSUlCUmdUYitZMUN3MHdFd1lEVlIwbEJBd3dDZ1lJS3dZQkJRVUhBd0l3RXdZRFZSMFJCQXd3CkNvSUlZMkZ5Y25saVpXVXdEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBRnB6eitLWE1jT2FBY2llVEpHOEd2RkMKNVNOMXc4YVl5cUJrOTV3N1BFdWNjeGM0QVMyL0d6elZKOWZEellYMFhkR2xoSVpHTVYvVExkbE5vV2xtSTMvMwpvWVhpRXVHV3dRS2JNcXhxZzgxRmVlcnNidFVndjNmK1B5MzE4RE9pZWF5T3NNd1JzZ0Y0eXlXeitZU1pWNTRuCmg3dlVqVVNVZXNNUnBRMm1qczNLaEt1Yi80SGxCZzFkMldHdHZSK1hlSkNPbENBZ0hPcGg2amJGaVM5SXVkMWcKWWRMVEprVFFCR29uWkNobzFYU2h1YnNHTVFYYStvenNoeG91KzF0T0Rqb0RUdWFtWHZ1NW5DMFZGbnhrRm9McQpnR3ZUbGMvZ1M3MUQ0L3pTQWxFUmE5TWdYQmRhK2xrMHFTSnhKRTR0SjlyNXM1ZDR5aFI2RldtMzM5Q05UWjA9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0KPC9jZXJ0Pgo8a2V5PgotLS0tLUJFR0lOIFBSSVZBVEUgS0VZLS0tLS0KTUlJRXZRSUJBREFOQmdrcWhraUc5dzBCQVFFRkFBU0NCS2N3Z2dTakFnRUFBb0lCQVFEZ0hlVW9yQWU1QURIeQp3SERHT1hWRjAzRk9FSjdabEgyc0Fub1MyZE4rbFo4YmUwcVJOTkxpS2lXTVUwSU42Q1Y2VXAydHN1cEVhc3JwCmZ3aVFFd1R3TmxCN1lTelE4VktHV1EwRXcvV0FhYVVsMkpNZG1QOTU5aGJMbkZQbTFRa2Z1VFVINm5NSUdadDcKbGEySUhqMVhoT3k0SlhzTDkyeUxjZDNKbTZZUGFSam5BbWloN05UODVIUUdKSWtLRDRUVWNsZEU0TmptNjg3Rgpzd2dJNVF4UWRGTXpaY2V6bkZCbHUxM25mUVFpMnJkMjJORFNNRWhwR3VBSmxBQTBmWG55ZVoyOGVIUGxZWEtaClBWNzh1bElHeHJramNVTXRURE56ZGtEa3F5UWRWVHZKeFF6NE5PL1hCTm9NMWtSd3VsVXMzVndXbzI4OFlGRHMKbXJuVGpwK2RBZ01CQUFFQ2dnRUFLVVAzNU5SQUc4VTRiUzBYMXJmUHF3cXlxeUFPVDV1eXhCQTByL0hocWtZYwpaSy8vMjlxeEZhbVMvbEo2TUJ0Vmd6OWcveEdaWnYyTzNRMWg0ejFOUkhtTHVodjdaNEYzbzNzVUZaT0xTWmlxCkt0ekV3Y2RoQ3ZEUDQ2K21Gek9VbVgyOWtQYVBOYWVaWkZqNytic3Zxa1MwWFhleFAxUFFiYUNLcU10NitRMFYKbktKak1zSGN4b2hOVW42a3lXaG03ajBZK2JCcXpaRjJUb3pMbnhTV0tacUVTY29nOThrSXB0d1laQnBxWWJlYgpqbFRobE9hNWlKWHRHRVNDUVFQaXlXaEp6RkNjTkpZZkJnUUNtQmNnQjJ0N29hcGhScCsrWE1pay9uS3lnVzVmCnhuNFloTnVsb0M2VjR3WmRmNk5qNHFiZGRKT3hRZmVuOE9vZS9ONVZOUUtCZ1FENVE2UW4xV3E3aHpnaC80WmQKQmJZWktlOEVVWVdkMzVFZGVORi92QkNtZEdzdnVlaGJHRXdQWURRN2N5d0h1QkRIaHNZcDRmcmZhTXArNi9XZApsMEEzdy9NRXRJbVV2aFRJRk5uaGR3a2tEK0hlb2wwcFhzbEVaMHNXUDE4NVZFZkJpeWNPS3RDMkdMWkxOTXRXClRoS2lDY2JBZ0FQMFFoMUJGd0wzN3hhKy93S0JnUURtTEVuL0YrSW1MaUtJWjJhZ0dvNnBxZUE5bk9zcHdwZFoKUExFZHpkVTl4OU1ndGN1RmVPeVR3d3U0NS9aNUdCMVpMNlVEOHZCWXM1ekg2ejNqakJMUHpsdHJ6eXl6dVBRMQpVcjYrYXB0TjhlWEpNSkZhenhybGNuemtHcTlmbk8yaExUNnlwRkRqZDFGQU5XZHY3WTU4UU5ZOVVqNklLTVJPCkM2V2lUY0E5WXdLQmdGVnJ1OGEyMlhQWWZBRVNxejRYcGZicnF2Qms2NUJWdkVwSVRDc2xET091UThsQVFZTnUKU1NwL3dvYVpDbjYrc21sZUkyelk5M3MyVXlhNXdCczRhUlp6UFVYZ2hNR0hmbUd1MjVmcmppTmdtZndNMGpaSwpPRmtMdU95djNQY3RqY1dpNVVoeW5jRzVxRWNQbVp0QytCbTFsZm9FSk5iQkRYdHY0bUdLK3RXTEFvR0JBT1U2CmJtY3liZk1BTnp3SlhsZE1tNCswc3JJcHVMbmFKY2lsZk83bHN0ellTUmRtZGMzelpBaTBVdFJQajFPQ0JKaHgKcnJHRUhJRDZQOFdLTGhTVHg1aFZOdzdqUU8ycjRPbktBbFM0N3ZwdFVoOVAwekxRMTBSekJKWlhUUmkzdktDcgo0cWtlbzhBbGNERzEvZEdta0NTR25kWnNOZ0o4TnlSU3pSNGF1TDFwQW9HQU5DUFo1SGxJM0JIRjhoNFdPMjFpClVQck1IMFhTVEdYY0tHVkVBWFhKeUQ1Tk9adlNMWHJXWEtBV0ZWMHQ3K0tGamRRNVp2blFralNPeGFzM0c2UU0KRElkeXhiTmRzVXZlNWIxa1JZU0JJYis3dlc5dDJnNFd0YnNDV01sbHM4TEdmREl1WGJKZVV5T0RKRVVscDBWRApUK0NNaGlqR3d0S0ZsRnRtQS9kUlFXQT0KLS0tLS1FTkQgUFJJVkFURSBLRVktLS0tLQo8L2tleT4Ka2V5LWRpcmVjdGlvbiAxCjx0bHMtYXV0aD4KIwojIDIwNDggYml0IE9wZW5WUE4gc3RhdGljIGtleQojCi0tLS0tQkVHSU4gT3BlblZQTiBTdGF0aWMga2V5IFYxLS0tLS0KMDkzOWI1ZjNlYjY3YjY3YTljZjgxYjUyMWIyMWMxNTYKNGIzZTg5MTk3MWNiYTkyYTFkMzUzZjRiYjYyNDJmNTAKODUzYjljNGUxMGY5M2UyYTViYzAwZDUyOThmZmY0ZTEKOWU2M2MzOTg4Y2U1MWJkMTEwZmMzM2IxNTMyOWU3YTkKZDZiOGU4NDNkOWVmMDEzOWI2ZGUzODgxYzFlMThjNDMKOTYxZmU1YjQ2ZGVlMmZjY2Y3ZDM5OWU3MDljNTk5MzMKNDY2NjEyZTdlZGJlNWFmMjkyYzUwMzFjMDA3ZDA4NGEKZTQ0MTExZGViMTc3ZGNhZDdjZGZjMDFmOGI5Zjc5NGQKZTU4NDZiNTUyNWJiMWE2MDEwYWFlYWU4Nzk1M2I1ODAKMmQyYTQwODRlMmU5Y2E0NDYzYTU1YjExNjJkZGJhMWMKMDQ0NmJjZjVlMTM5YWEzMGFlOTA3MDhhNDJiYzJkOWQKOTI1MDRmMDFmYzNhMjJkZjdhYzUyNTI4Yjc2ZDMwZWMKYjE2NGVhM2I4ZGI0ODlhNTM4YzgxODgzNmFiYTY3MzMKOTk0ZTEzYzA0MjNkNTFhMjYzZDViOTFlMmYxZTdkY2IKNzIwNWUxZDBlOWFiZDlkZjI2ZjVkNjY4NDIyMjAyNTUKMTkxODE4NGU3YzA4Yzg2NWZhNThjZjU2Y2U1OGY4YjAKLS0tLS1FTkQgT3BlblZQTiBTdGF0aWMga2V5IFYxLS0tLS0KPC90bHMtYXV0aD4K"


# -------------------------------------------------------------------------
# Core Helper Functions
# -------------------------------------------------------------------------

function Wait-UserPrompt {
    <#
    .SYNOPSIS
        Universal prompt helper replacing legacy Console ReadLine (HOST-01).
        Gracefully handles non-interactive hosts, redirected streams, and PowerShell ISE.
    #>
    param([string]$Message = "Press Enter to return...")
    Write-Host "`n$Message" -ForegroundColor Yellow
    try {
        $null = Read-Host
    } catch {
        Start-Sleep -Seconds 2
    }
}

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
        Re-launches the current script as Administrator via UAC (EL-01).
        Correctly detects the script path from disk or falls back to Web-download.
    #>
    Write-Host "`n[!] Administrator privileges required. Requesting elevation via UAC..." -ForegroundColor Yellow
    
    $powershellExe = (Get-Process -Id $PID).Path
    $scriptPath = $PSCommandPath
    if (-not $scriptPath -and $MyInvocation.ScriptName) { $scriptPath = $MyInvocation.ScriptName }
    
    if ($scriptPath -and (Test-Path $scriptPath)) {
        # Script was executed from a saved file
        Start-Process -FilePath $powershellExe -Verb RunAs -ArgumentList "-NoExit -ExecutionPolicy Bypass -File `"$scriptPath`""
        Exit
    } else {
        # Script was executed in-memory via irm | iex
        $downloadUrl = "https://raw.githubusercontent.com/$($global:RemoteToolsConfig.GitHubUser)/$($global:RemoteToolsConfig.GitHubRepo)/main/remote-tools.ps1"
        $command = "irm $downloadUrl | iex"
        Start-Process -FilePath $powershellExe -Verb RunAs -ArgumentList "-NoExit -ExecutionPolicy Bypass -Command `"$command`""
        Exit
    }
}

function Get-ReleaseAssetUrl {
    param([string]$Filename)
    # GitHub release assets replace spaces with dots
    $sanitized = $Filename -replace ' ', '.'
    return "https://github.com/$($global:RemoteToolsConfig.GitHubUser)/$($global:RemoteToolsConfig.GitHubRepo)/releases/download/$($global:RemoteToolsConfig.ReleaseTag)/$sanitized"
}

function Get-LocalAssetPath {
    <#
    .SYNOPSIS
        Safely resolves a local asset path when running from disk or returns $null when running in-memory via irm | iex.
    #>
    param(
        [Parameter(Mandatory=$true)][string]$RelativePath
    )
    if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        $candidate = Join-Path $PSScriptRoot $RelativePath
        if (Test-Path $candidate) {
            return $candidate
        }
    }
    $cwd = Get-Location
    if ($cwd) {
        $cwdCandidate = Join-Path $cwd $RelativePath
        if (Test-Path $cwdCandidate) {
            return $cwdCandidate
        }
    }
    return $null
}

function Invoke-DownloadWithProgress {
    <#
    .SYNOPSIS
        Resilient web file downloader supporting multi-mirror fallbacks, exponential backoff,
        and system proxy authentication (NET-01, NET-02, NET-03).
    #>
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [Alias("Url")]
        [string[]]$Urls,
        [Parameter(Mandatory=$true, Position=1)]
        [string]$DestinationPath,
        [string]$Description = "File",
        [int]$MaxRetries = 3
    )

    $parentDir = Split-Path -Parent $DestinationPath
    if (-not (Test-Path $parentDir)) {
        $null = New-Item -ItemType Directory -Path $parentDir -Force
    }

    # If already downloaded and valid, return cached file
    if ((Test-Path $DestinationPath) -and ((Get-Item $DestinationPath).Length -gt 0)) {
        Write-Host "  -> Cached file found: $(Split-Path $DestinationPath -Leaf)" -ForegroundColor Green
        return $true
    }

    foreach ($currentUrl in $Urls) {
        if ([string]::IsNullOrWhiteSpace($currentUrl)) { continue }
        Write-Host "  -> Attempting download of $Description from:" -ForegroundColor Cyan
        Write-Host "     $currentUrl" -ForegroundColor DarkGray

        for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
            $tempDest = "$DestinationPath.download"
            if (Test-Path $tempDest) { Remove-Item $tempDest -Force }

            try {
                $webClient = New-Object System.Net.WebClient
                $webClient.Headers.Add("User-Agent", "RemoteTools-PowerShell/1.0")
                
                # System proxy and credential cache integration (NET-03)
                $webClient.Proxy = [System.Net.WebRequest]::GetSystemWebProxy()
                $webClient.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials

                $webClient.DownloadFile($currentUrl, $tempDest)
                $webClient.Dispose()

                if ((Test-Path $tempDest) -and ((Get-Item $tempDest).Length -gt 0)) {
                    Move-Item -Path $tempDest -Destination $DestinationPath -Force
                    Write-Host "  [OK] Download completed successfully: $(Split-Path $DestinationPath -Leaf)" -ForegroundColor Green
                    return $true
                } else {
                    throw "Downloaded file was 0 bytes."
                }
            } catch {
                if (Test-Path $tempDest) { Remove-Item $tempDest -Force }
                Write-Warning "Attempt $attempt of $MaxRetries failed for ${currentUrl}: $($_.Exception.Message)"
                if ($attempt -lt $MaxRetries) {
                    $backoffSeconds = $attempt * 2
                    Write-Host "     Retrying in $backoffSeconds seconds..." -ForegroundColor DarkGray
                    Start-Sleep -Seconds $backoffSeconds
                }
            }
        }
        Write-Warning "All $MaxRetries attempts failed for mirror: $currentUrl"
    }

    Write-Error "Failed to download $Description from all configured mirrors."
    return $false
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

function Test-NetworkPort {
    <#
    .SYNOPSIS
        Tests TCP socket connectivity without handle leaks (SYS-01).
        TcpClient and WaitHandle are guaranteed closed in a finally block.
    #>
    param(
        [Parameter(Mandatory=$true)][string]$TargetHost,
        [Parameter(Mandatory=$true)][int]$Port,
        [int]$TimeoutSeconds = 2,
        [switch]$Quiet
    )
    if (-not $Quiet) {
        Write-Host "  -> Testing connection to $TargetHost`:$Port..." -ForegroundColor Cyan
    }
    
    $tcpClient = $null
    $asyncResult = $null
    $waitHandle = $null

    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $asyncResult = $tcpClient.BeginConnect($TargetHost, $Port, $null, $null)
        $waitHandle = $asyncResult.AsyncWaitHandle
        $waitSuccess = $waitHandle.WaitOne($TimeoutSeconds * 1000, $false)

        if ($waitSuccess -and $tcpClient.Connected) {
            $tcpClient.EndConnect($asyncResult)
            if (-not $Quiet) {
                Write-Host "  [OK] Connection SUCCESSFUL to $TargetHost`:$Port (Port OPEN)" -ForegroundColor Green
            }
            return $true
        } else {
            if (-not $Quiet) {
                Write-Host "  [FAIL] Connection TIMED OUT to $TargetHost`:$Port" -ForegroundColor Red
            }
            return $false
        }
    } catch {
        if (-not $Quiet) {
            Write-Host "  [FAIL] Could not reach $TargetHost`:$Port ($($_.Exception.Message))" -ForegroundColor Red
        }
        return $false
    } finally {
        if ($waitHandle) {
            try { $waitHandle.Close() } catch { }
        }
        if ($tcpClient) {
            try { $tcpClient.Close() } catch { }
        }
    }
}

function Test-PortAvailability {
    <#
    .SYNOPSIS
        Checks if a local TCP port is free or bound, reporting owning process information (PROC-01).
    #>
    param(
        [Parameter(Mandatory=$true)][int]$Port,
        [switch]$ReportProcess
    )
    $owningProcessId = $null
    $processName = $null

    try {
        if (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue) {
            $conn = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($conn) {
                $owningProcessId = $conn.OwningProcess
            }
        }
    } catch { }

    if (-not $owningProcessId) {
        try {
            $netstatOut = netstat -ano | Select-String ":$Port\s"
            if ($netstatOut) {
                $line = ($netstatOut | Select-Object -First 1).ToString().Trim()
                $tokens = $line -split '\s+'
                $pidCandidate = $tokens[-1]
                if ($pidCandidate -match '^\d+$') {
                    $owningProcessId = [int]$pidCandidate
                }
            }
        } catch { }
    }

    if ($owningProcessId -and $owningProcessId -gt 0) {
        try {
            $p = Get-Process -Id $owningProcessId -ErrorAction SilentlyContinue
            if ($p) {
                $processName = $p.ProcessName
            }
        } catch { }

        if ($ReportProcess) {
            $procDesc = if ($processName) { "$processName (PID: $owningProcessId)" } else { "PID: $owningProcessId" }
            Write-Host "  [WARN] Port $Port is currently OCCUPIED by $procDesc" -ForegroundColor Yellow
        }
        return @{
            Available       = $false
            Port            = $Port
            OwningProcessId = $owningProcessId
            ProcessName     = $processName
        }
    } else {
        return @{
            Available       = $true
            Port            = $Port
            OwningProcessId = $null
            ProcessName     = $null
        }
    }
}

function Stop-PrintServerGracefully {
    <#
    .SYNOPSIS
        Gracefully requests print_server to exit, force terminates if needed,
        and waits until file locks are completely released (PS-01).
    #>
    [CmdletBinding()]
    param(
        [int]$TimeoutSeconds = 5
    )

    $procs = Get-Process -Name "print_server" -ErrorAction SilentlyContinue
    if (-not $procs) {
        return $true
    }

    Write-Host "  -> Terminating running print_server process(es) to release file locks..." -ForegroundColor Yellow
    foreach ($proc in $procs) {
        try {
            $null = $proc.CloseMainWindow()
        } catch { }
    }

    $waited = 0
    while ($waited -lt $TimeoutSeconds) {
        $remaining = Get-Process -Name "print_server" -ErrorAction SilentlyContinue
        if (-not $remaining) {
            Write-Host "  [OK] print_server process exited gracefully." -ForegroundColor Green
            Start-Sleep -Milliseconds 500
            return $true
        }
        Start-Sleep -Seconds 1
        $waited++
    }

    # Force kill if still running after timeout
    $forceProcs = Get-Process -Name "print_server" -ErrorAction SilentlyContinue
    if ($forceProcs) {
        Write-Host "  -> Force terminating print_server process(es)..." -ForegroundColor Yellow
        $forceProcs | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }

    $finalCheck = Get-Process -Name "print_server" -ErrorAction SilentlyContinue
    if (-not $finalCheck) {
        Write-Host "  [OK] print_server terminated and file lock released." -ForegroundColor Green
        return $true
    } else {
        Write-Warning "Could not terminate print_server process (PID(s): $($finalCheck.Id -join ', '))."
        return $false
    }
}

# -------------------------------------------------------------------------
# OpenVPN Module
# -------------------------------------------------------------------------

function Get-OpenVpnGuiPath {
    <#
    .SYNOPSIS
        Detects OpenVPN GUI across 64-bit and 32-bit Program Files directories (ENV-03).
    #>
    $candidates = @(
        "C:\Program Files\OpenVPN\bin\openvpn-gui.exe",
        "C:\Program Files (x86)\OpenVPN\bin\openvpn-gui.exe"
    )
    if ($env:ProgramFiles) { $candidates += (Join-Path $env:ProgramFiles "OpenVPN\bin\openvpn-gui.exe") }
    if (${env:ProgramFiles(x86)}) { $candidates += (Join-Path ${env:ProgramFiles(x86)} "OpenVPN\bin\openvpn-gui.exe") }

    foreach ($path in ($candidates | Select-Object -Unique)) {
        if ($path -and (Test-Path $path)) {
            return $path
        }
    }
    return $null
}

function Deploy-OpenVpnConfig {
    param(
        [Parameter(Mandatory=$true)][string]$TargetDirectory
    )
    if (-not (Test-Path $TargetDirectory)) {
        $null = New-Item -ItemType Directory -Path $TargetDirectory -Force
    }

    $destPath = Join-Path $TargetDirectory "IPTSP VPN.ovpn"
    
    # If local file exists, use it; otherwise use embedded fallback
    $localFile = Get-LocalAssetPath -RelativePath "IPTSP VPN.ovpn"
    if ($localFile) {
        Copy-Item -Path $localFile -Destination $destPath -Force
    } else {
        $bytes = [System.Convert]::FromBase64String($global:EmbeddedIptspOvpn)
        [System.IO.File]::WriteAllBytes($destPath, $bytes)
    }
    Write-Host "  [OK] OpenVPN profile deployed: $destPath" -ForegroundColor Green
    return $destPath
}

function Install-OpenVPNModule {
    Write-Host "`n=== [1] OpenVPN Setup & Profile Deployment ===" -ForegroundColor Cyan

    $openVpnGuiPath = Get-OpenVpnGuiPath

    if (-not $openVpnGuiPath) {
        Write-Host "  -> OpenVPN Client is not installed. Preparing installation..." -ForegroundColor Yellow
        $msiDest = Join-Path $global:RemoteToolsConfig.TempDir "OpenVPN-Client.msi"
        
        # Download with mirror fallback (NET-01, NET-02)
        $openVpnMirrors = @(
            $global:RemoteToolsConfig.OpenVpnMsiUrl,
            $global:RemoteToolsConfig.OpenVpnBackupUrl,
            (Get-ReleaseAssetUrl -Filename "OpenVPN-2.6.12-I001-amd64.msi")
        )
        $downloadSuccess = Invoke-DownloadWithProgress -Urls $openVpnMirrors -DestinationPath $msiDest -Description "OpenVPN Community Client MSI"
        if (-not $downloadSuccess) {
            Write-Error "Failed to download OpenVPN installer. Please check your internet connection."
            return $false
        }

        Write-Host "  -> Installing OpenVPN Client silently..." -ForegroundColor Cyan
        $proc = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$msiDest`" /qn /norestart" -Wait -PassThru
        if ($proc.ExitCode -ne 0 -and $proc.ExitCode -ne 3010) {
            Write-Warning "OpenVPN installer exited with code $($proc.ExitCode)."
        } else {
            Write-Host "  [OK] OpenVPN Client installed successfully!" -ForegroundColor Green
        }
        $openVpnGuiPath = Get-OpenVpnGuiPath
        if (-not $openVpnGuiPath) {
            $openVpnGuiPath = "C:\Program Files\OpenVPN\bin\openvpn-gui.exe"
        }
    } else {
        Write-Host "  [OK] OpenVPN Client is already installed at: $openVpnGuiPath" -ForegroundColor Green
    }

    # Ensure OpenVPN Interactive Service is Automatic and Running for non-admin users (ENV-03)
    try {
        $vpnService = Get-Service -Name "OpenVPNServiceInteractive" -ErrorAction SilentlyContinue
        if ($vpnService) {
            Write-Host "  -> Configuring OpenVPN Interactive Service..." -ForegroundColor Cyan
            if ($vpnService.StartType -ne 'Automatic') {
                Set-Service -Name "OpenVPNServiceInteractive" -StartupType Automatic -ErrorAction SilentlyContinue
                Write-Host "  [OK] Set OpenVPNServiceInteractive startup type to Automatic." -ForegroundColor Green
            }
            if ($vpnService.Status -ne 'Running') {
                Start-Service -Name "OpenVPNServiceInteractive" -ErrorAction SilentlyContinue
                Write-Host "  [OK] Started OpenVPNServiceInteractive service." -ForegroundColor Green
            } else {
                Write-Host "  [OK] OpenVPNServiceInteractive service is already running." -ForegroundColor Green
            }
        } else {
            Write-Host "  [INFO] OpenVPNServiceInteractive service not registered on this system." -ForegroundColor DarkGray
        }
    } catch {
        Write-Warning "Could not configure OpenVPNServiceInteractive service: $($_.Exception.Message)"
    }

    # Deploy configuration profile to user directory and 64-bit/32-bit program files (ENV-03)
    $userConfigDir = Join-Path $env:USERPROFILE "OpenVPN\config"
    $null = Deploy-OpenVpnConfig -TargetDirectory $userConfigDir

    $sysConfigDirs = @(
        "C:\Program Files\OpenVPN\config",
        "C:\Program Files (x86)\OpenVPN\config"
    )
    foreach ($scd in $sysConfigDirs) {
        $parent = Split-Path -Parent $scd
        if (Test-Path $parent) {
            $null = Deploy-OpenVpnConfig -TargetDirectory $scd
        }
    }

    # Ensure multi-user Public Desktop shortcut (ENV-01)
    try {
        $desktopPath = [Environment]::GetFolderPath("CommonDesktopDirectory")
        if (-not $desktopPath -or -not (Test-Path $desktopPath)) {
            $desktopPath = [Environment]::GetFolderPath("Desktop")
        }
        $shortcutPath = Join-Path $desktopPath "OpenVPN GUI.lnk"
        if ((Test-Path $openVpnGuiPath) -and (-not (Test-Path $shortcutPath))) {
            $wshShell = New-Object -ComObject WScript.Shell
            $shortcut = $wshShell.CreateShortcut($shortcutPath)
            $shortcut.TargetPath = $openVpnGuiPath
            $shortcut.WorkingDirectory = Split-Path -Parent $openVpnGuiPath
            $shortcut.Description = "OpenVPN GUI Client"
            $shortcut.Save()
            Write-Host "  [OK] OpenVPN Public Desktop shortcut created: $shortcutPath" -ForegroundColor Green
        }
    } catch {
        Write-Warning "Could not create desktop shortcut: $($_.Exception.Message)"
    }

    Write-Host "`n[SUCCESS] OpenVPN Setup Completed! You can now launch OpenVPN GUI and connect to 'IPTSP VPN'." -ForegroundColor Green
    return $true
}

function Show-OpenVpnMenu {
    do {
        Show-Header
        Write-Host "--- [1] OpenVPN Client & Profile Management ---" -ForegroundColor Cyan
        Write-Host "Select an option from below:`n" -ForegroundColor Yellow
        Write-Host "  [1] Full Setup (Install Client + Import IPTSP Profile + Desktop Shortcut)" -ForegroundColor White
        Write-Host "  [2] Deploy / Update IPTSP VPN Profile Only" -ForegroundColor White
        Write-Host "  [3] Launch OpenVPN GUI" -ForegroundColor White
        Write-Host "  [4] Test VPN Gateway Connectivity (182.163.126.253)" -ForegroundColor White
        Write-Host "  [5] Return to Main Menu" -ForegroundColor Red
        Write-Host ""

        $vpnChoice = Read-Host "Enter option [1-5]"
        switch ($vpnChoice) {
            "1" {
                $null = Install-OpenVPNModule
                Wait-UserPrompt "Press Enter to return to OpenVPN menu..."
            }
            "2" {
                Write-Host "`nDeploying IPTSP VPN Profile..." -ForegroundColor Cyan
                $userDir = Join-Path $env:USERPROFILE "OpenVPN\config"
                $null = Deploy-OpenVpnConfig -TargetDirectory $userDir
                $sysDirs = @("C:\Program Files\OpenVPN\config", "C:\Program Files (x86)\OpenVPN\config")
                foreach ($sd in $sysDirs) {
                    if (Test-Path (Split-Path -Parent $sd)) {
                        $null = Deploy-OpenVpnConfig -TargetDirectory $sd
                    }
                }
                Write-Host "`n[OK] IPTSP Profile deployed!" -ForegroundColor Green
                Wait-UserPrompt "Press Enter to return to OpenVPN menu..."
            }
            "3" {
                $guiPath = Get-OpenVpnGuiPath
                if ($guiPath -and (Test-Path $guiPath)) {
                    Start-Process -FilePath $guiPath
                    Write-Host "`n[OK] OpenVPN GUI launched!" -ForegroundColor Green
                } else {
                    Write-Warning "OpenVPN GUI is not installed. Please choose Option 1 to install it."
                }
                Start-Sleep -Seconds 2
            }
            "4" {
                Write-Host "`nTesting connectivity to VPN Gateway..." -ForegroundColor Cyan
                $gw = "182.163.126.253"
                $ping = Test-Connection -ComputerName $gw -Count 2 -Quiet -ErrorAction SilentlyContinue
                if ($ping) {
                    Write-Host "  [OK] ICMP Ping to $gw SUCCESSFUL!" -ForegroundColor Green
                } else {
                    Write-Warning "ICMP Ping to $gw did not respond (may be firewalled)."
                }
                $null = Test-NetworkPort -TargetHost $gw -Port 1194 -TimeoutSeconds 3
                Wait-UserPrompt "Press Enter to return to OpenVPN menu..."
            }
            "5" { break }
            default {
                Write-Host "Invalid option. Please choose between 1 and 5." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } while ($vpnChoice -ne "5")
}

# -------------------------------------------------------------------------
# MicroSIP VOIP Module
# -------------------------------------------------------------------------

function Get-MicroSipExePath {
    <#
    .SYNOPSIS
        Detects MicroSIP softphone across 64-bit, 32-bit, and user-local paths (ENV-03).
    #>
    $possiblePaths = @(
        "C:\Program Files\MicroSIP\microsip.exe",
        "C:\Program Files (x86)\MicroSIP\microsip.exe",
        (Join-Path $env:LOCALAPPDATA "MicroSIP\microsip.exe")
    )
    if ($env:ProgramFiles) { $possiblePaths += (Join-Path $env:ProgramFiles "MicroSIP\microsip.exe") }
    if (${env:ProgramFiles(x86)}) { $possiblePaths += (Join-Path ${env:ProgramFiles(x86)} "MicroSIP\microsip.exe") }

    foreach ($path in ($possiblePaths | Select-Object -Unique)) {
        if ($path -and (Test-Path $path)) {
            return $path
        }
    }
    return $null
}

function Get-DerivedVoipProfile {
    <#
    .SYNOPSIS
        Intelligently derives all VOIP account fields from minimal inputs:
        Extension, Full Name, Location, Password, and SIP Server.
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Extension,
        [Parameter(Mandatory=$true)][string]$FullName,
        [string]$Location = "IT",
        [string]$Password = "",
        [string]$SipServer = "182.163.126.250",
        [int]$SipPort = 5060
    )

    $Extension = if ($Extension) { $Extension.Trim() } else { "" }
    $FullName = if ($FullName) { $FullName.Trim() } else { "" }
    $Location = if ($Location) { $Location.Trim() } else { "" }
    $Password = if ($Password) { $Password.Trim() } else { "" }
    $SipServer = if ($SipServer) { $SipServer.Trim() } else { "182.163.126.250" }

    # If Location was not provided or empty, check if FullName has [Location] tag embedded
    # e.g. "Ismail Hossain Saihan[IT]" -> clean name: "Ismail Hossain Saihan", location: "IT"
    if ($FullName -match '^(.*?)\s*\[([^\]]+)\]\s*$') {
        $cleanFullName = $matches[1].Trim()
        if ([string]::IsNullOrWhiteSpace($Location)) {
            $Location = $matches[2].Trim()
        }
    } else {
        $cleanFullName = $FullName
    }

    # Fallback location to "IT" if still empty
    if ([string]::IsNullOrWhiteSpace($Location)) {
        $Location = "IT"
    }

    # Extract First Name for Caller ID / Display Name
    # Skip honorifics/prefixes like "Md.", "Dr.", "Mr.", "Mrs.", "Ms."
    $words = $cleanFullName -split '\s+'
    $firstName = ""
    foreach ($w in $words) {
        $trimmedWord = $w.Trim().TrimEnd('.')
        if ($trimmedWord -notmatch '^(Md|Mohammad|Muhammed|Dr|Prof|Mr|Mrs|Ms)$' -and $trimmedWord.Length -gt 0) {
            $firstName = $trimmedWord
            break
        }
    }
    if ([string]::IsNullOrWhiteSpace($firstName) -and $words.Count -gt 0) {
        $firstName = $words[0].Trim()
    }
    if ([string]::IsNullOrWhiteSpace($firstName)) {
        $firstName = $Extension
    }

    $accountName = "$Extension- $cleanFullName[$Location]"
    $displayName = "$firstName-$Location"
    $serverWithPort = if ($SipPort -and $SipPort -ne 0) { "$SipServer`:$SipPort" } else { $SipServer }

    return [PSCustomObject]@{
        Extension   = $Extension
        FullName    = $cleanFullName
        Location    = $Location
        Password    = $Password
        AccountName = $accountName
        DisplayName = $displayName
        Server      = $serverWithPort
        Proxy       = $serverWithPort
        Domain      = $SipServer
        Port        = $SipPort
    }
}

function Set-MicroSipConfig {
    <#
    .SYNOPSIS
        Preserves existing INI sections (audio devices, volume, contacts) and merges [Account1] (VOIP-01).
        Writes output in UTF-8 without BOM to prevent Win32 parsing corruption (VOIP-02).
        Trims credential inputs to eliminate whitespace issues (VOIP-03).
    #>
    param(
        [Parameter(Mandatory=$true)][string]$IniPath,
        [Parameter(Mandatory=$true)][string]$Extension,
        [Parameter(Mandatory=$true)][string]$Password,
        [string]$FullName = "",
        [string]$Location = "",
        [string]$DisplayName = "",
        [string]$AccountName = "",
        [string]$Username = "",
        [string]$SipServer = "182.163.126.250",
        [int]$SipPort = 5060
    )

    $parentDir = Split-Path -Parent $IniPath
    if (-not (Test-Path $parentDir)) {
        $null = New-Item -ItemType Directory -Path $parentDir -Force
    }

    # Trim inputs (VOIP-03)
    $Extension = if ($Extension) { $Extension.Trim() } else { "" }
    $Password = if ($Password) { $Password.Trim() } else { "" }
    $effectiveFullName = if ($FullName) { $FullName.Trim() } elseif ($Username) { $Username.Trim() } else { "" }
    $Location = if ($Location) { $Location.Trim() } else { "" }
    $SipServer = if ($SipServer) { $SipServer.Trim() } else { "182.163.126.250" }

    # Derive smart defaults
    $derived = Get-DerivedVoipProfile -Extension $Extension `
                                      -FullName $effectiveFullName `
                                      -Location $Location `
                                      -Password $Password `
                                      -SipServer $SipServer `
                                      -SipPort $SipPort

    # Allow explicit overrides if specified, otherwise use derived
    $finalAccountName = if (-not [string]::IsNullOrWhiteSpace($AccountName)) { $AccountName.Trim() } else { $derived.AccountName }
    $finalDisplayName = if (-not [string]::IsNullOrWhiteSpace($DisplayName)) { $DisplayName.Trim() } else { $derived.DisplayName }
    $finalServer      = $derived.Server
    $finalProxy       = $derived.Proxy
    $finalDomain      = $derived.Domain

    # Parse existing INI if it exists to preserve existing sections (VOIP-01)
    $sections = [ordered]@{}
    $currentSection = ""
    $sections[$currentSection] = [System.Collections.Generic.List[string]]::new()

    if (Test-Path $IniPath) {
        $existingContent = [System.IO.File]::ReadAllText($IniPath)
        $lines = $existingContent -split '\r?\n'
        foreach ($line in $lines) {
            $trimmed = $line.Trim()
            if ($trimmed -match '^\[(.*)\]$') {
                $currentSection = $matches[1].Trim()
                if (-not $sections.Contains($currentSection)) {
                    $sections[$currentSection] = [System.Collections.Generic.List[string]]::new()
                }
            } else {
                $sections[$currentSection].Add($line)
            }
        }
    }

    # Helper to set or update a key in a section list
    function Set-IniSettingItem {
        param($List, [string]$Key, [string]$Value)
        $found = $false
        for ($i = 0; $i -lt $List.Count; $i++) {
            if ($List[$i] -match "^\s*$Key\s*=") {
                $List[$i] = "$Key=$Value"
                $found = $true
                break
            }
        }
        if (-not $found) {
            $List.Add("$Key=$Value")
        }
    }

    # Ensure [Settings] exists with baseline values
    if (-not $sections.Contains("Settings")) {
        $sections["Settings"] = [System.Collections.Generic.List[string]]::new()
        $sections["Settings"].Add("audioCodecs=PCMU/8000/1,PCMA/8000/1,G729/8000/1,opus/48000/2")
    }

    # Ensure dedicated recordings directory exists in Documents
    $recordingsDir = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "MicroSIP\Recordings"
    try {
        if (-not (Test-Path $recordingsDir)) {
            $null = New-Item -ItemType Directory -Path $recordingsDir -Force -ErrorAction SilentlyContinue
        }
    } catch {}

    $settingsRef = $sections["Settings"]
    # Ensure Account 1 is the active selected account
    Set-IniSettingItem -List $settingsRef -Key "accountId" -Value "1"
    Set-IniSettingItem -List $settingsRef -Key "autoStart" -Value "1"
    Set-IniSettingItem -List $settingsRef -Key "startMinimized" -Value "0"
    Set-IniSettingItem -List $settingsRef -Key "singleMode" -Value "1"
    Set-IniSettingItem -List $settingsRef -Key "denyIncoming" -Value "0"

    # User Requirement: Turn on call recording
    Set-IniSettingItem -List $settingsRef -Key "autoRecording" -Value "1"
    Set-IniSettingItem -List $settingsRef -Key "recordingButton" -Value "1"
    Set-IniSettingItem -List $settingsRef -Key "recordingFormat" -Value "mp3"
    Set-IniSettingItem -List $settingsRef -Key "recordingPath" -Value $recordingsDir

    # User Requirement: Disable automatic updates
    Set-IniSettingItem -List $settingsRef -Key "updatesInterval" -Value "never"
    Set-IniSettingItem -List $settingsRef -Key "checkUpdatesTime" -Value "0"

    # Build updated [Account1] settings matching the MicroSIP Account configuration dialog
    $accList = [System.Collections.Generic.List[string]]::new()
    $accList.Add("label=$finalAccountName")
    $accList.Add("server=$finalServer")
    $accList.Add("proxy=$finalProxy")
    $accList.Add("user=$Extension")
    $accList.Add("username=$Extension")
    $accList.Add("domain=$finalDomain")
    $accList.Add("authID=$Extension")
    $accList.Add("password=$Password")
    $accList.Add("displayName=$finalDisplayName")
    $accList.Add("name=$finalDisplayName")
    $accList.Add("transport=0")
    $accList.Add("srtp=0")
    $accList.Add("publish=1")
    $accList.Add("register=1")
    $accList.Add("regInterval=300")
    $accList.Add("keepAlive=15")
    $sections["Account1"] = $accList

    # Reconstruct INI file preserving sections
    $sb = [System.Text.StringBuilder]::new()
    foreach ($secKey in $sections.Keys) {
        if ($secKey -ne "") {
            $null = $sb.AppendLine("[$secKey]")
        }
        foreach ($line in $sections[$secKey]) {
            if ($line -ne "") {
                $null = $sb.AppendLine($line)
            }
        }
        $null = $sb.AppendLine()
    }

    # Write INI with UTF-8 without BOM (VOIP-02)
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($IniPath, $sb.ToString().TrimEnd() + "`r`n", $utf8NoBom)
    Write-Host "  [OK] MicroSIP profile configuration saved to: $IniPath" -ForegroundColor Green
    return $true
}

function Install-VoipModule {
    Write-Host "`n=== [2] VOIP (MicroSIP) Setup & Configuration ===" -ForegroundColor Cyan

    # Close running instance of MicroSIP to allow updating configuration
    $runningProc = Get-Process microsip -ErrorAction SilentlyContinue
    if ($runningProc) {
        Write-Host "  -> Closing running MicroSIP process to update configuration..." -ForegroundColor Yellow
        $runningProc | Stop-Process -Force
        Start-Sleep -Seconds 1
    }

    # Locate MicroSIP executable
    $microSipExe = Get-MicroSipExePath

    if (-not $microSipExe) {
        Write-Host "  -> MicroSIP is not installed. Preparing automatic installation..." -ForegroundColor Yellow
        $installerDest = Join-Path $global:RemoteToolsConfig.TempDir "MicroSIP-Setup.exe"

        # Multi-mirror fallback download (NET-01, NET-02)
        $microSipMirrors = @(
            $global:RemoteToolsConfig.MicroSipUrl,
            (Get-ReleaseAssetUrl -Filename "MicroSIP-3.21.3.exe")
        )
        $downloadOk = Invoke-DownloadWithProgress -Urls $microSipMirrors -DestinationPath $installerDest -Description "MicroSIP Installer"
        if (-not $downloadOk) {
            Write-Error "Failed to download MicroSIP installer. Please check your internet connection."
            return $false
        }

        Write-Host "  -> Installing MicroSIP silently..." -ForegroundColor Cyan
        $proc = Start-Process -FilePath $installerDest -ArgumentList "/S" -PassThru
        
        # Wait up to 15 seconds for installer file extraction
        $waited = 0
        while (-not $proc.HasExited -and $waited -lt 15) {
            Start-Sleep -Seconds 1
            $waited++
        }

        # MicroSIP installer automatically spawns microsip.exe upon finish.
        # Terminate this background instance so it does not lock MicroSIP.ini or hang PowerShell.
        Start-Sleep -Seconds 2
        Get-Process microsip -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1

        # Re-check paths after install
        $microSipExe = Get-MicroSipExePath
        if ($microSipExe) {
            Write-Host "  [OK] MicroSIP installed successfully!" -ForegroundColor Green
        } else {
            Write-Warning "MicroSIP installer ran, but microsip.exe was not detected in default paths."
            $microSipExe = "C:\Program Files\MicroSIP\microsip.exe"
        }
    } else {
        Write-Host "  [OK] MicroSIP is already installed at: $microSipExe" -ForegroundColor Green
    }

    # Prompt user for credentials with secure password masking (SEC-02, VOIP-03)
    Write-Host "`nPlease enter VOIP credentials:" -ForegroundColor Yellow
    
    $extension = Read-Host "  Enter Extension / User ID (e.g. 1054)"
    $extension = if ($extension) { $extension.Trim() } else { "" }
    while ([string]::IsNullOrWhiteSpace($extension)) {
        Write-Host "  Extension / User ID cannot be empty." -ForegroundColor Red
        $extension = (Read-Host "  Enter Extension / User ID (e.g. 1054)").Trim()
    }

    $fullName = Read-Host "  Enter User Name (e.g. Ismail Hossain Saihan)"
    $fullName = if ($fullName) { $fullName.Trim() } else { "" }
    while ([string]::IsNullOrWhiteSpace($fullName)) {
        Write-Host "  User Name cannot be empty." -ForegroundColor Red
        $fullName = (Read-Host "  Enter User Name (e.g. Ismail Hossain Saihan)").Trim()
    }

    $suggestedLocation = if ($fullName -match '\[(.*?)\]') { $matches[1] } else { "IT" }
    $locInput = Read-Host "  Enter Location / Department [$suggestedLocation]"
    $location = if ([string]::IsNullOrWhiteSpace($locInput)) { $suggestedLocation } else { $locInput.Trim() }

    $password = $null
    while ([string]::IsNullOrWhiteSpace($password)) {
        Write-Host "  Enter SIP Password / Secret: " -NoNewline
        $secPass = Read-Host -AsSecureString
        if ($secPass) {
            $password = [System.Net.NetworkCredential]::new("", $secPass).Password
            if ($password) { $password = $password.Trim() }
        }
        if ([string]::IsNullOrWhiteSpace($password)) {
            Write-Host "  Password cannot be empty." -ForegroundColor Red
        }
    }

    # Derive smart profile
    $derived = Get-DerivedVoipProfile -Extension $extension `
                                      -FullName $fullName `
                                      -Location $location `
                                      -Password $password `
                                      -SipServer $global:RemoteToolsConfig.DefaultSipServer `
                                      -SipPort $global:RemoteToolsConfig.DefaultSipPort

    Write-Host "`n  -> Generated VOIP Configuration Summary:" -ForegroundColor Cyan
    Write-Host "     [+] Extension    : $($derived.Extension)" -ForegroundColor White
    Write-Host "     [+] User Name    : $($derived.FullName)" -ForegroundColor White
    Write-Host "     [+] Location     : $($derived.Location)" -ForegroundColor White
    Write-Host "     [+] Account Name : $($derived.AccountName)" -ForegroundColor Green
    Write-Host "     [+] Display Name : $($derived.DisplayName)" -ForegroundColor Green
    Write-Host "     [+] SIP Server   : $($derived.Server)" -ForegroundColor DarkGray
    Write-Host "     [+] Call Record  : Enabled (Auto MP3)" -ForegroundColor DarkGray
    Write-Host "     [+] Auto Updates : Disabled" -ForegroundColor DarkGray

    # Write MicroSIP configuration
    $appDataIni = Join-Path $env:APPDATA "MicroSIP\MicroSIP.ini"
    Set-MicroSipConfig -IniPath $appDataIni `
                       -Extension $derived.Extension `
                       -FullName $derived.FullName `
                       -Location $derived.Location `
                       -AccountName $derived.AccountName `
                       -DisplayName $derived.DisplayName `
                       -Password $derived.Password `
                       -SipServer $global:RemoteToolsConfig.DefaultSipServer `
                       -SipPort $global:RemoteToolsConfig.DefaultSipPort

    # Ensure Public Desktop shortcut for all remote users (ENV-01)
    try {
        $desktopPath = [Environment]::GetFolderPath("CommonDesktopDirectory")
        if (-not $desktopPath -or -not (Test-Path $desktopPath)) {
            $desktopPath = [Environment]::GetFolderPath("Desktop")
        }
        $shortcutPath = Join-Path $desktopPath "MicroSIP.lnk"
        if ((Test-Path $microSipExe) -and (-not (Test-Path $shortcutPath))) {
            $wshShell = New-Object -ComObject WScript.Shell
            $shortcut = $wshShell.CreateShortcut($shortcutPath)
            $shortcut.TargetPath = $microSipExe
            $shortcut.WorkingDirectory = Split-Path -Parent $microSipExe
            $shortcut.Description = "MicroSIP Softphone"
            $shortcut.Save()
            Write-Host "  [OK] MicroSIP Public Desktop shortcut created: $shortcutPath" -ForegroundColor Green
        }
    } catch {
        Write-Warning "Could not create MicroSIP desktop shortcut: $($_.Exception.Message)"
    }

    # Offer to launch MicroSIP
    $launch = Read-Host "`nWould you like to launch MicroSIP now? (Y/N) [Y]"
    if ([string]::IsNullOrWhiteSpace($launch) -or $launch.ToUpper() -eq "Y") {
        if (Test-Path $microSipExe) {
            Start-Process -FilePath $microSipExe
            Write-Host "  [OK] MicroSIP launched!" -ForegroundColor Green
        }
    }

    Write-Host "`n[SUCCESS] VOIP (MicroSIP) setup completed successfully!" -ForegroundColor Green
    return $true
}

function Show-VoipMenu {
    do {
        Show-Header
        Write-Host "--- [2] VOIP & MicroSIP Management ---" -ForegroundColor Cyan
        Write-Host "Select an option from below:`n" -ForegroundColor Yellow
        Write-Host "  [1] Full Setup (Install MicroSIP + Configure SIP Account)" -ForegroundColor White
        Write-Host "  [2] Update SIP Account & Credentials (Without Re-installing)" -ForegroundColor White
        Write-Host "  [3] Launch MicroSIP Softphone" -ForegroundColor White
        Write-Host "  [4] Test SIP Server Connectivity (182.163.126.250:5060)" -ForegroundColor White
        Write-Host "  [5] Return to Main Menu" -ForegroundColor Red
        Write-Host ""

        $voipChoice = Read-Host "Enter option [1-5]"
        switch ($voipChoice) {
            "1" {
                $null = Install-VoipModule
                Wait-UserPrompt "Press Enter to return to VOIP menu..."
            }
            "2" {
                Write-Host "`nUpdate VOIP Credentials:" -ForegroundColor Yellow
                $extension = Read-Host "  Enter Extension / User ID (e.g. 1054)"
                while ([string]::IsNullOrWhiteSpace($extension)) {
                    Write-Host "  Extension cannot be empty." -ForegroundColor Red
                    $extension = Read-Host "  Enter Extension / User ID"
                }
                $extension = $extension.Trim()

                $fullName = Read-Host "  Enter User Name (e.g. Ismail Hossain Saihan)"
                while ([string]::IsNullOrWhiteSpace($fullName)) {
                    Write-Host "  User Name cannot be empty." -ForegroundColor Red
                    $fullName = Read-Host "  Enter User Name"
                }
                $fullName = $fullName.Trim()

                $suggestedLocation = if ($fullName -match '\[(.*?)\]') { $matches[1] } else { "IT" }
                $locInput = Read-Host "  Enter Location / Department [$suggestedLocation]"
                $location = if ([string]::IsNullOrWhiteSpace($locInput)) { $suggestedLocation } else { $locInput.Trim() }

                $password = $null
                while ([string]::IsNullOrWhiteSpace($password)) {
                    Write-Host "  Enter SIP Password: " -NoNewline
                    $secPass = Read-Host -AsSecureString
                    if ($secPass) {
                        $password = [System.Net.NetworkCredential]::new("", $secPass).Password
                        if ($password) { $password = $password.Trim() }
                    }
                    if ([string]::IsNullOrWhiteSpace($password)) {
                        Write-Host "  Password cannot be empty." -ForegroundColor Red
                    }
                }

                # Derive smart profile
                $derived = Get-DerivedVoipProfile -Extension $extension `
                                                  -FullName $fullName `
                                                  -Location $location `
                                                  -Password $password `
                                                  -SipServer $global:RemoteToolsConfig.DefaultSipServer `
                                                  -SipPort $global:RemoteToolsConfig.DefaultSipPort

                Write-Host "`n  -> Generated VOIP Configuration Summary:" -ForegroundColor Cyan
                Write-Host "     [+] Extension    : $($derived.Extension)" -ForegroundColor White
                Write-Host "     [+] User Name    : $($derived.FullName)" -ForegroundColor White
                Write-Host "     [+] Location     : $($derived.Location)" -ForegroundColor White
                Write-Host "     [+] Account Name : $($derived.AccountName)" -ForegroundColor Green
                Write-Host "     [+] Display Name : $($derived.DisplayName)" -ForegroundColor Green
                Write-Host "     [+] SIP Server   : $($derived.Server)" -ForegroundColor DarkGray
                Write-Host "     [+] Call Record  : Enabled (Auto MP3)" -ForegroundColor DarkGray
                Write-Host "     [+] Auto Updates : Disabled" -ForegroundColor DarkGray

                $appDataIni = Join-Path $env:APPDATA "MicroSIP\MicroSIP.ini"
                $null = Set-MicroSipConfig -IniPath $appDataIni `
                                           -Extension $derived.Extension `
                                           -FullName $derived.FullName `
                                           -Location $derived.Location `
                                           -AccountName $derived.AccountName `
                                           -DisplayName $derived.DisplayName `
                                           -Password $derived.Password `
                                           -SipServer $global:RemoteToolsConfig.DefaultSipServer `
                                           -SipPort $global:RemoteToolsConfig.DefaultSipPort
                Write-Host "`n[OK] SIP configuration updated!" -ForegroundColor Green
                Wait-UserPrompt "Press Enter to return to VOIP menu..."
            }
            "3" {
                $found = Get-MicroSipExePath
                if ($found) {
                    Start-Process -FilePath $found
                    Write-Host "`n[OK] MicroSIP softphone launched!" -ForegroundColor Green
                } else {
                    Write-Warning "MicroSIP is not installed. Choose Option 1 to install it."
                }
                Start-Sleep -Seconds 2
            }
            "4" {
                Write-Host "`nTesting connectivity to SIP Server..." -ForegroundColor Cyan
                $sipHost = $global:RemoteToolsConfig.DefaultSipServer
                $ping = Test-Connection -ComputerName $sipHost -Count 2 -Quiet -ErrorAction SilentlyContinue
                if ($ping) {
                    Write-Host "  [OK] ICMP Ping to $sipHost SUCCESSFUL!" -ForegroundColor Green
                } else {
                    Write-Host "  [INFO] ICMP Ping to $sipHost did not respond (may be filtered)." -ForegroundColor DarkGray
                }
                $null = Test-NetworkPort -TargetHost $sipHost -Port 5060 -TimeoutSeconds 3
                Wait-UserPrompt "Press Enter to return to VOIP menu..."
            }
            "5" { break }
            default {
                Write-Host "Invalid option. Please choose between 1 and 5." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } while ($voipChoice -ne "5")
}

# -------------------------------------------------------------------------
# Printer Driver Installation Module
# -------------------------------------------------------------------------

function Install-PrinterDriver {
    param(
        [Parameter(Mandatory=$true)][hashtable]$DriverInfo
    )
    Write-Host "`n--- Installing $($DriverInfo.Name) ---" -ForegroundColor Cyan
    
    # Check if file is available locally in script directory
    $localPath = Get-LocalAssetPath -RelativePath "Printer Driver\$($DriverInfo.Filename)"
    $targetExe = $null

    if ($localPath) {
        Write-Host "  -> Using local driver installer: $localPath" -ForegroundColor Green
        $targetExe = $localPath
    } else {
        $destPath = Join-Path $global:RemoteToolsConfig.TempDir $DriverInfo.Filename
        $url = Get-ReleaseAssetUrl -Filename $DriverInfo.Filename
        
        $downloadOk = Invoke-DownloadWithProgress -Url $url -DestinationPath $destPath -Description $DriverInfo.Description
        if (-not $downloadOk) {
            Write-Error "Failed to download $($DriverInfo.Name)."
            return $false
        }
        $targetExe = $destPath
    }

    Write-Host "`n  -> Launching vendor setup wizard: $(Split-Path $targetExe -Leaf)" -ForegroundColor Yellow
    Write-Host "     Please complete the setup steps in the wizard window." -ForegroundColor DarkGray
    
    $proc = Start-Process -FilePath $targetExe -Wait -PassThru
    Write-Host "  [OK] Driver wizard completed with exit code: $($proc.ExitCode)" -ForegroundColor Green
    return $true
}

function Show-PrinterDriverMenu {
    do {
        Show-Header
        Write-Host "--- [3] Install Printer Driver ---" -ForegroundColor Cyan
        Write-Host "Select the printer driver to install:`n" -ForegroundColor Yellow
        Write-Host "  [1] Gprinter Driver (Barcode & Label Printer)" -ForegroundColor White
        Write-Host "  [2] Rongta Driver (Receipt & POS Printer)" -ForegroundColor White
        Write-Host "  [3] Dotmax Driver (Dot Matrix & Form Printer)" -ForegroundColor White
        Write-Host "  [4] View Installed Windows Printers" -ForegroundColor White
        Write-Host "  [5] Return to Main Menu" -ForegroundColor Red
        Write-Host ""

        $driverChoice = Read-Host "Enter driver option [1-5]"
        if ($global:PrinterDrivers.ContainsKey($driverChoice)) {
            $null = Install-PrinterDriver -DriverInfo $global:PrinterDrivers[$driverChoice]
            Wait-UserPrompt "Press Enter to return to Printer Drivers menu..."
        } elseif ($driverChoice -eq "4") {
            Write-Host "`nInstalled Printers on this system:" -ForegroundColor Cyan
            try {
                Get-Printer | Select-Object Name, DriverName, PortName, PrinterStatus | Format-Table -AutoSize
            } catch {
                Write-Warning "Could not retrieve printers: $($_.Exception.Message)"
            }
            Wait-UserPrompt "Press Enter to return to Printer Drivers menu..."
        } elseif ($driverChoice -eq "5") {
            break
        } else {
            Write-Host "Invalid option. Please choose between 1 and 5." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    } while ($driverChoice -ne "5")
}

# -------------------------------------------------------------------------
# Barcode Print Server Bridge Module
# -------------------------------------------------------------------------

function Add-PrintServerDefenderExclusions {
    <#
    .SYNOPSIS
        Inspects antivirus environment via WMI/CIM and verifies Defender service status
        before applying exclusions, avoiding false positives (SEC-01).
    #>
    param([string]$ServerDir = "C:\PrintServer")
    Write-Host "  -> Inspecting antivirus environment & configuring exclusions..." -ForegroundColor Cyan

    # Step 1: Detect Antivirus products via WMI/CIM
    $avProducts = @()
    try {
        if (Get-CimSession -ErrorAction SilentlyContinue) {
            $avProducts = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct -ErrorAction SilentlyContinue
        } else {
            $avProducts = Get-WmiObject -Namespace root/SecurityCenter2 -Class AntiVirusProduct -ErrorAction SilentlyContinue
        }
    } catch { }

    $thirdPartyAv = @()
    if ($avProducts) {
        foreach ($av in $avProducts) {
            $name = $av.displayName
            if ($name -match 'Defender') {
                Write-Host "  [DETECTED] Antivirus: $name (Built-in)" -ForegroundColor Cyan
            } else {
                $thirdPartyAv += $name
                Write-Host "  [DETECTED] Third-party Antivirus: $name" -ForegroundColor Yellow
            }
        }
    }

    if ($thirdPartyAv.Count -gt 0) {
        Write-Warning "Active third-party antivirus detected ($($thirdPartyAv -join ', ')).`n     Automated Defender exclusions may not cover third-party scanners.`n     Please ensure '$ServerDir' and 'print_server.exe' are whitelisted in your third-party security suite."
    }

    # Step 2: Check WinDefend service status
    $wdService = Get-Service -Name WinDefend -ErrorAction SilentlyContinue
    if (-not $wdService) {
        Write-Host "  [INFO] Windows Defender service (WinDefend) is not installed." -ForegroundColor DarkGray
        return $false
    }

    if ($wdService.Status -ne 'Running') {
        Write-Warning "Windows Defender service is currently '$($wdService.Status)' (not Running). Defender exclusions cannot take effect."
        return $false
    }

    # Step 3: Check Add-MpPreference cmdlet and apply exclusions
    try {
        if (Get-Command Add-MpPreference -ErrorAction SilentlyContinue) {
            Add-MpPreference -ExclusionPath $ServerDir -ErrorAction Stop
            Add-MpPreference -ExclusionProcess "print_server.exe" -ErrorAction Stop
            Write-Host "  [OK] Defender exclusion applied for folder: $ServerDir" -ForegroundColor Green
            Write-Host "  [OK] Defender exclusion applied for process: print_server.exe" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  [INFO] Windows Defender cmdlets (Add-MpPreference) not present on this system." -ForegroundColor DarkGray
            return $false
        }
    } catch {
        Write-Warning "Failed to apply Defender exclusions: $($_.Exception.Message)"
        return $false
    }
}

function Register-PrintServerStartup {
    <#
    .SYNOPSIS
        Creates a direct .lnk shortcut with WindowStyle = 7 (Minimized) in the Common Startup
        directory for multi-user support (ENV-02), avoiding Defender ASR rule blocks against VBScript (PROC-02).
    #>
    param(
        [Parameter(Mandatory=$true)][string]$TargetExe,
        [Parameter(Mandatory=$true)][string]$TargetDir,
        [switch]$TestOnly
    )

    # Determine common startup directory for multi-user support (ENV-02)
    $startupFolder = [Environment]::GetFolderPath("CommonStartup")
    if (-not $startupFolder -or -not (Test-Path $startupFolder)) {
        $startupFolder = [Environment]::GetFolderPath("Startup")
    }

    $destinationShortcut = if ($TestOnly) {
        Join-Path $TargetDir "PrintServer.lnk"
    } else {
        Join-Path $startupFolder "PrintServer.lnk"
    }

    # Direct .lnk shortcut with WindowStyle = 7 (Minimized) avoids Defender ASR rule blocks against VBScript
    try {
        $wshShell = New-Object -ComObject WScript.Shell
        $shortcut = $wshShell.CreateShortcut($destinationShortcut)
        $shortcut.TargetPath = $TargetExe
        $shortcut.WorkingDirectory = $TargetDir
        $shortcut.Description = "Barcode Print Server Bridge (Auto-Start Minimized)"
        $shortcut.WindowStyle = 7 # Minimized
        $shortcut.Save()
        Write-Host "  [OK] Minimized startup shortcut registered: $destinationShortcut" -ForegroundColor Green
        return $destinationShortcut
    } catch {
        Write-Warning "Could not configure startup shortcut: $($_.Exception.Message)"
        return $null
    }
}

function Install-PrintServerModule {
    Write-Host "`n=== [4] Install Barcode Print Server Bridge ===" -ForegroundColor Cyan

    $serverDir = $global:RemoteToolsConfig.PrintServerDir
    if (-not (Test-Path $serverDir)) {
        $null = New-Item -ItemType Directory -Path $serverDir -Force
    }

    # Step 1: Terminate running print server gracefully before file write (PS-01)
    $null = Stop-PrintServerGracefully

    # Step 2: Microsoft Defender Exclusion with AV inspection (SEC-01)
    $null = Add-PrintServerDefenderExclusions -ServerDir $serverDir

    # Step 3: Copy or Download print_server.exe
    $destExe = Join-Path $serverDir "print_server.exe"
    $localExe = Get-LocalAssetPath -RelativePath "print_server.exe"

    if ($localExe) {
        Write-Host "  -> Copying local print_server.exe to: $destExe" -ForegroundColor Cyan
        Copy-Item -Path $localExe -Destination $destExe -Force
        Write-Host "  [OK] print_server.exe placed in: $destExe" -ForegroundColor Green
    } else {
        $url = Get-ReleaseAssetUrl -Filename "print_server.exe"
        $downloadOk = Invoke-DownloadWithProgress -Url $url -DestinationPath $destExe -Description "Barcode Print Server"
        if (-not $downloadOk) {
            Write-Error "Failed to obtain print_server.exe. Aborting installation."
            return $false
        }
    }

    # Step 4: Create Multi-User Public Desktop Shortcut (ENV-01, PROC-02)
    try {
        $desktopPath = [Environment]::GetFolderPath("CommonDesktopDirectory")
        if (-not $desktopPath -or -not (Test-Path $desktopPath)) {
            $desktopPath = [Environment]::GetFolderPath("Desktop")
        }
        $desktopShortcut = Join-Path $desktopPath "Print Server.lnk"
        $wshShell = New-Object -ComObject WScript.Shell
        $shortcut = $wshShell.CreateShortcut($desktopShortcut)
        $shortcut.TargetPath = $destExe
        $shortcut.WorkingDirectory = $serverDir
        $shortcut.Description = "Barcode Print Server Bridge"
        $shortcut.WindowStyle = 7 # Minimized
        $shortcut.Save()
        Write-Host "  [OK] Public Desktop shortcut created: $desktopShortcut" -ForegroundColor Green
    } catch {
        Write-Warning "Could not create Desktop shortcut: $($_.Exception.Message)"
    }

    # Step 5: Register Direct Minimized Startup Shortcut (PROC-02, ENV-02)
    $null = Register-PrintServerStartup -TargetExe $destExe -TargetDir $serverDir

    # Step 6: Start immediately minimized if not already running
    $running = Get-Process print_server -ErrorAction SilentlyContinue
    if (-not $running) {
        Write-Host "  -> Starting Print Server minimized right now..." -ForegroundColor Cyan
        Start-Process -FilePath $destExe -WorkingDirectory $serverDir -WindowStyle Minimized
        Start-Sleep -Seconds 2
        
        $checkRunning = Get-Process print_server -ErrorAction SilentlyContinue
        if ($checkRunning) {
            Write-Host "  [OK] Print Server is actively running (Process ID: $($checkRunning.Id))!" -ForegroundColor Green
        }
    } else {
        Write-Host "  [OK] Print Server is already running (Process ID: $($running.Id))." -ForegroundColor Green
    }

    Write-Host "`n[SUCCESS] Print Server installed successfully and configured to run minimized at startup!" -ForegroundColor Green
    return $true
}

function Show-PrintServerMenu {
    do {
        Show-Header
        Write-Host "--- [4] Barcode Print Server Bridge Management ---" -ForegroundColor Cyan
        Write-Host "Select an option from below:`n" -ForegroundColor Yellow
        Write-Host "  [1] Full Setup (Defender Exclusions + Copy + Minimized Startup + Start)" -ForegroundColor White
        Write-Host "  [2] Start Print Server (Minimized Now)" -ForegroundColor White
        Write-Host "  [3] Stop Running Print Server Process" -ForegroundColor White
        Write-Host "  [4] Test Port 4444 Bridge Status & Endpoint" -ForegroundColor White
        Write-Host "  [5] Re-apply Microsoft Defender Exclusions" -ForegroundColor White
        Write-Host "  [6] Return to Main Menu" -ForegroundColor Red
        Write-Host ""

        $psChoice = Read-Host "Enter option [1-6]"
        switch ($psChoice) {
            "1" {
                $null = Install-PrintServerModule
                Wait-UserPrompt "Press Enter to return to Print Server menu..."
            }
            "2" {
                $serverDir = $global:RemoteToolsConfig.PrintServerDir
                $destExe = Join-Path $serverDir "print_server.exe"

                if (-not (Test-Path $destExe)) {
                    Write-Warning "print_server.exe not found in $serverDir. Please run Option 1 (Full Setup) first."
                } else {
                    $running = Get-Process print_server -ErrorAction SilentlyContinue
                    if ($running) {
                        Write-Host "  [INFO] Print Server is already running (PID: $($running.Id))." -ForegroundColor Yellow
                    } else {
                        Start-Process -FilePath $destExe -WorkingDirectory $serverDir -WindowStyle Minimized
                        Start-Sleep -Seconds 2
                        $newProc = Get-Process print_server -ErrorAction SilentlyContinue
                        if ($newProc) {
                            Write-Host "  [OK] Print Server started successfully (PID: $($newProc.Id))!" -ForegroundColor Green
                        } else {
                            Write-Warning "Failed to verify print_server running state."
                        }
                    }
                }
                Wait-UserPrompt "Press Enter to return to Print Server menu..."
            }
            "3" {
                $stopped = Stop-PrintServerGracefully
                if ($stopped) {
                    Write-Host "  [OK] Print Server process stopped successfully." -ForegroundColor Green
                } else {
                    Write-Host "  [INFO] Print Server is not currently running." -ForegroundColor Yellow
                }
                Wait-UserPrompt "Press Enter to return to Print Server menu..."
            }
            "4" {
                Write-Host "`nChecking Print Server Bridge on port 4444..." -ForegroundColor Cyan
                $proc = Get-Process print_server -ErrorAction SilentlyContinue
                if ($proc) {
                    Write-Host "  [OK] Process 'print_server.exe' is RUNNING (PID: $($proc.Id))" -ForegroundColor Green
                } else {
                    Write-Host "  [FAIL] Process 'print_server.exe' is NOT RUNNING" -ForegroundColor Red
                }

                $portCheck = Test-PortAvailability -Port 4444 -ReportProcess
                if (-not $portCheck.Available) {
                    $owner = if ($portCheck.ProcessName) { "$($portCheck.ProcessName) (PID: $($portCheck.OwningProcessId))" } else { "PID: $($portCheck.OwningProcessId)" }
                    if ($proc -and $proc.Id -eq $portCheck.OwningProcessId) {
                        Write-Host "  [OK] Port 4444 is properly bound by print_server.exe (PID: $($proc.Id))" -ForegroundColor Green
                    } else {
                        Write-Warning "Port 4444 is occupied by another process: $owner!"
                    }
                } else {
                    Write-Host "  [FAIL] Port 4444 is NOT listening (Available/Unbound)." -ForegroundColor Red
                }

                $portOpen = Test-NetworkPort -TargetHost "127.0.0.1" -Port 4444 -TimeoutSeconds 2
                if ($portOpen) {
                    try {
                        $null = Invoke-RestMethod -Uri "http://127.0.0.1:4444/printers" -TimeoutSec 2 -ErrorAction Stop
                        Write-Host "  [OK] HTTP Endpoint /printers responded successfully!" -ForegroundColor Green
                    } catch {
                        Write-Host "  [INFO] Port 4444 open, endpoint response: $($_.Exception.Message)" -ForegroundColor DarkGray
                    }
                }
                Wait-UserPrompt "Press Enter to return to Print Server menu..."
            }
            "5" {
                $null = Add-PrintServerDefenderExclusions -ServerDir $global:RemoteToolsConfig.PrintServerDir
                Wait-UserPrompt "Press Enter to return to Print Server menu..."
            }
            "6" { break }
            default {
                Write-Host "Invalid option. Please choose between 1 and 6." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } while ($psChoice -ne "6")
}

function Show-MainMenu {
    Show-Header
    Write-Host "Select a module from the menu below:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] OpenVPN Client & Profile Menu" -ForegroundColor White
    Write-Host "  [2] VOIP & MicroSIP Management Menu" -ForegroundColor White
    Write-Host "  [3] Printer Driver Installation Menu" -ForegroundColor White
    Write-Host "  [4] Barcode Print Server Bridge Menu" -ForegroundColor White
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
            "1" { Show-OpenVpnMenu }
            "2" { Show-VoipMenu }
            "3" { Show-PrinterDriverMenu }
            "4" { Show-PrintServerMenu }
            "5" { Write-Host "`nExiting Remote Tools. Goodbye!" -ForegroundColor Green; break }
            default { Write-Host "Invalid option. Please choose between 1 and 5." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    } while ($choice -ne "5")
}
