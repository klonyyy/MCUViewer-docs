# Statistics window with a selected range - VariableViewer/images/Statistics.png
# Continues from Cursors.ps1 (zoomed-in "test" plot); turns statistics off again at the end.
. "$PSScriptRoot\..\ShotLib.ps1"
Use-ShotInstance

Set-ShotCheckbox 332 667 $false      # cursors off
Set-ShotCheckbox 332 693 $true       # statistics on - opens the Statistics window
Set-ShotCheckbox 601 193 $true       # "Select range" in the Statistics window
Clear-ShotHover
Save-Shot "Statistics"

Set-ShotCheckbox 601 193 $false
Set-ShotCheckbox 332 693 $false
Clear-ShotHover
