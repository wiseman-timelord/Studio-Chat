# engine_window.ps1 - script for "Engine Window".

# Load utility functions
. .\scripts\utility_general.ps1
. .\scripts\interact_model.ps1
Start-Sleep -Seconds 1


# Global flag for log message control
$global:LogMessagesEnabled = $false

# Configure Window
Configure-Manage-Window -Action "configure" -windowTitle "StudioChat - Engine Window" -BottomLeft

# Load configuration
$config = Manage-Configuration -action "load" -configPath ".\data\config_general.json"

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

# Handle Chat Interaction
function Handle-ChatMessage {
    param (
        [string]$message,
        [hashtable]$config,
        [hashtable]$response,
        [System.IO.StreamWriter]$writer
    )

    $prompt = Create-Prompt -config $config -response $response
    Write-Host "Sending request to LM Studio..."
    $model_response = Generate-Response -message $prompt -lm_studio_endpoint $config.lm_studio_endpoint -text_model_name $config.text_model_name
    Write-Host "Received response from LM Studio"

    if ($model_response -eq "No response from model!") {
        Manage-Response -responsePath ".\data\model_response.json" -key "ai_npc_current" -value "No response from model!" -update
    } else {
        $filtered_response = Filter-Response -response $model_response -type "ai_roleplaying"
        Manage-Response -responsePath ".\data\model_response.json" -key "ai_npc_current" -value $filtered_response -update

        $responseLines = $filtered_response -split [environment]::NewLine
        foreach ($line in $responseLines) {
            $writer.WriteLine($line)
        }
    }
}



# Entry Point
Start-Sleep -Seconds 1
Clear-Host
Write-DualSeparator
Write-Host "Engine Initialized."
$global:LogMessagesEnabled = $true  # Enable log messages after initialization
Start-Sleep -Seconds 1
Write-Host "Loading menu."

try {
    while ($true) {
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
                $eventsResponse = Handle-Prompt -promptType "prompt_events" -config $config -response $response

                Write-Host "Received response from LM Studio for events"
                Write-Host "Response JSON: $($eventsResponse | ConvertTo-Json -Depth 10)"

                if ($eventsResponse -eq "No response from model!") {
                    Manage-Response -responsePath ".\data\model_response.json" -key "recent_events" -value "No response from model!" -update
                } else {
                    Manage-Response -responsePath ".\data\model_response.json" -key "recent_events" -value $eventsResponse -update
                }

                $historyResponse = Handle-Prompt -promptType "prompt_history" -config $config -response $response

                Write-Host "Received response from LM Studio for history"
                Write-Host "Response JSON: $($historyResponse | ConvertTo-Json -Depth 10)"

                if ($historyResponse -eq "No response from model!") {
                    Manage-Response -responsePath ".\data\model_response.json" -key "scenario_history" -value "No response from model!" -update
                } else {
                    Manage-Response -responsePath ".\data\model_response.json" -key "scenario_history" -value $historyResponse -update
                }

                $writer.WriteLine($eventsResponse)
                $writer.WriteLine($historyResponse)
            } else {
                $prompt = Create-Prompt -config $config -response $response

                Write-Host "Sending request to LM Studio..."

                $model_response = Generate-Response -message $prompt -lm_studio_endpoint $lm_studio_endpoint -text_model_name $text_model_name

                Write-Host "Received response from LM Studio"

                if ($model_response -eq "No response from model!") {
                    Manage-Response -responsePath ".\data\model_response.json" -key "ai_npc_current" -value "No response from model!" -update
                } else {
                    # Filter the response for "ai_roleplaying"
                    $filtered_response = Filter-Response -response $model_response -type "ai_roleplaying"
                    Manage-Response -responsePath ".\data\model_response.json" -key "ai_npc_current" -value $filtered_response -update

                    $responseLines = $filtered_response -split [environment]::NewLine
                    foreach ($line in $responseLines) {
                        $writer.WriteLine($line)
                    }
                }
            }
        }

        $client.Close()
    }
} finally {
    $listener.Stop()
    Write-Host "Server stopped."
}