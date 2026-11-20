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
    OpenVpnMsiUrl     = "https://github.com/OpenVPN/openvpn/releases/download/v2.6.12/OpenVPN-2.6.12-I001-amd64.msi"
}

# Embedded Base64 for IPTSP VPN Profile (offline/portable fallback)
$global:EmbeddedIptspOvpn = "ZGV2IHR1bgpwZXJzaXN0LXR1bgpwZXJzaXN0LWtleQpkYXRhLWNpcGhlcnMgQUVTLTI1Ni1HQ006QUVTLTEyOC1HQ006Q0hBQ0hBMjAtUE9MWTEzMDU6QUVTLTI1Ni1DQkMKZGF0YS1jaXBoZXJzLWZhbGxiYWNrIEFFUy0yNTYtQ0JDCmF1dGggU0hBMjU2CnRscy1jbGllbnQKY2xpZW50CnJlc29sdi1yZXRyeSBpbmZpbml0ZQpyZW1vdGUgMTgyLjE2My4xMjYuMjUzIDExOTQgdWRwNApub2JpbmQKdmVyaWZ5LXg1MDktbmFtZSAiQ2FycnkgQmVlIiBuYW1lCmF1dGgtdXNlci1wYXNzCnJlbW90ZS1jZXJ0LXRscyBzZXJ2ZXIKZXhwbGljaXQtZXhpdC1ub3RpZnkKCjxjYT4KLS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUVLVENDQXhHZ0F3SUJBZ0lJQlJnVGIrWTFDdzB3RFFZSktvWklodmNOQVFFTEJRQXdaekVVTUJJR0ExVUUKQXhNTGFXNTBaWEp1WVd3dFkyRXhDekFKQmdOVkJBWVRBa0pFTVE0d0RBWURWUVFJRXdWRWFHRnJZVEVRTUE0RwpBMVVFQnhNSFVtOWhaQzB5TWpFU01CQUdBMVVFQ2hNSlEyRnljbmtnUW1WbE1Rd3dDZ1lEVlFRTEV3TXhNREF3CkhoY05NalV4TURJNU1EWXpNekExV2hjTk16VXhNREkzTURZek16QTFXakJuTVJRd0VnWURWUVFERXd0cGJuUmwKY201aGJDMWpZVEVMTUFrR0ExVUVCaE1DUWtReERqQU1CZ05WQkFnVEJVUm9ZV3RoTVJBd0RnWURWUVFIRXdkUwpiMkZrTFRJeU1SSXdFQVlEVlFRS0V3bERZWEp5ZVNCQ1pXVXhEREFLQmdOVkJBc1RBekV3TURDQ0FTSXdEUVlKCktvWklodmNOQVFFQkJRQURnZ0VQQURDQ0FRb0NnZ0VCQUtjTVJQMk1LbU51QkZDN0pZN2N5VmloMHpSd010aTQKMkJOMW11aDNmOG1UdWk1Wm54ZlBwc0FCNDIrSW1KN3g4emQ4elB0bkJHOHhyUWtKdk1oZjBjQ3R2MzVJRVNkSwp2R0ljcGpla3Vray9TRjk0dE5JUEZBSWg3SHZ3QWpVOHZGajFGTWlDeHpQdUp6NlVXY0l0eE1qN3lQYW9wbVduCkQxZUNYRGFGVUh6dVdmVzBBck9Ic0dGZjJPR1RKVVpKbkhMUWFWcENUVU5YL1l3UkJsY0RpMmxEOXRrelg1ZHgKTStjdzNnZ3ozTUZ4OUU4SEV2SzFDQVN4eXRZeDZhYnFraTF0QzR3cjVZSzJPU0pZSWVGMllHRTVDRDdvczlzNQpyQUllRHIzNUdYN3djRWVNZVpsUGxJaTNsWnZxZDlwamR3cFFIQnl3K1FNbnZ0OTdKNnF6NEVjQ0F3RUFBYU9CCjJEQ0IxVEFkQmdOVkhRNEVGZ1FVK1VqSkJjUWxMWitOY21tS0pJYlFWNDRsZExRd2daZ0dBMVVkSXdTQmtEQ0IKallBVStVakpCY1FsTForTmNtbUtKSWJRVjQ0bGRMU2hhNlJwTUdjeEZEQVNCZ05WQkFNVEMybHVkR1Z5Ym1GcwpMV05oTVFzd0NRWURWUVFHRXdKQ1JERU9NQXdHQTFVRUNCTUZSR2hoYTJFeEVEQU9CZ05WQkFjVEIxSnZZV1F0Ck1qSXhFakFRQmdOVkJBb1RDVU5oY25KNUlFSmxaVEVNTUFvR0ExVUVDeE1ETVRBd2dnZ0ZHQk52NWpVTERUQU0KQmdOVkhSTUVCVEFEQVFIL01Bc0dBMVVkRHdRRUF3SUJCakFOQmdrcWhraUc5dzBCQVFzRkFBT0NBUUVBWTZLZwpMeUhuRFNwYTZFaHgvWjRYMzU4YUpnUnM0S29HSm5zd0trekxBbE52ZHRyREVVL1k1dWs1Ukt3V0FJdjNaK2MrCnpZNFFpVzZxek5Hbm9BMmFESkRSTkxWWFJuN1dsZW1ZNW8wdjJNRzdIU0E0UXNNK0l5QlNOdUFJcUMvbUVDNVQKTi9MbHhNNWkrMVlXdlVMQXYwQUdkT3dhMi9XUUVpb0RNTTlxY0Vpcm9lWGNmbE9ZK3NVY3ZMalBtMnNWYmlzbwo0Mkx5a2E0c1oyeDZndWVSKzV1TnVSN3VOS0NIRWFXcTVRaERtNDB1YVBYOVRDZHlUS2JBUVkwa2tncjI2ZlhjClNxQkhkR1dHN3YzVmlTK0FCWWJ5NkE5MUtKRnpCZ1l5MCs1KzlybjQyV2dLQnRGZ1J2U2Z6QkZsellYaHRqaEYKeEZIQldEODZ3enZLQW9NOERBPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo8L2NhPgo8Y2VydD4KLS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUVlekNDQTJPZ0F3SUJBZ0lCQWpBTkJna3Foa2lHOXcwQkFRc0ZBREJuTVJRd0VnWURWUVFERXd0cGJuUmwKY201aGJDMWpZVEVMTUFrR0ExVUVCaE1DUWtReERqQU1CZ05WQkFnVEJVUm9ZV3RoTVJBd0RnWURWUVFIRXdkUwpiMkZrTFRJeU1SSXdFQVlEVlFRS0V3bERZWEp5ZVNCQ1pXVXhEREFLQmdOVkJBc1RBekV3TURBZUZ3MHlOVEV3Ck1qa3dOalEyTlRWYUZ3MHpOVEV3TWpjd05qUTJOVFZhTUdReEN6QUpCZ05WQkFZVEFrSkVNUTR3REFZRFZRUUkKRXdWRWFHRnJZVEVRTUE0R0ExVUVCeE1IVW05aFpDMHlNakVTTUJBR0ExVUVDaE1KUTJGeWNua2dRbVZsTVF3dwpDZ1lEVlFRTEV3TXhNREF4RVRBUEJnTlZCQU1UQ0dOaGNuSjVZbVZsTUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGCkFBT0NBUThBTUlJQkNnS0NBUUVBNEIzbEtLd0h1UUF4OHNCd3hqbDFSZE54VGhDZTJaUjlyQUo2RXRuVGZwV2YKRzN0S2tUVFM0aW9sakZOQ0RlZ2xlbEtkcmJMcVJHcks2WDhJa0JNRThEWlFlMkVzMFBGU2hsa05CTVAxZ0dtbApKZGlUSFpqL2VmWVd5NXhUNXRVSkg3azFCK3B6Q0JtYmU1V3RpQjQ5VjRUc3VDVjdDL2RzaTNIZHladW1EMmtZCjV3Sm9vZXpVL09SMEJpU0pDZytFMUhKWFJPRFk1dXZPeGJNSUNPVU1VSFJUTTJYSHM1eFFaYnRkNTMwRUl0cTMKZHRqUTBqQklhUnJnQ1pRQU5IMTU4bm1kdkhoejVXRnltVDFlL0xwU0JzYTVJM0ZETFV3emMzWkE1S3NrSFZVNwp5Y1VNK0RUdjF3VGFETlpFY0xwVkxOMWNGcU52UEdCUTdKcTUwNDZmblFJREFRQUJvNElCTXpDQ0FTOHdDUVlEClZSMFRCQUl3QURBTEJnTlZIUThFQkFNQ0JlQXdNUVlKWUlaSUFZYjRRZ0VOQkNRV0lrOXdaVzVUVTB3Z1IyVnUKWlhKaGRHVmtJRlZ6WlhJZ1EyVnlkR2xtYVdOaGRHVXdIUVlEVlIwT0JCWUVGR1huTG5keWxpbHAyS1ZSaEFYbAorTlZXdXoyOE1JR1lCZ05WSFNNRWdaQXdnWTJBRlBsSXlRWEVKUzJmalhKcGlpU0cwRmVPSlhTMG9XdWthVEJuCk1SUXdFZ1lEVlFRREV3dHBiblJsY201aGJDMWpZVEVMTUFrR0ExVUVCaE1DUWtReERqQU1CZ05WQkFnVEJVUm8KWVd0aE1SQXdEZ1lEVlFRSEV3ZFNiMkZrTFRJeU1SSXdFQVlEVlFRS0V3bERZWEp5ZVNCQ1pXVXhEREFLQmdOVgpCQXNUQXpFd01JSUlCUmdUYitZMUN3MHdFd1lEVlIwbEJBd3dDZ1lJS3dZQkJRVUhBd0l3RXdZRFZSMFJCQXd3CkNvSUlZMkZ5Y25saVpXVXdEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBRnB6eitLWE1jT2FBY2llVEpHOEd2RkMKNVNOMXc4YVl5cUJrOTV3N1BFdWNjeGM0QVMyL0d6elZKOWZEellYMFhkR2xoSVpHTVYvVExkbE5vV2xtSTMvMwpvWVhpRXVHV3dRS2JNcXhxZzgxRmVlcnNidFVndjNmK1B5MzE4RE9pZWF5T3NNd1JzZ0Y0eXlXeitZU1pWNTRuCmg3dlVqVVNVZXNNUnBRMm1qczNLaEt1Yi80SGxCZzFkMldHdHZSK1hlSkNPbENBZ0hPcGg2amJGaVM5SXVkMWcKWWRMVEprVFFCR29uWkNobzFYU2h1YnNHTVFYYStvenNoeG91KzF0T0Rqb0RUdWFtWHZ1NW5DMFZGbnhrRm9McQpnR3ZUbGMvZ1M3MUQ0L3pTQWxFUmE5TWdYQmRhK2xrMHFTSnhKRTR0SjlyNXM1ZDR5aFI2RldtMzM5Q05UWjA9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0KPC9jZXJ0Pgo8a2V5PgotLS0tLUJFR0lOIFBSSVZBVEUgS0VZLS0tLS0KTUlJRXZRSUJBREFOQmdrcWhraUc5dzBCQVFFRkFBU0NCS2N3Z2dTakFnRUFBb0lCQVFEZ0hlVW9yQWU1QURIeQp3SERHT1hWRjAzRk9FSjdabEgyc0Fub1MyZE4rbFo4YmUwcVJOTkxpS2lXTVUwSU42Q1Y2VXAydHN1cEVhc3JwCmZ3aVFFd1R3TmxCN1lTelE4VktHV1EwRXcvV0FhYVVsMkpNZG1QOTU5aGJMbkZQbTFRa2Z1VFVINm5NSUdadDcKbGEySUhqMVhoT3k0SlhzTDkyeUxjZDNKbTZZUGFSam5BbWloN05UODVIUUdKSWtLRDRUVWNsZEU0TmptNjg3Rgpzd2dJNVF4UWRGTXpaY2V6bkZCbHUxM25mUVFpMnJkMjJORFNNRWhwR3VBSmxBQTBmWG55ZVoyOGVIUGxZWEtaClBWNzh1bElHeHJramNVTXRURE56ZGtEa3F5UWRWVHZKeFF6NE5PL1hCTm9NMWtSd3VsVXMzVndXbzI4OFlGRHMKbXJuVGpwK2RBZ01CQUFFQ2dnRUFLVVAzNU5SQUc4VTRiUzBYMXJmUHF3cXlxeUFPVDV1eXhCQTByL0hocWtZYwpaSy8vMjlxeEZhbVMvbEo2TUJ0Vmd6OWcveEdaWnYyTzNRMWg0ejFOUkhtTHVodjdaNEYzbzNzVUZaT0xTWmlxCkt0ekV3Y2RoQ3ZEUDQ2K21Gek9VbVgyOWtQYVBOYWVaWkZqNytic3Zxa1MwWFhleFAxUFFiYUNLcU10NitRMFYKbktKak1zSGN4b2hOVW42a3lXaG03ajBZK2JCcXpaRjJUb3pMbnhTV0tacUVTY29nOThrSXB0d1laQnBxWWJlYgpqbFRobE9hNWlKWHRHRVNDUVFQaXlXaEp6RkNjTkpZZkJnUUNtQmNnQjJ0N29hcGhScCsrWE1pay9uS3lnVzVmCnhuNFloTnVsb0M2VjR3WmRmNk5qNHFiZGRKT3hRZmVuOE9vZS9ONVZOUUtCZ1FENVE2UW4xV3E3aHpnaC80WmQKQmJZWktlOEVVWVdkMzVFZGVORi92QkNtZEdzdnVlaGJHRXdQWURRN2N5d0h1QkRIaHNZcDRmcmZhTXArNi9XZApsMEEzdy9NRXRJbVV2aFRJRk5uaGR3a2tEK0hlb2wwcFhzbEVaMHNXUDE4NVZFZkJpeWNPS3RDMkdMWkxOTXRXClRoS2lDY2JBZ0FQMFFoMUJGd0wzN3hhKy93S0JnUURtTEVuL0YrSW1MaUtJWjJhZ0dvNnBxZUE5bk9zcHdwZFoKUExFZHpkVTl4OU1ndGN1RmVPeVR3d3U0NS9aNUdCMVpMNlVEOHZCWXM1ekg2ejNqakJMUHpsdHJ6eXl6dVBRMQpVcjYrYXB0TjhlWEpNSkZhenhybGNuemtHcTlmbk8yaExUNnlwRkRqZDFGQU5XZHY3WTU4UU5ZOVVqNklLTVJPCkM2V2lUY0E5WXdLQmdGVnJ1OGEyMlhQWWZBRVNxejRYcGZicnF2Qms2NUJWdkVwSVRDc2xET091UThsQVFZTnUKU1NwL3dvYVpDbjYrc21sZUkyelk5M3MyVXlhNXdCczRhUlp6UFVYZ2hNR0hmbUd1MjVmcmppTmdtZndNMGpaSwpPRmtMdU95djNQY3RqY1dpNVVoeW5jRzVxRWNQbVp0QytCbTFsZm9FSk5iQkRYdHY0bUdLK3RXTEFvR0JBT1U2CmJtY3liZk1BTnp3SlhsZE1tNCswc3JJcHVMbmFKY2lsZk83bHN0ellTUmRtZGMzelpBaTBVdFJQajFPQ0JKaHgKcnJHRUhJRDZQOFdLTGhTVHg1aFZOdzdqUU8ycjRPbktBbFM0N3ZwdFVoOVAwekxRMTBSekJKWlhUUmkzdktDcgo0cWtlbzhBbGNERzEvZEdta0NTR25kWnNOZ0o4TnlSU3pSNGF1TDFwQW9HQU5DUFo1SGxJM0JIRjhoNFdPMjFpClVQck1IMFhTVEdYY0tHVkVBWFhKeUQ1Tk9adlNMWHJXWEtBV0ZWMHQ3K0tGamRRNVp2blFralNPeGFzM0c2UU0KRElkeXhiTmRzVXZlNWIxa1JZU0JJYis3dlc5dDJnNFd0YnNDV01sbHM4TEdmREl1WGJKZVV5T0RKRVVscDBWRApUK0NNaGlqR3d0S0ZsRnRtQS9kUlFXQT0KLS0tLS1FTkQgUFJJVkFURSBLRVktLS0tLQo8L2tleT4Ka2V5LWRpcmVjdGlvbiAxCjx0bHMtYXV0aD4KIwojIDIwNDggYml0IE9wZW5WUE4gc3RhdGljIGtleQojCi0tLS0tQkVHSU4gT3BlblZQTiBTdGF0aWMga2V5IFYxLS0tLS0KMDkzOWI1ZjNlYjY3YjY3YTljZjgxYjUyMWIyMWMxNTYKNGIzZTg5MTk3MWNiYTkyYTFkMzUzZjRiYjYyNDJmNTAKODUzYjljNGUxMGY5M2UyYTViYzAwZDUyOThmZmY0ZTEKOWU2M2MzOTg4Y2U1MWJkMTEwZmMzM2IxNTMyOWU3YTkKZDZiOGU4NDNkOWVmMDEzOWI2ZGUzODgxYzFlMThjNDMKOTYxZmU1YjQ2ZGVlMmZjY2Y3ZDM5OWU3MDljNTk5MzMKNDY2NjEyZTdlZGJlNWFmMjkyYzUwMzFjMDA3ZDA4NGEKZTQ0MTExZGViMTc3ZGNhZDdjZGZjMDFmOGI5Zjc5NGQKZTU4NDZiNTUyNWJiMWE2MDEwYWFlYWU4Nzk1M2I1ODAKMmQyYTQwODRlMmU5Y2E0NDYzYTU1YjExNjJkZGJhMWMKMDQ0NmJjZjVlMTM5YWEzMGFlOTA3MDhhNDJiYzJkOWQKOTI1MDRmMDFmYzNhMjJkZjdhYzUyNTI4Yjc2ZDMwZWMKYjE2NGVhM2I4ZGI0ODlhNTM4YzgxODgzNmFiYTY3MzMKOTk0ZTEzYzA0MjNkNTFhMjYzZDViOTFlMmYxZTdkY2IKNzIwNWUxZDBlOWFiZDlkZjI2ZjVkNjY4NDIyMjAyNTUKMTkxODE4NGU3YzA4Yzg2NWZhNThjZjU2Y2U1OGY4YjAKLS0tLS1FTkQgT3BlblZQTiBTdGF0aWMga2V5IFYxLS0tLS0KPC90bHMtYXV0aD4K"


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

