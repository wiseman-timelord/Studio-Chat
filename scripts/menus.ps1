# menus.ps1 - script for menus/menu handling only

# Load utility functions
. .\scripts\utility.ps1

# Function to display and handle the main menu
function Show-MainMenu {
    param (
        [hashtable]$config
    )

    while ($true) {
        Clear-Host
        Write-Separator
        Write-Host "`n                Main Menu`n"
        Write-Host "             1. Start Chatting`n"
        Write-Host "             2. Configure Chat`n"
        Write-Separator
        $selection = Read-Host "Select; Choose Options = 1-2, Exit Program = X"

        switch ($selection) {
            "1" {
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
        [hashtable]$config
    )

    while ($true) {
        Clear-Host
        Write-Separator
        Write-Host "`n             Config Menu`n"
        Write-Host "           1. User Name ($($config['human_name']))`n"
        Write-Host "           2. Npc Name ($($config['ai_npc_name']))`n"
        Write-Host "           3. Rp Location ($($config['scenario_location']))`n"
        Write-Separator
        $selection = Read-Host "Select; Choose Options = 1-3, Back to Menu = B"

        switch ($selection) {
            "1" {
                $newUserName = Read-Host "Enter new User Name"
                Update-Configuration -key "human_name" -value $newUserName
                $config['human_name'] = $newUserName
            }
            "2" {
                $newNpcName = Read-Host "Enter new Npc Name"
                Update-Configuration -key "ai_npc_name" -value $newNpcName
                $config['ai_npc_name'] = $newNpcName
            }
            "3" {
                $newLocation = Read-Host "Enter new Rp Location"
                Update-Configuration -key "scenario_location" -value $newLocation
                $config['scenario_location'] = $newLocation
            }
            "B" { return $false }
            default { Write-Host "Invalid selection. Please choose a valid option." }
        }
    }
}

