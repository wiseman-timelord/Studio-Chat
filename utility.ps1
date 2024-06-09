# Utility script for shared functions

# Artwork
function Write-Separator {
    Write-Host "`n--------------------------------------------------------`n"
}

# Load configuration
function Load-Configuration {
    param (
        [string]$configPath = ".\config.json"
    )
    return Get-Content -Raw -Path $configPath | ConvertFrom-Json
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
        [switch]$Left,
        [switch]$Right
    )

    # Get the window bounds
    $rect = New-Object RECT
    [pInvoke]::GetWindowRect($WindowHandle, [ref]$rect)

    # Get the screen dimensions
    $screen = [System.Windows.Forms.Screen]::FromHandle($WindowHandle).WorkingArea

    # Calculate new dimensions and position
    $width = $screen.Width / 2
    $height = $screen.Height

    if ($Left) {
        $x = $screen.Left
    } elseif ($Right) {
        $x = $screen.Left + $width
    } else {
        $x = $rect.left
    }

    $y = $screen.Top

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
