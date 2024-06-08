# Script: main2.ps1

# Set window title
$Host.UI.RawUI.WindowTitle = "StudioChat - Chat Window"

# Load configuration
$config = Get-Content -Raw -Path ".\config.json" | ConvertFrom-Json

$server_address = "localhost"
$server_port = 12345

Add-Type @"
    using System;
    using System.Runtime.InteropServices;

    public class Interop {
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool GetAsyncKeyState(int vKey);
    }
"@

function Get-MultiLineInput {
    $input = ""
    while ($true) {
        $key = $Host.UI.RawUI.ReadKey("IncludeKeyDown,NoEcho")

        if ($key.VirtualKeyCode -eq 13) { # Enter key
            if ([Interop]::GetAsyncKeyState(16)) { # Shift key
                $input += "`n"
                Write-Host "`n" -NoNewline
            } else {
                break
            }
        } elseif ($key.VirtualKeyCode -eq 8) { # Backspace key
            if ($input.Length -gt 0) {
                $input = $input.Substring(0, $input.Length - 1)
                Write-Host "`b `b" -NoNewline
            }
        } else {
            $input += $key.Character
            Write-Host $key.Character -NoNewline
        }
    }
    return $input
}

Write-Host "Chat Interface is running..."

while ($true) {
    Write-Host "--------------------------------------------------------"
    Write-Host "You: " -NoNewline
    $user_input = Get-MultiLineInput
    if ($user_input -in @('exit', 'quit')) {
        break
    }

    # Replace new lines with /n in user input
    $formatted_input = $user_input -replace "`n", '/n'

    try {
        $client = [System.Net.Sockets.TcpClient]::new($server_address, $server_port)
        $stream = $client.GetStream()
        $reader = [System.IO.StreamReader]::new($stream)
        $writer = [System.IO.StreamWriter]::new($stream)
        $writer.AutoFlush = $true

        $writer.WriteLine($formatted_input)

        $response = ""
        while ($true) {
            $line = $reader.ReadLine()
            if ($line -eq $null) { break }
            $response += $line + [environment]::NewLine
        }

        if ($response) {
            # Trim the last line if it is blank
            $responseLines = $response -split [environment]::NewLine
            if ($responseLines[-1] -eq "") {
                $responseLines = $responseLines[0..($responseLines.Length - 2)]
            }
            $response = [string]::Join([environment]::NewLine, $responseLines)

            Write-Host "--------------------------------------------------------"
            Write-Host "Model: $response"
        }

        $client.Close()
    } catch {
        Write-Host "Error communicating with the server: $_"
    }
}

Write-Host "Chat Interface closed."
