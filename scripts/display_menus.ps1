# `.\scripts\interact_model.ps1` - Interactions with LM Studio

# Request Response (chat window)
function Update-ModelResponse {
    param (
        [string]$responseText
    )
    $responseLines = $responseText -split [environment]::NewLine
    if ($responseLines[-1] -eq "") {
        $responseLines = $responseLines[0..($responseLines.Length - 2)]
    }
    $responseText = [string]::Join([environment]::NewLine, $responseLines)

    $recent_events = $responseLines[0]
    $scenario_history = $responseLines[1]

    Manage-Response -responsePath ".\data\model_response.json" -key "recent_events" -value $recent_events -update
    Manage-Response -responsePath ".\data\model_response.json" -key "scenario_history" -value $scenario_history -update
}

# Function to display main menu
function Show-MainMenu {
    param (
        [hashtable]$config
    )

    while ($true) {
        Clear-Host
        Write-Host "================================================================================================================"
        Write-Host "                     Main Menu"
        Write-Host "================================================================================================================"
        Write-Host "1. Start Roleplaying"
        Write-Host "2. Configure Settings"
        Write-Host "3. Exit"
        Write-Host "----------------------------------------------------------------------------------------------------------------"
        Write-Host "Select an option by number:"

        $selectedOption = Read-Host

        switch ($selectedOption) {
            "1" {
                return $true
            }
            "2" {
                # Implement settings configuration logic here
                Write-Host "Settings configured."
            }
            "3" {
                return $false
            }
            default {
                Write-Host "Invalid selection. Please try again."
                Start-Sleep -Seconds 2
            }
        }
    }
}

# Function to display color theme menu and apply selected theme
function Show-ColorThemeMenu {
    param (
        [hashtable]$config
    )

    $colorThemes = @{
        1 = "SolarizedDark"
        2 = "GruvboxDark"
        3 = "Monokai"
        4 = "DarkGreyWhite"
    }

    while ($true) {
        Clear-Host
        Write-Host "================================================================================================================"
        Write-Host "                     Color Theme Menu"
        Write-Host "================================================================================================================"
        Write-Host "1. SolarizedDark"
        Write-Host "2. GruvboxDark"
        Write-Host "3. Monokai"
        Write-Host "4. DarkGreyWhite"
        Write-Host "----------------------------------------------------------------------------------------------------------------"
        Write-Host "Select a color theme by number, Back to Menu = B:"

        $selectedThemeKey = Read-Host

        if ($selectedThemeKey -eq "B") {
            return $false
        }

        if ($colorThemes.ContainsKey($selectedThemeKey)) {
            Apply-ColorTheme -theme $colorThemes[$selectedThemeKey]
            return $true
        } else {
            Write-Host "Invalid selection. Please try again."
            Start-Sleep -Seconds 2
        }
    }
}

# Function to apply selected color theme
function Apply-ColorTheme {
    param (
        [string]$theme
    )

    # Apply the selected theme
    switch ($theme) {
        "SolarizedDark" {
            # Apply SolarizedDark theme settings
            # Example: Set-ConsoleColor -ForegroundColor DarkBlue -BackgroundColor White
        }
        "GruvboxDark" {
            # Apply GruvboxDark theme settings
            # Example: Set-ConsoleColor -ForegroundColor DarkGreen -BackgroundColor Black
        }
        "Monokai" {
            # Apply Monokai theme settings
            # Example: Set-ConsoleColor -ForegroundColor Magenta -BackgroundColor DarkGray
        }
        "DarkGreyWhite" {
            # Apply DarkGreyWhite theme settings
            # Example: Set-ConsoleColor -ForegroundColor White -BackgroundColor DarkGray
        }
        default {
            Write-Host "Invalid theme selected."
        }
    }
}

# Request Consolidate (Chat Window)
function Send-ConsolidateCommand {
    param (
        [string]$server_address,
        [int]$server_port
    )
    $tcpClient = Initialize-TcpClient -server_address $server_address -server_port $server_port
    $tcpClient.writer.WriteLine("consolidate")
    $consolidateResponseText = Read-TcpResponse -reader $tcpClient.reader
    $tcpClient.client.Close()
    return $consolidateResponseText
}

# Request Consolidation (engine window)
function Handle-Consolidation {
    param (
        [hashtable]$config,
        [hashtable]$response,
        [System.IO.StreamWriter]$writer
    )

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
}


# Function to load or update response data
function Manage-Response {
    param (
        [string]$key = $null,
        [string]$value = $null,
        [string]$responsePath = ".\data\model_response.json",
        [switch]$update
    )

    $response = Get-Content -Raw -Path $responsePath | ConvertFrom-Json
    $hashtable = @{}
    foreach ($property in $response.PSObject.Properties) {
        $hashtable[$property.Name] = $property.Value
    }
    Write-Host "Loaded: $responsePath"

    if ($update) {
        $hashtable[$key] = $value
        $hashtable | ConvertTo-Json -Depth 10 | Set-Content -Path $responsePath
        Write-Host "Updated: $responsePath"
    }

    return $hashtable
}

