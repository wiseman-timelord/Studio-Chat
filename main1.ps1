# main1.ps1


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

# Start TCP server
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $server_port)
$listener.Start()

# Entry Point
Write-Host "...Engine Initialized."
Write-Separator
try {
    while ($true) {
        $client = $listener.AcceptTcpClient()
        $stream = $client.GetStream()
        $reader = [System.IO.StreamReader]::new($stream)
        $writer = [System.IO.StreamWriter]::new($stream)
        $writer.AutoFlush = $true

        $message = $reader.ReadLine()
        if ($message) {
            $response = Generate-Response -message $message -lm_studio_endpoint $lm_studio_endpoint -model_name $model_name
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
