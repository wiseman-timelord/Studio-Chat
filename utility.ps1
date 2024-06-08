# utility.ps1

function Load-Config {
    param (
        [string]$configPath
    )
    return Get-Content -Raw -Path $configPath | ConvertFrom-Json
}

function Handle-MultiLineContent {
    param (
        [string]$content
    )
    return $content -replace "`n", [environment]::NewLine
}
