# engine_window.ps1 - script for "Engine Window".

# Load utility functions
. .\scripts\utility.ps1
. .\scripts\interact.ps1
Start-Sleep -Seconds 1

# Configure Window
$Host.UI.RawUI.WindowTitle = "StudioChat - Engine Window"
$windowHandle = (Get-Process -Id $PID).MainWindowHandle
Move-Window -WindowHandle $windowHandle -BottomLeft

# Load configuration
$config = Load-Configuration -configPath ".\data\config.json"

$lm_studio_endpoint = $config.lm_studio_endpoint
$model_name = $config.model_name
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
    Write-Host $message
}

# Entry Point
Start-Sleep -Seconds 1
Clear-Host
Write-Separator
Write-Host "Engine Initialized."
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

            if ($message -eq "Roleplay Started.") {
                Write-Host "Roleplay Started."
                continue
            }

            if ($message.StartsWith("log: ")) {
                $logMessage = $message.Substring(5)
                Receive-LogMessage -message $logMessage
                continue
            }

            $response = Load-Response -responsePath ".\data\response.json"
            if ($message -eq "consolidate") {
                $eventsResponse = Handle-EventsPrompt -config $config -response $response

                Write-Host "Received response from LM Studio for events"
                Write-Host "Response: $eventsResponse"

                if ($eventsResponse -eq "No response from model!") {
                    Update-Response -key "recent_events" -value "No response from model!"
                } else {
                    Update-Response -key "recent_events" -value $eventsResponse
                }

                $historyResponse = Handle-HistoryPrompt -config $config -response $response

                Write-Host "Received response from LM Studio for history"
                Write-Host "Response: $historyResponse"

                if ($historyResponse -eq "No response from model!") {
                    Update-Response -key "scenario_history" -value "No response from model!"
                } else {
                    Update-Response -key "scenario_history" -value $historyResponse
                }

                $writer.WriteLine($eventsResponse)
                $writer.WriteLine($historyResponse)
            } else {
                $prompt = Create-Prompt -config $config -response $response

                Write-Host "Sending request to LM Studio..."
                Write-Host "Prompt: $prompt"

                $model_response = Generate-Response -message $prompt -lm_studio_endpoint $lm_studio_endpoint -model_name $model_name

                Write-Host "Received response from LM Studio"
                Write-Host "Response: $model_response"

                if ($model_response -eq "No response from model!") {
                    Update-Response -key "ai_npc_current" -value "No response from model!"
                } else {
                    # Filter the response for "ai_roleplaying"
                    $filtered_response = Filter-Response -response $model_response -type "ai_roleplaying"
                    Update-Response -key "ai_npc_current" -value $filtered_response

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