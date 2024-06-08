# main1.ps1

# Import utility script
. .\utility.ps1

# Set window title
$Host.UI.RawUI.WindowTitle = "StudioChat - Engine Window"

# Load configuration
$config = Load-Config -configPath ".\config.json"

$lm_studio_endpoint = $config.lm_studio_endpoint
$model_name = $config.model_name
$server_port = 12345

# Function to generate response from LM Studio
function Generate-Response {
    param (
        [string]$message
    )

    $payload = @{
        model = $model_name
        messages = @(@{ role = "user"; content = $message })
    } | ConvertTo-Json

    try {
        Write-Host "Sending request to LM Studio..."
        $response = Invoke-RestMethod -Uri $lm_studio_endpoint -Method Post -Body $payload -ContentType "application/json"
        Write-Host "Received response from LM Studio"
        # Properly handle multi-line content
        return Handle-MultiLineContent -content $response.choices[0].message.content
    } catch {
        Write-Host "Error communicating with LM Studio: $_"
        return 'Error: Could not reach LM Studio.'
    }
}

# Start TCP server
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $server_port)
$listener.Start()
Write-Host "Engine is running and listening on port $server_port..."

try {
    while ($true) {
        $client = $listener.AcceptTcpClient()
        $stream = $client.GetStream()
        $reader = [System.IO.StreamReader]::new($stream)
        $writer = [System.IO.StreamWriter]::new($stream)
        $writer.AutoFlush = $true

        $message = $reader.ReadLine()
        if ($message) {
            # Replace /n with new lines before generating the response
            $message = $message -replace '/n', [environment]::NewLine
            $response = Generate-Response -message $message
            $responseLines = $response -split [environment]::NewLine
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
