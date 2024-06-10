# main1.ps1 - script for "Engine Window".

# Load utility functions
. .\utility.ps1
Start-Sleep -Seconds 1

# Configure Window
$Host.UI.RawUI.WindowTitle = "StudioChat - Engine Window"
$windowHandle = (Get-Process -Id $PID).MainWindowHandle
Move-Window -WindowHandle $windowHandle -Left

# Load configuration
$config = Load-Configuration

$lm_studio_endpoint = $config.lm_studio_endpoint
$model_name = $config.model_name
$server_port = $config.script_comm_port
$ai_npc_name = $config.ai_npc_name
$human_name = $config.human_name
$scenario_location = $config.scenario_location

# Start TCP server
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $server_port)
$listener.Start()

# Function to create prompt
function Create-Prompt {
    param (
        [hashtable]$config,
        [hashtable]$response
    )

    $prompt = @"
Your task is to respond to $($config.human_name) with one sentence of dialogue, followed by a one-sentence description of an action you take, and separate them with a comma, for example, '"I'm delighted to see you here, it's quite an unexpected pleasure!", $($config.ai_npc_name) says as he offers a warm smile to $($config.human_name).'.

The location is $($config.scenario_location), where $($config.ai_npc_name) and $($config.human_name) are present. $($config.human_name) just said '$($response.human_current)' to $($config.ai_npc_name).
"@
    return $prompt
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

            $response = Load-Response
            $prompt = Create-Prompt -config $config -response $response
            $model_response = Generate-Response -message $prompt -lm_studio_endpoint $lm_studio_endpoint -model_name $model_name

            $responseLines = $model_response -split [environment]::NewLine
            foreach ($line in $responseLines) {
                $writer.WriteLine($line)
            }
        }

        $client.Close()
    }
} finally {
    $listener.Stop()
    Write-Host "Server stopped."
}