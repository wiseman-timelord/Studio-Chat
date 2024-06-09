# main2.ps1


# Load utility functions
. .\utility.ps1
Start-Sleep -Seconds 1

# Configure Window
$Host.UI.RawUI.WindowTitle = "StudioChat - Chat Window"
$windowHandle = (Get-Process -Id $PID).MainWindowHandle
Move-Window -WindowHandle $windowHandle -Right

# Load configuration
$config = Load-Configuration
$server_address = "localhost"
$server_port = $config.script_comm_port

# Entry Point
Write-Host "...Chat Initialized."
while ($true) {
    Write-Separator
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

            Write-Separator
            Write-Host "Model: $response"
        }

        $client.Close()
    } catch {
        Write-Host "Error communicating with the server: $_"
    }
}

Write-Host "Chat window closed."
