# Brings a freshly started instance (Start-ShotInstance on example_project/example.mcuv) into the state
# the other shot scripts start from: "new group0" active and expanded, acquisition stopped.
. "$PSScriptRoot\..\ShotLib.ps1"
Use-ShotInstance

Invoke-Mcp "stop_acquisition" | Out-Null
Invoke-Mcp "refresh_variable_addresses" | Out-Null
Invoke-Mcp "set_active_group" @{ name = "new group0" } | Out-Null
Start-Sleep -Milliseconds 500
Show-ShotVarViewer          # the last shown tab is restored from layout.ini
Expand-ShotGroup0
Clear-ShotHover
