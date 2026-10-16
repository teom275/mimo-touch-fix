<#
.SYNOPSIS
    EasyDeck Companion Server & Launcher for Windows.
    Zero-install: uses native Windows PowerShell and .NET.
#>

[CmdletBinding()]
param(
    [int]$Port = 8080
)

# 1. Compile native Windows Media and Volume key simulator in memory
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class NativeAudioBridge {
    [DllImport("user32.dll")]
    public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);

    public const byte VK_VOLUME_MUTE = 0xAD;
    public const byte VK_VOLUME_DOWN = 0xAE;
    public const byte VK_VOLUME_UP = 0xAF;
    public const byte VK_MEDIA_NEXT_TRACK = 0xB0;
    public const byte VK_MEDIA_PREV_TRACK = 0xB1;
    public const byte VK_MEDIA_PLAY_PAUSE = 0xB3;

    public static void PressKey(byte key) {
        keybd_event(key, 0, 0, UIntPtr.Zero);
        keybd_event(key, 0, 2, UIntPtr.Zero);
    }
}
"@

# 2. Locate Browser (Edge or Chrome)
$browserExe = @(
    "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    "C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    "C:\Program Files\Google\Chrome\Application\chrome.exe",
    "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

# 3. Detect Mimo / Secondary Screen Position
Add-Type -AssemblyName System.Windows.Forms
$screens = [System.Windows.Forms.Screen]::AllScreens

# Try to find a screen matching ~1024x640 or non-primary screen
$targetScreen = $screens | Where-Object { 
    ($_.Bounds.Width -eq 1024 -and $_.Bounds.Height -eq 640) -or 
    ($_.Bounds.Width -eq 640 -and $_.Bounds.Height -eq 1024)
} | Select-Object -First 1

if (-not $targetScreen) {
    # If no 1024x640 screen, try to find any secondary screen
    $targetScreen = $screens | Where-Object { -not $_.Primary } | Select-Object -First 1
}

$windowArgs = ""
if ($targetScreen) {
    $posX = $targetScreen.Bounds.X
    $posY = $targetScreen.Bounds.Y
    $w = $targetScreen.Bounds.Width
    $h = $targetScreen.Bounds.Height
    $windowArgs = "--window-position=$posX,$posY --window-size=$w,$h"
}

# 4. Start HTTP Server
$rootPath = $PSScriptRoot
if (-not $rootPath) { $rootPath = "." }
$indexPath = Join-Path $rootPath "index.html"

$listener = New-Object System.Net.HttpListener
$prefix = "http://localhost:$Port/"
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
} catch {
    $Port = 8085
    $prefix = "http://localhost:$Port/"
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add($prefix)
    $listener.Start()
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "            EASYDECK COMPANION SERVER             " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  Servidor local activo en: $prefix" -ForegroundColor Green
if ($targetScreen) {
    Write-Host "  Pantalla detectada: $($targetScreen.Bounds.Width)x$($targetScreen.Bounds.Height) en ($posX, $posY)" -ForegroundColor DarkGray
}
Write-Host "  Minimiza esta ventana mientras uses EasyDeck." -ForegroundColor Yellow
Write-Host "  Presiona Ctrl + C para cerrar." -ForegroundColor DarkGray
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# 5. Launch Browser in Frameless App Mode
$appUrl = "$prefix"
if ($browserExe) {
    $procArgs = "--app=$appUrl $windowArgs"
    Start-Process -FilePath $browserExe -ArgumentList $procArgs
} else {
    Start-Process $appUrl
}

# 6. Main HTTP Loop
while ($listener.IsListening) {
    $context = $listener.GetContext()
    $req = $context.Request
    $res = $context.Response

    # CORS
    $res.AddHeader("Access-Control-Allow-Origin", "*")
    $res.AddHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")

    if ($req.HttpMethod -eq "OPTIONS") {
        $res.StatusCode = 200
        $res.Close()
        continue
    }

    $rawUrl = $req.RawUrl
    
    # API Endpoints
    if ($rawUrl -match "^/api/(.*)") {
        $endpoint = $Matches[1].ToLower()
        $jsonResponse = '{"success": true}'

        switch ($endpoint) {
            "media/playpause" { [NativeAudioBridge]::PressKey([NativeAudioBridge]::VK_MEDIA_PLAY_PAUSE) }
            "media/next"      { [NativeAudioBridge]::PressKey([NativeAudioBridge]::VK_MEDIA_NEXT_TRACK) }
            "media/prev"      { [NativeAudioBridge]::PressKey([NativeAudioBridge]::VK_MEDIA_PREV_TRACK) }
            "volume/up"       { [NativeAudioBridge]::PressKey([NativeAudioBridge]::VK_VOLUME_UP) }
            "volume/down"     { [NativeAudioBridge]::PressKey([NativeAudioBridge]::VK_VOLUME_DOWN) }
            "volume/mute"     { [NativeAudioBridge]::PressKey([NativeAudioBridge]::VK_VOLUME_MUTE) }
            default {
                $jsonResponse = '{"success": false, "error": "Unknown endpoint"}'
                $res.StatusCode = 404
            }
        }

        $buffer = [System.Text.Encoding]::UTF8.GetBytes($jsonResponse)
        $res.ContentType = "application/json"
        $res.ContentLength64 = $buffer.Length
        $res.OutputStream.Write($buffer, 0, $buffer.Length)
        $res.Close()
        continue
    }

    # Serve static index.html
    if (Test-Path $indexPath) {
        $bytes = [System.IO.File]::ReadAllBytes($indexPath)
        $res.ContentType = "text/html; charset=utf-8"
        $res.ContentLength64 = $bytes.Length
        $res.OutputStream.Write($bytes, 0, $bytes.Length)
        $res.Close()
    } else {
        $res.StatusCode = 404
        $res.Close()
    }
}
