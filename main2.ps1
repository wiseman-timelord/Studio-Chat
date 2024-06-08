# Set window title
$Host.UI.RawUI.WindowTitle = "StudioChat - Chat Window"

# Load configuration
$config = Get-Content -Raw -Path ".\config.json" | ConvertFrom-Json

$server_address = "localhost"
$server_port = 12345

Write-Host "Chat Interface is running..."

while ($true) {
    Write-Host "--------------------------------------------------------"
    $user_input = Read-Host "You"
    if ($user_input -in @('exit', 'quit')) {
        break
    }

    try {
        $client = [System.Net.Sockets.TcpClient]::new($server_address, $server_port)
        $stream = $client.GetStream()
        $reader = [System.IO.StreamReader]::new($stream)
        $writer = [System.IO.StreamWriter]::new($stream)
        $writer.AutoFlush = $true

        $writer.WriteLine($user_input)

        $response = ""
        while ($true) {
            $line = $reader.ReadLine()
            if ($line -eq $null) { break }
            $response += $line + [environment]::NewLine
        }

        if ($response) {
            # Trim the last line if it is blank
            $responseLines = $response -split [environment]::NewLine
            if ($responseLines[-1] -eq "") {
                $responseLines = $responseLines[0..($responseLines.Length - 2)]
            }
            $response = [string]::Join([environment]::NewLine, $responseLines)

            Write-Host "--------------------------------------------------------"
            Write-Host "Model: $response"
        }

        $client.Close()
    } catch {
        Write-Host "Error communicating with the server: $_"
    }
}

# Ensure the pipe is properly closed
$pipe.Dispose()
Write-Host "Pipe closed."
