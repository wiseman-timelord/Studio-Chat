# `.\scripts\display_menus.ps1` - Menus and python interface (not gradio)

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
        Write-Host $("".PadLeft(120, "="))
        Write-Host "    Main Menu"
        Write-Host $("".PadLeft(120, "="))
        Write-Host "`n`n`n`n`n`n`n"
		Write-Host "    1. Start Roleplaying`n"
        Write-Host "    2. Configure Roleplaying`n"
        Write-Host "    3. Configure Libraries`n"
        Write-Host "    4. Configure Colors"
        Write-Host "`n`n`n`n`n`n`n"
		Write-Host $("".PadLeft(120, "-"))
        $selectedOption = Read-Host -Prompt "Selection; Menu Options = 1-4, Exit Studio-Chat = X: "

        switch ($selectedOption) {
            "1" {
                return $true
            }
            "2" {
                Show-RoleplayingSettingsMenu -config $config
			}	
			"3" {
                Show-LibrarySettingsMenu -config $config
            }
            "4" {
                Show-ColorThemeMenu -config $config
            }
            "x" {
                return $false
            }
            default {
                Write-Host "Invalid selection. Please try again."
                Start-Sleep -Seconds 2
            }
        }
    }
}


# Show Roleplaying Menu
function Show-RoleplayingSettingsMenu {
    param (
        [hashtable]$config
    )

    while ($true) {
        Clear-Host
        Write-Host $("".PadLeft(120, "="))
        Write-Host "    Roleplaying Settings"
        Write-Host $("".PadLeft(120, "="))
        Write-Host "`n`n`n`n`n`n`n"
		Write-Host "    1. Scenario Location:"
		Write-Host "        `($($config.scenario_location)`)"
        Write-Host "    2. AI NPC Name:"
		Write-Host "        `($($config.ai_npc_name)`)"
        Write-Host "    3. Human Name:"
		Write-Host "        `($($config.human_name)`)"
        Write-Host "`n`n`n`n`n`n`n"
		Write-Host $("".PadLeft(120, "-"))
        $selectedOption = Read-Host -Prompt "Selection; Menu Options = 1-3, Navigate Back = B: "

        switch ($selectedOption) {
            "1" {
                $config.scenario_location = Read-Host "Enter new Scenario Location"
            }
            "2" {
                $config.ai_npc_name = Read-Host "Enter new AI NPC Name"
            }
            "3" {
                $config.human_name = Read-Host "Enter new Human Name"
            }
            "b" {
                Save-Configuration -config $config
                return
            }
            default {
                Write-Host "Invalid selection. Please try again."
                Start-Sleep -Seconds 2
            }
        }
    }
}

# Function to show the library settings menu
function Show-LibrarySettingsMenu {
    param (
        [hashtable]$config
    )

    while ($true) {
        Clear-Host
        Write-Host $("".PadLeft(120, "="))
        Write-Host "    Library Settings"
        Write-Host $("".PadLeft(120, "="))
        Write-Host "`n`n`n`n`n`n`n"
		Write-Host "    1. LM Studio Endpoint:"
		Write-Host "        `($($config.lm_studio_endpoint)`)"
        Write-Host "    2. LM Studio Communication Port: "
		Write-Host "        `($($config.comm_port_lmstudio)`)"
        Write-Host "    3. Max Context Length: $($config.context_factor)"
		Write-Host "        `($($config.context_factor`)"
		Write-Host "    4. Gradio Endpoint:"
		Write-Host "        `($($config.gradio_endpoint)`)"
        Write-Host "    5. Gradio Communication Port:"
		Write-Host "        `($($config.comm_port_gradio)`)"
        Write-Host "`n`n`n`n`n`n`n"
		Write-Host $("".PadLeft(120, "-"))
        $selectedOption = Read-Host -Prompt "Selection; Menu Options = 1-5, Navigate Back = B: "

        switch ($selectedOption) {
            "1" {
                $config.lm_studio_endpoint = Read-Host "Enter new LM Studio Endpoint"
            }
            "2" {
                $config.comm_port_lmstudio = Read-Host "Enter new LM Studio Communication Port"
            }
            "3" {
                $config.context_factor = Read-Host "Enter Model Max Context Length"
            }
            "4" {
                $config.gradio_endpoint = Read-Host "Enter new Gradio Endpoint"
            }
            "5" {
                $config.comm_port_gradio = Read-Host "Enter new Gradio Communication Port"
            }
            "b" {
                Save-Configuration -config $config
                return
            }
            default {
                Write-Host "Invalid selection. Please try again."
                Start-Sleep -Seconds 2
            }
        }
    }
}

# Display Color Scheme Menu
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
        Write-Host $("".PadLeft(120, "="))
        Write-Host "    Color Scheme Menu"
        Write-Host $("".PadLeft(120, "="))
        Write-Host "`n`n`n`n`n`n`n"
		Write-Host "    1. SolarizedDark"
        Write-Host "    2. GruvboxDark"
        Write-Host "    3. Monokai"
        Write-Host "    4. DarkGreyWhite"
        Write-Host "`n`n`n`n`n`n`n"
		Write-Host $("".PadLeft(120, "-"))
        $selectedThemeKey = Read-Host -Prompt "Selection; Menu Options = 1-4, Navigate Back = B: "

        if ($selectedThemeKey -eq "b") {
            return
        }

        if ($colorThemes.ContainsKey([int]$selectedThemeKey)) {
            Apply-ColorTheme -theme $colorThemes[[int]$selectedThemeKey]
            $config.color_theme = $colorThemes[[int]$selectedThemeKey]
            # Save the updated config here
            # Manage-Configuration -action "save" -configPath ".\data\config_general.json" -config $config
            Write-Host "Color Scheme Updated: $($colorThemes[[int]$selectedThemeKey])"
            Start-Sleep -Seconds 2
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

    switch ($theme) {
        "SolarizedDark" {
            $host.UI.RawUI.BackgroundColor = "DarkBlue"
            $host.UI.RawUI.ForegroundColor = "White"
        }
        "GruvboxDark" {
            $host.UI.RawUI.BackgroundColor = "Black"
            $host.UI.RawUI.ForegroundColor = "DarkGreen"
        }
        "Monokai" {
            $host.UI.RawUI.BackgroundColor = "DarkGray"
            $host.UI.RawUI.ForegroundColor = "Magenta"
        }
        "DarkGreyWhite" {
            $host.UI.RawUI.BackgroundColor = "DarkGray"
            $host.UI.RawUI.ForegroundColor = "White"
        }
        default {
            Write-Host "Invalid theme selected."
        }
    }

    Clear-Host
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
