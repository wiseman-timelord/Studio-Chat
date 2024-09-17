# `.\launch_engine.ps1` - script for Launch of Engine.

# Imports
. .\scripts\utility_general.ps1
. .\scripts\interact_model.ps1
. .\scripts\display_menus.ps1
Start-Sleep -Seconds 1

# Global flag for log message control
$global:LogMessagesEnabled = $false

# Configure Window
Configure-Manage-Window -Action "configure" -windowTitle "StudioChat - Engine Window"

# Load configuration
$config = Manage-Configuration -action "load" -configPath ".\data\config_general.json"

# Apply saved color theme
Apply-SavedColorTheme -config $config

$lm_studio_endpoint = $config.lm_studio_endpoint
$text_model_name = $config.text_model_name
$server_port = $config.script_comm_port
$ai_npc_name = $config.ai_npc_name
$human_name = $config.human_name
$scenario_location = $config.scenario_location

# Start TCP server
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $server_port)
$listener.Start()

# Function to handle log messages
function Receive-LogMessage {
    param (
        [string]$message
    )
    if ($global:LogMessagesEnabled) {
        Write-Host $message
    }
}

# Function to display waiting message
function Display-WaitingMessage {
    Clear-Host
    Write-Host "Waiting for Chat Window input..."
    Write-Host "Press 'B' to return to the Main Menu"
}

# Entry Point
Start-Sleep -Seconds 1
Write-DualSeparator
Write-Host "Engine Initialized."
$global:LogMessagesEnabled = $true  # Enable log messages after initialization
Start-Sleep -Seconds 1
Write-Host "Loading menu."

$isRoleplayingMode = $false

try {
    while ($true) {
        if (-not $isRoleplayingMode) {
            $menuResult = Show-MainMenu -config $config
            if ($menuResult -eq $true) {
                $isRoleplayingMode = $true
                Display-WaitingMessage
            } elseif ($menuResult -eq $false) {
                break
            }
        }

        try {
            if (-not $listener.Pending()) {
                if ($isRoleplayingMode) {
                    if ([Console]::KeyAvailable) {
                        $key = [Console]::ReadKey($true)
                        if ($key.Key -eq 'B') {
                            $isRoleplayingMode = $false
                            continue
                        }
                    }
                }
                Start-Sleep -Seconds 1
                continue
            }

            $client = $listener.AcceptTcpClient()
            $stream = $client.GetStream()
            $reader = [System.IO.StreamReader]::new($stream)
            $writer = [System.IO.StreamWriter]::new($stream)
            $writer.AutoFlush = $true

            $message = $reader.ReadLine()
            if ($message) {
                if ($message -eq "shutdown") {
                    Write-Host "Shutting Down."
                    Shutdown-Exit -server_port $server_port
                    break
                }

                if ($message.StartsWith("log: ")) {
                    $logMessage = $message.Substring(5)
                    Receive-LogMessage -message $logMessage
                    continue
                }

                $response = Manage-Response -responsePath ".\data\model_response.json"
                if ($message -eq "consolidate") {
                    Handle-Consolidation -config $config -response $response -writer $writer
                } else {
                    Handle-ChatMessage -message $message -config $config -response $response -writer $writer
                }

                if ($isRoleplayingMode) {
                    Display-WaitingMessage
                }
            }
        } catch {
            $errorMessage = "Error in main loop: $_"
            Write-Host $errorMessage
            Add-Content -Path ".\errors.log" -Value $errorMessage
        } finally {
            if ($null -ne $client) {
                $client.Close()
            }
        }
    }
} finally {
    $listener.Stop()
    Write-Host "Server stopped."
}