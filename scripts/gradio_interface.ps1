# .\scripts\gradio_interface.ps1

# Import necessary modules
Import-Module -Name ".\scripts\utility_general.ps1"
Import-Module -Name ".\scripts\interact_model.ps1"

# Load configuration
$config = Manage-Configuration -action "load" -configPath ".\data\config_general.json"

# Function to handle chat interaction
function Handle-ChatMessage {
    param (
        [string]$message,
        [hashtable]$config,
        [hashtable]$response,
        [System.IO.StreamWriter]$writer
    )

    $prompt = Create-Prompt -config $config -response $response
    $model_response = Generate-Response -message $prompt -lm_studio_endpoint $config.lm_studio_endpoint -text_model_name $config.text_model_name

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

# Function to initialize TCP client
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

# Function to read TCP response
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

# Gradio interface setup
$chat_interface = {
    param (
        [string]$user_input
    )

    $server_address = "localhost"
    $server_port = $config.script_comm_port

    try {
        $tcpClient = Initialize-TcpClient -server_address $server_address -server_port $server_port
        $tcpClient.writer.WriteLine($user_input)
        $responseText = Read-TcpResponse -reader $tcpClient.reader

        if ($responseText) {
            Manage-Response -responsePath ".\data\model_response.json" -key "ai_npc_current" -value $responseText -update
            $response = Manage-Response -responsePath ".\data\model_response.json"
            Send-LogToEngine -message "Received response from engine" -server_port $config.script_comm_port
            return $response
        }
        $tcpClient.client.Close()
    } catch {
        $errorMessage = "Error communicating with the server: $_"
        Send-LogToEngine -message $errorMessage -server_port $config.script_comm_port
        return @{ ai_npc_current = "Error: Unable to communicate with the server. Please try again." }
    }
}

# Function to start the Gradio app
function Start-GradioApp {
    param (
        [scriptblock]$Interface,
        [string]$Title,
        [string]$Layout,
        [switch]$UserInputRow
    )

    # Import the Gradio module
    Import-Module -Name ".\scripts\gradio.psm1"

    # Define the Gradio interface
    $gradio_app = New-GradioApp -Interface $Interface -Title $Title -Layout $Layout -UserInputRow:$UserInputRow

    # Start the Gradio interface in a background job
    $job = Start-ThreadJob -ScriptBlock {
        param (
            [scriptblock]$Interface,
            [string]$Title,
            [string]$Layout,
            [switch]$UserInputRow
        )

        # Import the Gradio module
        Import-Module -Name ".\scripts\gradio.psm1"

        # Define the Gradio interface
        $gradio_app = New-GradioApp -Interface $Interface -Title $Title -Layout $Layout -UserInputRow:$UserInputRow

        # Start the Gradio interface
        try {
            $gradio_app.launch()
        } catch {
            $errorMessage = "Error launching Gradio interface: $_"
            Send-LogToEngine -message $errorMessage -server_port $config.script_comm_port
            Write-Host $errorMessage
            exit 1
        }
    } -ArgumentList $Interface, $Title, $Layout, $UserInputRow

    # Register a job event to handle termination
    Register-ObjectEvent -InputObject $job -EventName StateChanged -Action {
        if ($Sender.State -eq 'Completed' -or $Sender.State -eq 'Failed') {
            $job.StopJob()
        }
    }

    return $job
}

# Start the Gradio interface
$gradio_app_job = Start-GradioApp -Interface $chat_interface -Title "StudioChat" -Layout "2x2" -UserInputRow

# Ensure the Gradio job is stopped when the main script exits
$global:GradioJob = $gradio_app_job
$global:GradioJob.StopJob()