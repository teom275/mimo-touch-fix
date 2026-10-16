<#
.SYNOPSIS
    Mimo Touch Screen Mapping Fix for Windows.
    Maps the USB Mimo touch digitizer to the Mimo display monitor in the Windows WISP subsystem.
.DESCRIPTION
    Fixes the issue where touching the Mimo external monitor clicks on the primary screen
    or current mouse cursor position due to stale or missing hardware mappings in:
    HKLM:\SOFTWARE\Microsoft\Wisp\Pen\Digimon
#>

[CmdletBinding()]
param()

# Check Administrator privileges; if not elevated, relaunch with elevation prompt
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Elevating privileges to Administrator..." -ForegroundColor Yellow
    $scriptPath = $MyInvocation.MyCommand.Path
    if (-not $scriptPath) {
        $scriptPath = "$PSScriptRoot\Fix-MimoTouchMapping.ps1"
    }
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
    exit
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "       MIMO TOUCH SCREEN MAPPING UTILITY          " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Detect Mimo Monitor
Write-Host "[1/4] Detecting MIMO Monitor..." -ForegroundColor Gray
$monitors = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID -ErrorAction SilentlyContinue

$mimoMonitor = $monitors | Where-Object { 
    $friendlyName = [System.Text.Encoding]::ASCII.GetString($_.UserFriendlyName -ne 0)
    $friendlyName -match "MIMO" -or $_.InstanceName -match "CMN1041"
} | Select-Object -First 1

if (-not $mimoMonitor) {
    Write-Host "[-] Could not detect MIMO Monitor in WMI." -ForegroundColor Red
    Write-Host "    Make sure the Mimo screen is connected and powered on." -ForegroundColor Yellow
    Pause
    exit 1
}

$monitorFriendly = [System.Text.Encoding]::ASCII.GetString($mimoMonitor.UserFriendlyName -ne 0)
$cleanInstance = $mimoMonitor.InstanceName.TrimEnd('_', '0').TrimEnd('_')
$monitorGuid = "{e6f07b5f-ee97-4a90-b076-33f57bf4eaa7}"
$displayDevicePath = "\\?\" + $cleanInstance.Replace('\', '#') + "#" + $monitorGuid

Write-Host "    Found Monitor: $monitorFriendly ($cleanInstance)" -ForegroundColor Green
Write-Host "    Display Path : $displayDevicePath" -ForegroundColor DarkGray
Write-Host ""

# 2. Detect Mimo Touch Digitizer
Write-Host "[2/4] Detecting MIMO Touch Digitizer..." -ForegroundColor Gray
$touchDevices = Get-PnpDevice -Class "HIDClass" -Status "OK" -ErrorAction SilentlyContinue | Where-Object {
    $_.InstanceId -match "VID_266E&PID_0102"
}

$touchDev = $touchDevices | Where-Object { $_.InstanceId -like "*Col01*" } | Select-Object -First 1
if (-not $touchDev) {
    $touchDev = $touchDevices | Select-Object -First 1
}

if (-not $touchDev) {
    Write-Host "[-] Could not detect MIMO Touch Screen digitizer (VID_266E&PID_0102)." -ForegroundColor Red
    Write-Host "    Make sure the USB touch cable is firmly connected." -ForegroundColor Yellow
    Pause
    exit 1
}

$hidGuid = "{4d1e55b2-f16f-11cf-88cb-001111000030}"
$touchInstanceId = $touchDev.InstanceId
$hidDevicePath = "\\?\" + $touchInstanceId.Replace('\', '#') + "#" + $hidGuid
$registryValueName = "20-" + $hidDevicePath

Write-Host "    Found Touch Digitizer: $($touchDev.FriendlyName)" -ForegroundColor Green
Write-Host "    Instance ID          : $touchInstanceId" -ForegroundColor DarkGray
Write-Host "    HID Device Path      : $hidDevicePath" -ForegroundColor DarkGray
Write-Host ""

# 3. Update Windows Wisp Registry
Write-Host "[3/4] Writing mapping to Windows Registry..." -ForegroundColor Gray
$regPath = "HKLM:\SOFTWARE\Microsoft\Wisp\Pen\Digimon"

if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}

# Clean old/stale VID_266E mappings
$currentProps = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
if ($currentProps) {
    $currentProps.PSObject.Properties | Where-Object { 
        $_.Name -like "*VID_266E*" -and $_.Name -ne $registryValueName 
    } | ForEach-Object {
        Write-Host "    Removing obsolete mapping: $($_.Name)" -ForegroundColor Yellow
        Remove-ItemProperty -Path $regPath -Name $_.Name -ErrorAction SilentlyContinue
    }
}

# Set the new mapping
Set-ItemProperty -Path $regPath -Name $registryValueName -Value $displayDevicePath -Type String -Force
Write-Host "    [OK] Successfully mapped touch digitizer to MIMO display!" -ForegroundColor Green
Write-Host ""

# 4. Restart the HID Touch Device
Write-Host "[4/4] Restarting touch device to apply changes immediately..." -ForegroundColor Gray
$restartOutput = pnputil.exe /restart-device "$touchInstanceId" 2>&1

if ($LASTEXITCODE -eq 0 -or $restartOutput -match "successfully restarted|reiniciado correctamente") {
    Write-Host "    [OK] Device restarted successfully!" -ForegroundColor Green
} else {
    Write-Host "    Note: pnputil returned: $restartOutput" -ForegroundColor DarkYellow
    Write-Host "    (The registry mapping has been written; if touch hasn't refreshed, reconnect the USB cable or reboot)." -ForegroundColor DarkYellow
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host "       MIMO TOUCH MAPPING COMPLETED!             " -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host "You can now test touching your Mimo screen." -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to close..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
