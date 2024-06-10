# main2.ps1 - script for "Chat Window".

# Load utility functions and menu functions
. .\utility.ps1
. .\menus.ps1
Start-Sleep -Seconds 1

# Configure Window
$Host.UI.RawUI.WindowTitle = "StudioChat - Chat Window"
$windowHandle = (Get-Process -Id $PID).MainWindowHandle
Move-Window -WindowHandle $windowHandle -Right

# Load configuration
$config = Load-Configuration
$server_address = "localhost"
$server_port = $config.script_comm_port

# Chat interface
function Draw-ChatInterface {
    param (
        [hashtable]$config,
        [hashtable]$response
    )

    Clear-Host
    Write-DualSeparator
    Write-Host "$($config.human_name):"
    Write-Host "$($response.human_current)"
    Write-Separator
    Write-Host "$($config.ai_npc_name):"
    Write-Host "$($response.ai_npc_current)"
    Write-DualSeparator

    if (-not $response.human_current) {
        Write-Host "Your Input (Back=B): " -NoNewline
    }
}

# Function to start chatting
function Start-Chatting {
    param (
        [hashtable]$config
    )

    $server_address = "localhost"
    $server_port = $config.script_comm_port

    # Clear the response values at the start of the chat
    Update-Response -key "human_current" -value ""
    Update-Response -key "ai_npc_current" -value ""

    while ($true) {
        $response = Load-Response
        Draw-ChatInterface -config $config -response $response

        $user_input = Read-Host
        if ($user_input -in @('B', 'b')) {
            break
        }

        if ($user_input -in @('exit', 'quit')) {
            break
        }

        Update-Response -key "human_current" -value $user_input

        try {
            $client = [System.Net.Sockets.TcpClient]::new($server_address, $server_port)
            $stream = $client.GetStream()
            $reader = [System.IO.StreamReader]::new($stream)
            $writer = [System.IO.StreamWriter]::new($stream)
            $writer.AutoFlush = $true

            $writer.WriteLine($user_input)
            $responseText = ""
            while ($true) {
                $line = $reader.ReadLine()
                if ($line -eq $null) { break }
                $responseText += $line + [environment]::NewLine
            }

            if ($responseText) {
                if ($responseText -eq "shutdown") {
                    Write-Host "Shutdown command received. Exiting..."
                    $client = [System.Net.Sockets.TcpClient]::new($server_address, $server_port)
                    $stream = $client.GetStream()
                    $writer = [System.IO.StreamWriter]::new($stream)
                    $writer.AutoFlush = $true

                    $writer.WriteLine("shutdown")
                    $client.Close()
                    Start-Sleep -Seconds 2 # Give time for the Engine Window to shutdown
                    exit
                }

                # Trim the last line if it is blank
                $responseLines = $responseText -split [environment]::NewLine
                if ($responseLines[-1] -eq "") {
                    $responseLines = $responseLines[0..($responseLines.Length - 2)]
                }
                $responseText = [string]::Join([environment]::NewLine, $responseLines)

                Update-Response -key "ai_npc_current" -value $responseText

                $response = Load-Response
                Draw-ChatInterface -config $config -response $response
            }

            $client.Close()
        } catch {
            Write-Host "Error communicating with the server: $_"
        }
    }
    Write-Host "Chat window closed."
}

# Main logic
Start-Sleep -Seconds 1
Clear-Host
Write-Separator
Write-Host "Chat Window Initialized."
Start-Sleep -Seconds 1

while ($true) {
    $mainSelection = Show-MainMenu -config $config
    if (-not $mainSelection) {
        Shutdown-Exit -server_port $server_port
        break
    }
}