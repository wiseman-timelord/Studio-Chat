# chat_window.ps1 - script for "Chat Window".

# Load utility functions and menu functions
. .\scripts\utility_general.ps1
. .\scripts\display_menus.ps1
. .\scripts\interact_model.ps1
Start-Sleep -Seconds 1

# Configure Window
Configure-Manage-Window -Action "configure" -windowTitle "StudioChat - Chat Window" -TopLeft

# Load configuration
$config = Load-Configuration -configPath ".\data\config_general.json"
$server_address = "localhost"
$server_port = $config.script_comm_port

# Chat interface
function Draw-ChatInterface {
    param (
        [hashtable]$config,
        [hashtable]$response,
        [int]$stage
    )

    Clear-Host
    Write-DualSeparator
    Write-Host "$($config.human_name):"
    if ($stage -ge 2 -or $response.human_current) {
        Write-Host "$($response.human_current)"
    } else {
        Write-Host ""
    }
    Write-Separator
    Write-Host "$($config.ai_npc_name):"
    if ($stage -eq 3 -or $response.ai_npc_current) {
        Write-Host "$($response.ai_npc_current)"
    } else {
        Write-Host ""
    }
    Write-Separator
    Write-Host "Recent Events:"
    if ($response.recent_events) {
        Write-Host "$($response.recent_events)"
    } else {
        Write-Host ""
    }
    Write-Separator
    Write-Host "Scenario History:"
    if ($response.scenario_history) {
        Write-Host "$($response.scenario_history)"
    } else {
        Write-Host ""
    }
    Write-DualSeparator
}


# Function to start chatting
function Start-Chatting {
    param (
        [hashtable]$config
    )

    $server_address = "localhost"
    $server_port = $config.script_comm_port

    # Initialize new session
    Update-Response -key "human_current" -value "$($config.human_name) met with $($config.ai_npc_name)."
    Update-Response -key "ai_npc_current" -value "$($config.ai_npc_name) met with $($config.human_name)."
    Update-Response -key "recent_events" -value "$($config.human_name) and $($config.ai_npc_name) noticed each other."
    Update-Response -key "scenario_history" -value "The roleplay started."

    while ($true) {
        $response = Load-Response
        Draw-ChatInterface -config $config -response $response -stage 1

        Write-Host "Your Input (Back=B, Exit=X): " -NoNewline
        $user_input = Read-Host
        if ($user_input -in @('B', 'b')) {
            break
        }

        if ($user_input -in @('X', 'x')) {
            Shutdown-Exit -server_port $server_port
            break
        }

        Update-Response -key "human_current" -value $user_input
        $response = Load-Response
        Draw-ChatInterface -config $config -response $response -stage 2

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
                $response = Load-Response -responsePath ".\data\model_response.json"
                Draw-ChatInterface -config $config -response $response -stage 3

                # Send consolidate prompt to engine_window
                try {
                    $client = [System.Net.Sockets.TcpClient]::new($server_address, $server_port)
                    $stream = $client.GetStream()
                    $reader = [System.IO.StreamReader]::new($stream)
                    $writer = [System.IO.StreamWriter]::new($stream)
                    $writer.AutoFlush = $true

                    $writer.WriteLine("consolidate")
                    $consolidateResponseText = ""
                    while ($true) {
                        $line = $reader.ReadLine()
                        if ($line -eq $null) { break }
                        $consolidateResponseText += $line + [environment]::NewLine
                    }

                    if ($consolidateResponseText) {
                        $consolidateResponseLines = $consolidateResponseText -split [environment]::NewLine
                        if ($consolidateResponseLines[-1] -eq "") {
                            $consolidateResponseLines = $consolidateResponseLines[0..($consolidateResponseLines.Length - 2)]
                        }
                        $consolidateResponseText = [string]::Join([environment]::NewLine, $consolidateResponseLines)

                        $recent_events = $consolidateResponseLines[0]
                        $scenario_history = $consolidateResponseLines[1]

                        Update-Response -key "recent_events" -value $recent_events
                        Update-Response -key "scenario_history" -value $scenario_history
                    }

                    $client.Close()
                } catch {
                    Write-Host "Error communicating with the server for consolidation: $_"
                }

                # Prompt for next user input
                Write-Host "Your Input (Back=B, Exit=X): " -NoNewline
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