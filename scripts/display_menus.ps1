# display_menus.ps1 - script for menus/menu handling only

# Load utility functions
. .\scripts\utility_general.ps1
. .\scripts\interact_model.ps1

# Function to display and handle the main menu
function Show-MainMenu {
    param (
        [hashtable]$config
    )

    # Log when the main menu is accessed
    Send-LogToEngine -message "Accessed: Main Menu" -server_port $config.script_comm_port

    while ($true) {
        Clear-Host
        Write-DualSeparator
        Write-Host "`n`n`n`n                         Main Menu"
        Write-Host "                         ---------`n"
        Write-Host "                    1. Start Chatting`n"
        Write-Host "                    2. Configure Chat`n"
        Write-Host "                    3. Configure Model`n`n`n`n"
        Write-DualSeparator
        $selection = Read-Host "Select; Choose Options = 1-3, Exit Program = X"

        switch ($selection) {
            "1" {
                Send-LogToEngine -message "Selected: Start Chatting" -server_port $config.script_comm_port
                # Log roleplay start only when actually starting
                $client = [System.Net.Sockets.TcpClient]::new("localhost", $config.script_comm_port)
                $stream = $client.GetStream()
                $writer = [System.IO.StreamWriter]::new($stream)
                $writer.AutoFlush = $true
                $writer.WriteLine("Roleplay Started.")
                $client.Close()

                Start-Chatting -config $config
                return $true
            }
            "2" {
                while ($true) {
                    $configSelection = Show-ConfigMenu -config $config
                    if (-not $configSelection) {
                        break
                    }
                }
            }
            "3" {
                while ($true) {
                    $configModelSelection = Show-ConfigModelMenu -config $config
                    if (-not $configModelSelection) {
                        break
                    }
                }
            }
            "X" { 
                Shutdown-Exit -server_port $config.script_comm_port
                return $false 
            }
            default { Write-Host "Invalid selection. Please choose a valid option." }
        }
    }
}


# Function to display and handle the configuration menu
function Show-ConfigMenu {
    param (
        [hashtable]$config,
        [string]$configPath = ".\data\config_general.json"
    )

    # Log when the config menu is accessed
    Send-LogToEngine -message "Accessed: Config Menu" -server_port $config.script_comm_port

    while ($true) {
        Clear-Host
        Write-DualSeparator
        Write-Host "`n                       Config Menu"
        Write-Host "                       -----------`n"
        Write-Host "                 1. User Name ($($config['human_name']))`n"
        Write-Host "                 2. Npc Name ($($config['ai_npc_name']))`n"
        Write-Host "                 3. Rp Location ($($config['scenario_location']))`n"
        Write-DualSeparator
        $selection = Read-Host "Select; Choose Options = 1-3, Back to Menu = B"

        switch ($selection) {
            "1" {
                $newUserName = Read-Host "Enter new User Name"
                $config['human_name'] = $newUserName
            }
            "2" {
                $newNpcName = Read-Host "Enter new Npc Name"
                $config['ai_npc_name'] = $newNpcName
            }
            "3" {
                $newLocation = Read-Host "Enter new Rp Location"
                $config['scenario_location'] = $newLocation
            }
            "B" {
                Manage-Configuration -action "save" -config $config
                $global:Config = Manage-Configuration -action "load" -configPath $configPath
                return $false
            }
            default { Write-Host "Invalid selection. Please choose a valid option." }
        }
    }
}

function Show-ConfigModelMenu {
    param (
        [hashtable]$config,
        [string]$configPath = ".\data\config_general.json"
    )

    # Log when the model config menu is accessed
    Send-LogToEngine -message "Accessed: Config Model Menu" -server_port $config.script_comm_port

    while ($true) {
        Clear-Host
        Write-DualSeparator
        Write-Host "`n`n`n`n`n                    Config Model Menu"
        Write-Host "                    -----------------`n"
        Write-Host "                 1. Select Model`n"
        Write-Host "                 2. Context Length ($($config['context_used']))`n`n`n`n`n"
        Write-DualSeparator
        $selection = Read-Host "Select; Choose Options = 1-2, Back to Menu = B"

        switch ($selection) {
            "1" {
                $modelSelection = Show-ModelMenu -config $config
                if (-not $modelSelection) {
                    break
                }
            }
            "2" {
                $newContextLength = Read-Host "Enter new Context Length"
                if ($newContextLength -match '^\d+$') {
                    $config['context_used'] = [int]$newContextLength
                    Set-ContextLength -contextLength $newContextLength
                    Manage-Configuration -action "save" -config $config
                    $global:Config = Manage-Configuration -action "load" -configPath $configPath
                    Write-Host "Context Length set to $newContextLength."
                    Start-Sleep -Seconds 2
                } else {
                    Write-Host "Invalid input. Please enter a numeric value."
                }
            }
            "B" {
                Manage-Configuration -action "save" -config $config
                $global:Config = Manage-Configuration -action "load" -configPath $configPath
                return $false
            }
            default { Write-Host "Invalid selection. Please choose a valid option." }
        }
    }
}


function Show-ModelMenu {
    param (
        [hashtable]$config,
        [string]$configPath = ".\data\config_general.json"
    )

    # Log when the model menu is accessed
    Send-LogToEngine -message "Accessed: Model Menu" -server_port $config.script_comm_port

    $models = Get-ModelsFromServer

    while ($true) {
        Clear-Host
        Write-DualSeparator
        Write-Host "`n                       Model Menu"
        Write-Host "                       ----------`n"

        for ($i = 0; $i -lt $models.data.Count; $i++) {
            $modelParts = $models.data[$i].id -split '/'
            $displayName = "$($modelParts[0])/$($modelParts[1])"
            Write-Host "             $($i+1). $displayName`n"
        }
        Write-DualSeparator
        $selection = Read-Host "Select a model by number, Back to Menu = B"

        if ($selection -in @('B', 'b')) {
            return $false
        }

        if ($selection -gt 0 -and $selection -le $models.data.Count) {
            $selectedModel = $models.data[$selection - 1].id
            $config['model_name'] = $selectedModel
            Manage-Configuration -action "save" -config $config
            $global:Config = Manage-Configuration -action "load" -configPath $configPath
            Write-Host "Model $displayName selected."
            Start-Sleep -Seconds 2
            return $true
        } else {
            Write-Host "Invalid selection. Please choose a valid option."
        }
    }
}

function Set-ContextLength {
    param (
        [int]$contextLength
    )

    # Define the URL for the config endpoint
    $url = "http://localhost:1234/v1/config"

    # Create the configuration payload
    $payload = @{
        n_ctx = $contextLength
    } | ConvertTo-Json

    # Send the POST request with the configuration payload
    try {
        $response = Invoke-RestMethod -Uri $url -Method Post -Body $payload -ContentType "application/json"
        Write-Host "Context length set successfully."
    } catch {
        Write-Host "Failed to set context length: $_"
    }
}
