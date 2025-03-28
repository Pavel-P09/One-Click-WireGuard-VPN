#!/usr/bin/env pwsh

<#
  PowerShell WireGuard VPN Client
  --------------------------------
  - Fetches VPN config from remote REST API
  - Requires username/password each time
  - Connects/disconnects using wireguard.exe
  - Logs activity to local file
#>

# === CONFIGURABLE VARIABLE ===
$global:ApiUrl   = "http://SERVER_IP:5000/get-config"  # Replace SERVER_IP with actual server IP
$global:WgConfig = "$env:USERPROFILE\\wg-client.conf"
$global:WgExe    = "C:\\Program Files\\WireGuard\\wireguard.exe"
$global:LogFile  = "$env:USERPROFILE\\vpn-wg-client.log"

function Log {
    param([string]$text)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $text" | Out-File -FilePath $global:LogFile -Append -Encoding utf8
}

function Connect-VPN {
    Write-Host "Enter username:"
    $Username = Read-Host
    Write-Host "Enter password:"
    $SecurePassword = Read-Host -AsSecureString
    $PlainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
    )

    $JsonPayload = @{ username = $Username; password = $PlainPassword } | ConvertTo-Json

    try {
        $Response = Invoke-RestMethod -Uri $global:ApiUrl -Method POST -Body $JsonPayload -ContentType 'application/json'
    } catch {
        Write-Host "Error: Could not contact server. $_"
        Log "Failed to reach API server: $_"
        return
    }

    if ($Response.config) {
        $Response.config | Out-File -FilePath $global:WgConfig -Encoding ASCII
        & "$global:WgExe" /installtunnelservice $global:WgConfig | Out-Null
        Start-Sleep -Seconds 2
        Write-Host "VPN connected successfully."
        Log "Connected VPN as $Username"
    } else {
        Write-Host "Authentication failed or no config received."
        Log "Auth failed for $Username"
    }
}

function Disconnect-VPN {
    & "$global:WgExe" /uninstalltunnelservice wg-client.conf | Out-Null
    if (Test-Path $global:WgConfig) { Remove-Item $global:WgConfig -Force }
    Write-Host "VPN disconnected."
    Log "Disconnected VPN"
}

function Show-Menu {
    Clear-Host
    Write-Host "============================="
    Write-Host "   WireGuard VPN  Menu"
    Write-Host "============================="
    Write-Host "1) Connect VPN"
    Write-Host "2) Disconnect VPN"
    Write-Host "3) Exit"
}

$exit = $false

while (-not $exit) {
    Show-Menu
    $Choice = Read-Host -Prompt "Choose an option [1-3]"

    switch ($Choice) {
        '1' { Connect-VPN }
        '2' { Disconnect-VPN }
        '3' { Log "Exited menu"; $exit = $true }
        default { Write-Host "Invalid choice. Please try again." }
    }

    if (-not $exit) {
        Write-Host "`nPress Enter to continue..."
        [void][System.Console]::ReadKey()
    }
}

Write-Host "Goodbye!"
