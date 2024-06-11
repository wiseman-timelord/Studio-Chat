# interact_model.ps1 - Interactions with LM Studio

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
    $response.PSObject.Properties.Name | ForEach-Object { $hashtable[$_] = $response."$_" }
    Write-Host "Loaded: $responsePath"

    if ($update) {
        $response[$key] = $value
        $response | ConvertTo-Json -Depth 10 | Set-Content -Path $responsePath
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
        [string]$model_name,
        [int]$maxRetries = 3
    )

    $payload = @{
        model = $model_name
        messages = @(@{ role = "user"; content = $message })
    } | ConvertTo-Json

    for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
        try {
            Write-Host "Sending request to LM Studio (Attempt $attempt)..."
            Write-Host "Payload: $payload" # Show the JSON payload being sent

            $response = Invoke-RestMethod -Uri $lm_studio_endpoint -Method Post -Body $payload -ContentType "application/json"
            Write-Host "Received response from LM Studio"
            Write-Host "Raw Response: $($response | ConvertTo-Json -Depth 10)" # Show the JSON response received
            
            $content = $response.choices[0].message.content -replace "`n", [environment]::NewLine

            # Check if the content is empty or contains only non-alphanumeric characters
            if (-not [string]::IsNullOrEmpty($content) -and $content -match "\w") {
                return $content
            }

            Write-Host "No Content Produced!"
            Start-Sleep -Seconds 2  # Wait before retrying
        } catch {
            Write-Host "Error communicating with LM Studio: $_"
            Start-Sleep -Seconds 2  # Wait before retrying
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

    $model_response = Generate-Response -message $prompt -lm_studio_endpoint $config.lm_studio_endpoint -model_name $config.model_name

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
