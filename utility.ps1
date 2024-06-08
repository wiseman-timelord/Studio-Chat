function Load-Config {
    param (
        [string]$configPath
    )
    return Get-Content -Raw -Path $configPath | ConvertFrom-Json
}

function Handle-MultiLineContent {
    param (
        [string]$content
    )
    return $content -replace "`n", [environment]::NewLine
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
