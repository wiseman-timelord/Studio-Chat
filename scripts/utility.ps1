# utility.ps1 - Utility script for shared functions

# Artwork
function Write-Separator {
    Write-Host "`n--------------------------------------------------------`n"
}

# Artwork
function Write-DualSeparator {
    Write-Host "`n========================================================`n"
}

# Load configuration
function Load-Configuration {
    param (
        [string]$configPath = ".\data\config.json"
    )
    $config = Get-Content -Raw -Path $configPath | ConvertFrom-Json
    $hashtable = @{}
    $config.PSObject.Properties | ForEach-Object { $hashtable[$_.Name] = $_.Value }
    return $hashtable
}

# Update configuration
function Update-Configuration {
    param (
        [string]$key,
        [string]$value
    )
    $config = Load-Configuration -configPath ".\data\config.json"
    $config[$key] = $value
    $config | ConvertTo-Json | Set-Content -Path ".\data\config.json"
}

# Function to load response data
function Load-Response {
    param (
        [string]$responsePath = ".\data\response.json"
    )
    $response = Get-Content -Raw -Path $responsePath | ConvertFrom-Json
    $hashtable = @{}
    $response.PSObject.Properties.Name | ForEach-Object { $hashtable[$_] = $response."$_" }
    return $hashtable
}

# Function to update response data
function Update-Response {
    param (
        [string]$key,
        [string]$value,
        [string]$responsePath = ".\data\response.json"
    )
    $response = Load-Response -responsePath $responsePath
    if (-not $response) {
        $response = @{}
    }
    $response[$key] = $value
    $response | ConvertTo-Json -Depth 10 | Set-Content -Path $responsePath
}

Add-Type -AssemblyName System.Windows.Forms

Add-Type @"
using System;
using System.Runtime.InteropServices;

public struct RECT
{
    public int left;
    public int top;
    public int right;
    public int bottom;
}

public class pInvoke
{
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool GetWindowRect(IntPtr hWnd, ref RECT rect);
}
"@

function Move-Window {
    param (
        [System.IntPtr]$WindowHandle,
        [switch]$TopLeft,
        [switch]$BottomLeft
    )

    # Get the window bounds
    $rect = New-Object RECT
    [pInvoke]::GetWindowRect($WindowHandle, [ref]$rect)

    # Get the screen dimensions
    $screen = [System.Windows.Forms.Screen]::FromHandle($WindowHandle).WorkingArea

    # Calculate new dimensions and position
    $width = $screen.Width / 2
    $height = $screen.Height / 2

    if ($TopLeft) {
        $x = $screen.Left
        $y = $screen.Top
    } elseif ($BottomLeft) {
        $x = $screen.Left
        $y = $screen.Top + $height
    } else {
        $x = $rect.left
        $y = $rect.top
    }

    # Move and resize the window
    [pInvoke]::MoveWindow($WindowHandle, $x, $y, [int]$width, [int]$height, $true) | Out-Null
}

# Function to generate response from LM Studio
function Generate-Response {
    param (
        [string]$message,
        [string]$lm_studio_endpoint,
        [string]$model_name
    )

    $payload = @{
        model = $model_name
        messages = @(@{ role = "user"; content = $message })
    } | ConvertTo-Json

    try {
        Write-Host "Sending request to LM Studio..."
        $response = Invoke-RestMethod -Uri $lm_studio_endpoint -Method Post -Body $payload -ContentType "application/json"
        Write-Host "Received response from LM Studio"
        return $response.choices[0].message.content -replace "`n", [environment]::NewLine
    } catch {
        Write-Host "Error communicating with LM Studio: $_"
        return 'Error: Could not reach LM Studio.'
    }
}

Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class WindowApi
{
    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
    
    public const int WM_CLOSE = 0x0010;
}
"@

function Get-WindowHandle {
    param (
        [int]$ProcessId
    )

    $process = Get-Process -Id $ProcessId
    if ($process.MainWindowHandle -ne [IntPtr]::Zero) {
        return $process.MainWindowHandle
    }
    return [IntPtr]::Zero
}

function Close-Window {
    param (
        [int]$ProcessId
    )

    $windowHandle = Get-WindowHandle -ProcessId $ProcessId
    if ($windowHandle -ne [IntPtr]::Zero) {
        [WindowApi]::SendMessage($windowHandle, [WindowApi]::WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
    } else {
        Write-Host "Window with Process ID '$ProcessId' not found."
    }
}

function Shutdown-Exit {
    param (
        [string]$server_address = "localhost",
        [int]$server_port
    )

    try {
        $client = [System.Net.Sockets.TcpClient]::new($server_address, $server_port)
        $stream = $client.GetStream()
        $writer = [System.IO.StreamWriter]::new($stream)
        $writer.AutoFlush = $true

        $writer.WriteLine("shutdown")
        $client.Close()
    } catch {
        Write-Host "Error sending shutdown command: $_"
    }
    
    # Close the Engine Window by Process ID
    $engineProcessId = (Get-Process -Name "pwsh" | Where-Object { $_.MainWindowTitle -eq "StudioChat - Engine Window" }).Id
    Close-Window -ProcessId $engineProcessId
    
    # Close the Chat Window by Process ID
    $chatProcessId = (Get-Process -Name "pwsh" | Where-Object { $_.MainWindowTitle -eq "StudioChat - Chat Window" }).Id
    Close-Window -ProcessId $chatProcessId
}