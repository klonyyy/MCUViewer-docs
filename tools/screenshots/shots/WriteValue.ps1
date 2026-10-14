# Running acquisition with the "control" table plot - VariableViewer/images/WriteValue.png
. "$PSScriptRoot\..\ShotLib.ps1"
Use-ShotInstance

Invoke-ShotClickUntil 107 721 { Test-ShotPixelLit 140 721 }    # select plot "test" in the tree
Invoke-Mcp "start_acquisition" | Out-Null
Start-Sleep -Seconds 3
Clear-ShotHover
Save-Shot "WriteValue"
Invoke-Mcp "stop_acquisition" | Out-Null
Start-Sleep -Seconds 1