function Deploy-OpenVpnConfig {
    param(
        [Parameter(Mandatory=$true)][string]$TargetDirectory
    )
    if (-not (Test-Path $TargetDirectory)) {
        $null = New-Item -ItemType Directory -Path $TargetDirectory -Force
    }

    $destPath = Join-Path $TargetDirectory "IPTSP VPN.ovpn"
    
    # If local file exists, use it; otherwise use embedded fallback
    $localFile = Join-Path $PSScriptRoot "IPTSP VPN.ovpn"
    if (Test-Path $localFile) {
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

    $openVpnGuiPath = "C:\Program Files\OpenVPN\bin\openvpn-gui.exe"
    $isInstalled = Test-Path $openVpnGuiPath

    if (-not $isInstalled) {
        Write-Host "  -> OpenVPN Client is not installed. Preparing installation..." -ForegroundColor Yellow
        $msiDest = Join-Path $global:RemoteToolsConfig.TempDir "OpenVPN-Client.msi"
        
        # Try downloading OpenVPN installer
        $downloadSuccess = Invoke-DownloadWithProgress -Url $global:RemoteToolsConfig.OpenVpnMsiUrl -DestinationPath $msiDest -Description "OpenVPN Community Client MSI"
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
    } else {
        Write-Host "  [OK] OpenVPN Client is already installed." -ForegroundColor Green
    }

    # Deploy configuration profile to user directory and program files
    $userConfigDir = Join-Path $env:USERPROFILE "OpenVPN\config"
    $sysConfigDir = "C:\Program Files\OpenVPN\config"
    
    $null = Deploy-OpenVpnConfig -TargetDirectory $userConfigDir
    if (Test-Path "C:\Program Files\OpenVPN") {
        $null = Deploy-OpenVpnConfig -TargetDirectory $sysConfigDir
    }

    # Ensure desktop shortcut
    try {
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = Join-Path $desktopPath "OpenVPN GUI.lnk"
        if ((Test-Path $openVpnGuiPath) -and (-not (Test-Path $shortcutPath))) {
            $wshShell = New-Object -ComObject WScript.Shell
            $shortcut = $wshShell.CreateShortcut($shortcutPath)
            $shortcut.TargetPath = $openVpnGuiPath
            $shortcut.WorkingDirectory = "C:\Program Files\OpenVPN\bin"
            $shortcut.Description = "OpenVPN GUI Client"
            $shortcut.Save()
            Write-Host "  [OK] OpenVPN Desktop shortcut created." -ForegroundColor Green
        }
    } catch {
        Write-Warning "Could not create desktop shortcut: $($_.Exception.Message)"
    }

    Write-Host "`n[SUCCESS] OpenVPN Setup Completed! You can now launch OpenVPN GUI and connect to 'IPTSP VPN'." -ForegroundColor Green
    return $true
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
            "1" { $null = Install-OpenVPNModule; Write-Host "`nPress Enter to return to menu..."; [void][System.Console]::ReadLine() }
            "2" { Write-Host "`nFeature 2 selected" -ForegroundColor Cyan; Start-Sleep -Seconds 1 }
            "3" { Write-Host "`nFeature 3 selected" -ForegroundColor Cyan; Start-Sleep -Seconds 1 }
            "4" { Write-Host "`nFeature 4 selected" -ForegroundColor Cyan; Start-Sleep -Seconds 1 }
            "5" { Write-Host "`nExiting Remote Tools. Goodbye!" -ForegroundColor Green; break }
            default { Write-Host "Invalid option. Please choose between 1 and 5." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    } while ($choice -ne "5")
}
