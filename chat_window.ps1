# chat_window.ps1 - script for "Chat Window".

# Load utility functions and menu functions
. .\scripts\utility_general.ps1
. .\scripts\display_menus.ps1
. .\scripts\interact_model.ps1
Start-Sleep -Seconds 1

# Configure Window
Configure-Manage-Window -Action "configure" -windowTitle "StudioChat - Chat Window" -TopLeft

# Load Jsons
$config = Manage-Configuration -action "load" -configPath ".\data\config_general.json"

$server_address = "localhost"
$server_port = $config.script_comm_port

function Initialize-Session {
    param (
        [hashtable]$config
    )
    # Initial session setup
    Manage-Response -responsePath ".\data\model_response.json" -key "human_current" -value "$($config.human_name) met with $($config.ai_npc_name)." -update
    Manage-Response -responsePath ".\data\model_response.json" -key "ai_npc_current" -value "$($config.ai_npc_name) met with $($config.human_name)." -update
    Manage-Response -responsePath ".\data\model_response.json" -key "recent_events" -value "$($config.human_name) and $($config.ai_npc_name) noticed each other." -update
    Manage-Response -responsePath ".\data\model_response.json" -key "scenario_history" -value "The roleplay started." -update
    Manage-Response -responsePath ".\data\model_response.json" -key "session_history" -value "" -update
}

function Initialize-TcpClient {
    param (
        [string]$server_address,
        [int]$server_port
    )
    $client = [System.Net.Sockets.TcpClient]::new($server_address, $server_port)
    $stream = $client.GetStream()
    $reader = [System.IO.StreamReader]::new($stream)
    $writer = [System.IO.StreamWriter]::new($stream)
    $writer.AutoFlush = $true
    return @{ client = $client; stream = $stream; reader = $reader; writer = $writer }
}

function Read-TcpResponse {
    param (
        [System.IO.StreamReader]$reader
    )
    $responseText = ""
    while ($true) {
        $line = $reader.ReadLine()
        if ($line -eq $null) { break }
        $responseText += $line + [environment]::NewLine
    }
    return $responseText.TrimEnd([environment]::NewLine)
}

function Send-ShutdownCommand {
    param (
        [string]$server_address,
        [int]$server_port
    )
    $tcpClient = Initialize-TcpClient -server_address $server_address -server_port $server_port
    $tcpClient.writer.WriteLine("shutdown")
    $tcpClient.client.Close()
}

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

    Initialize-Session -config $config

    while ($true) {
        $response = Manage-Response -responsePath ".\data\model_response.json"
        Draw-ChatInterface -config $config -response $response -stage 1

        Write-Host "Your Input (Back=B, Exit=X): " -NoNewline
        $user_input = Read-Host
        if ($user_input -in @('B', 'b', 'X', 'x')) {
            if ($user_input -in @('X', 'x')) {
                Shutdown-Exit -server_port $server_port
            }
            break
        }

        Manage-Response -responsePath ".\data\model_response.json" -key "human_current" -value $user_input -update
        $response = Manage-Response -responsePath ".\data\model_response.json"
        Draw-ChatInterface -config $config -response $response -stage 2

        try {
            $tcpClient = Initialize-TcpClient -server_address $server_address -server_port $server_port
            $tcpClient.writer.WriteLine($user_input)
            $responseText = Read-TcpResponse -reader $tcpClient.reader

            if ($responseText) {
                if ($responseText -eq "shutdown") {
                    Write-Host "Shutdown command received. Exiting..."
                    Send-ShutdownCommand -server_address $server_address -server_port $server_port
                    exit
                }

                Manage-Response -responsePath ".\data\model_response.json" -key "ai_npc_current" -value $responseText -update
                $response = Manage-Response -responsePath ".\data\model_response.json"
                Draw-ChatInterface -config $config -response $response -stage 3

                $consolidateResponseText = Send-ConsolidateCommand -server_address $server_address -server_port $server_port

                if ($consolidateResponseText) {
                    Update-ModelResponse -responseText $consolidateResponseText
                }

                Write-Host "Your Input (Back=B, Exit=X): " -NoNewline
            }
            $tcpClient.client.Close()
        } catch {
            Write-Host "Error communicating with the server: $_"
        }
    }
    Write-Host "Chat window closed."
}

# Main logic
Start-Sleep -Seconds 1
Clear-Host
Write-DualSeparator
Write-Host "Chat Window Initialized."
Start-Sleep -Seconds 1

while ($true) {
    $mainSelection = Show-MainMenu -config $config
    if (-not $mainSelection) {
        Shutdown-Exit -server_port $server_port
        break
    }
}