# Process txt prompt
function Get-ProcessedPrompt {
    param (
        [string]$filePath
    )

    $content = Get-Content -Path $filePath -Raw
    $processedContent = $content -replace "(`n|`r`n)+", "\n" -replace "`n", "\n"
    return $processedContent
}

# Function to generate response from LM Studio with retries
function Generate-Response {
    param (
        [string]$message,
        [string]$lm_studio_endpoint,
        [string]$text_model_name,
        [int]$maxRetries = 3
    )

    $payload = @{
        model = $text_model_name
        messages = @(@{ role = "user"; content = $message })
    } | ConvertTo-Json

    for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
        try {
            Write-Host "Sending request to LM Studio (Attempt $attempt)..."
            $response = Invoke-RestMethod -Uri $lm_studio_endpoint -Method Post -Body $payload -ContentType "application/json"
            $content = $response.choices[0].message.content -replace "`n", [environment]::NewLine

            if (-not [string]::IsNullOrEmpty($content) -and $content -match "\w") {
                return $content
            }

            Write-Host "No Content Produced!"
            Start-Sleep -Seconds 2
        } catch {
            Write-Host "Error communicating with LM Studio: $_"
            Start-Sleep -Seconds 2
        }
    }

    Write-Host "No valid response after $maxRetries attempts."
    return 'No response from model!'
}

# Function to create prompt
function Create-Prompt {
    param (
        [hashtable]$config,
        [hashtable]$response
    )

    $promptTemplate = Get-ProcessedPrompt -filePath ".\data\prompt_converse.txt"
    $prompt = $promptTemplate -replace '\{human_name\}', $config.human_name `
                               -replace '\{ai_npc_name\}', $config.ai_npc_name `
                               -replace '\{scenario_location\}', $config.scenario_location `
                               -replace '\{human_current\}', $response.human_current `
                               -replace '\{recent_events\}', $response.recent_events

    $promptLength = $prompt.Length
    $tokensNeeded = [math]::Ceiling($promptLength * 1.25)
    $contextUsed = $tokensNeeded * $config.context_factor

    Set-ContextLength -contextLength $contextUsed

    return $prompt
}


# Handle events and history prompt.
function Handle-Prompt {
    param (
        [string]$promptType,
        [hashtable]$config,
        [hashtable]$response
    )

    $promptPath = ".\data\$($promptType).txt"
    $promptTemplate = Get-ProcessedPrompt -filePath $promptPath

    switch ($promptType) {
        "prompt_events" {
            $prompt = $promptTemplate -replace '\{human_name\}', $config.human_name `
                                      -replace '\{ai_npc_name\}', $config.ai_npc_name `
                                      -replace '\{human_current\}', $response.human_current `
                                      -replace '\{ai_npc_current\}', $response.ai_npc_current
        }
        "prompt_history" {
            $prompt = $promptTemplate -replace '\{recent_events\}', $response.recent_events `
                                      -replace '\{scenario_history\}', $response.scenario_history
        }
    }

    $prompt = $prompt -replace "\\n", "`n"

    $model_response = Generate-Response -message $prompt -lm_studio_endpoint $config.lm_studio_endpoint -text_model_name $config.text_model_name

    if ($model_response -eq "No response from model!") {
        return "No response from model!"
    }

    $filtered_response = Filter-Response -response $model_response -type "text_processing"

    return $filtered_response
}

# Function to filter the response based on the type
function Filter-Response {
    param (
        [string]$response,
        [string]$type
    )

    switch ($type) {
        "ai_roleplaying" {
            # Remove URLs
            $filtered_response = $response -replace "http\S+", ""

            # Remove specific unwanted characters
            $filtered_response = $filtered_response -replace "[<|!?\[\]()]", ""

            # Handle ".!"
            $filtered_response = $filtered_response -replace "\.\!", "."

            # Count the number of colons in the response
            $colon_count = ($filtered_response -split ":").Length - 1

            if ($colon_count -eq 1) {
                # If only one colon, select content after the colon up to the first period
                $filtered_response = $filtered_response -split ":", 2 | Select-Object -Last 1
                $filtered_response = $filtered_response -split "\.", 2 | Select-Object -First 1
            } elseif ($colon_count -gt 1) {
                # If multiple colons, select content after the second colon up to the following period
                $filtered_response = $filtered_response -split ":", 3 | Select-Object -Last 1
                $filtered_response = $filtered_response -split "\.", 2 | Select-Object -First 1
            }

            # Trim any additional blank lines
            $filtered_response = $filtered_response.Trim()
        }
        "text_processing" {
            $filtered_response = $response -split ":", 2 | Select-Object -Last 1
            $filtered_response = $filtered_response -split "`n", 2 | Select-Object -First 1
            $filtered_response = $filtered_response.Trim()
        }
        default {
            $filtered_response = $response.Trim()
        }
    }

    return $filtered_response
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
        Write-Host "Context length set to $contextLength tokens successfully."
    } catch {
        Write-Host "Failed to set context length: $_"
    }
}
