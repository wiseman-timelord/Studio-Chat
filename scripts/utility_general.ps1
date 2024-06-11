# utility_general.ps1 - Utility script for shared functions

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

# Artwork
function Write-Separator {
    Write-Host "`n--------------------------------------------------------`n"
}

# Artwork
function Write-DualSeparator {
    Write-Host "`n========================================================`n"
}

# Send printed message for engine_window
function Send-LogToEngine {
    param (
        [string]$message,
        [string]$server_address = "localhost",
        [int]$server_port = 12345
    )

    try {
        $client = [System.Net.Sockets.TcpClient]::new($server_address, $server_port)
        $stream = $client.GetStream()
        $writer = [System.IO.StreamWriter]::new($stream)
        $writer.AutoFlush = $true

        $writer.WriteLine("log: $message")
        $client.Close()
    } catch {
        Write-Host "Error sending log message to engine window: $_"
    }
}

# Load configuration
function Load-Configuration {
    param (
        [string]$configPath = ".\data\config_general.json",
        [int]$server_port = 12345
    )
    $config = Get-Content -Raw -Path $configPath | ConvertFrom-Json
    $hashtable = @{}
    $config.PSObject.Properties | ForEach-Object { $hashtable[$_.Name] = $_.Value }
    Send-LogToEngine -message "Loaded: $configPath" -server_port $server_port
    return $hashtable
}

# Save configuration
function Save-Configuration {
    param (
        [hashtable]$config,
        [string]$configPath = ".\data\config_general.json",
        [int]$server_port = 12345
    )
    $config | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath
    Send-LogToEngine -message "Updated: $configPath" -server_port $server_port
}

# Update configuration
function Update-Configuration {
    param (
        [hashtable]$config,
        [string]$key,
        [string]$value,
        [int]$server_port = 12345
    )
    $config[$key] = $value
    Save-Configuration -config $config -server_port $server_port
}

function Configure-Manage-Window {
    param (
        [string]$Action,
        [System.IntPtr]$WindowHandle = [System.IntPtr]::Zero,
        [string]$windowTitle = $null,
        [switch]$TopLeft,
        [switch]$BottomLeft
    )

    switch ($Action) {
        "configure" {
            $Host.UI.RawUI.WindowTitle = $windowTitle
            $WindowHandle = (Get-Process -Id $PID).MainWindowHandle
            Configure-Manage-Window -Action "move" -WindowHandle $WindowHandle -TopLeft:$TopLeft -BottomLeft:$BottomLeft
        }
        "move" {
            if ($WindowHandle -eq [System.IntPtr]::Zero) {
                throw "WindowHandle must be provided for move action."
            }
            $rect = New-Object RECT
            [pInvoke]::GetWindowRect($WindowHandle, [ref]$rect)
            $screen = [System.Windows.Forms.Screen]::FromHandle($WindowHandle).WorkingArea
            $width = $screen.Width / 2
            $height = $screen.Height / 2
            $x = $TopLeft ? $screen.Left : ($BottomLeft ? $screen.Left : $rect.left)
            $y = $TopLeft ? $screen.Top : ($BottomLeft ? $screen.Top + $height : $rect.top)
            [pInvoke]::MoveWindow($WindowHandle, $x, $y, [int]$width, [int]$height, $true) | Out-Null
        }
        "close" {
            if ($WindowHandle -eq [System.IntPtr]::Zero) {
                throw "WindowHandle must be provided for close action."
            }
            [WindowApi]::SendMessage($WindowHandle, [WindowApi]::WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
        }
    }
}

function Get-WindowHandle {
    param (
        [int]$ProcessId
    )

    $process = Get-Process -Id $ProcessId
    return $process.MainWindowHandle
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

    $engineProcessId = (Get-Process -Name "pwsh" | Where-Object { $_.MainWindowTitle -eq "StudioChat - Engine Window" }).Id
    Configure-Manage-Window -WindowHandle (Get-WindowHandle -ProcessId $engineProcessId) -Action "close"

    $chatProcessId = (Get-Process -Name "pwsh" | Where-Object { $_.MainWindowTitle -eq "StudioChat - Chat Window" }).Id
    Configure-Manage-Window -WindowHandle (Get-WindowHandle -ProcessId $chatProcessId) -Action "close"
}