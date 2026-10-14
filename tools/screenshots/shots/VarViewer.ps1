# Main Var Viewer window with data from a short run - VariableViewer/images/VarViewer.png
. "$PSScriptRoot\..\ShotLib.ps1"
Use-ShotInstance

Invoke-Mcp "start_acquisition" | Out-Null
Start-Sleep -Seconds 3
Invoke-Mcp "stop_acquisition" | Out-Null
Start-Sleep -Seconds 1

Invoke-ShotClickUntil 107 721 { Test-ShotPixelLit 140 721 }    # select plot "test" in the tree
Clear-ShotHover
Save-Shot "VarViewer"
