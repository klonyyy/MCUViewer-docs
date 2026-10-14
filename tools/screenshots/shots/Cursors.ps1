# Cursors on the zoomed-in "test" plot after a short run - VariableViewer/images/Cursors.png
# Leaves the plot zoomed in and the cursors on (Statistics.ps1 continues from here).
. "$PSScriptRoot\..\ShotLib.ps1"
Use-ShotInstance

Invoke-ShotClickUntil 107 721 { Test-ShotPixelLit 140 721 }    # select plot "test" in the tree
Invoke-Mcp "start_acquisition" | Out-Null
Start-Sleep -Seconds 3
Invoke-Mcp "stop_acquisition" | Out-Null
Start-Sleep -Seconds 1

Invoke-ShotDrag 1000 170 1140 944 -Button 1 -Steps 8 -WaitMs 1500    # right-drag box zoom to about 0.1 s
Set-ShotCheckbox 332 667 $true                                        # Cursors checkbox
Clear-ShotHover
Save-Shot "Cursors"
