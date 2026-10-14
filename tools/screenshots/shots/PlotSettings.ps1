# Plot Edit window of the "control" table plot - VariableViewer/images/PlotSettings.png
. "$PSScriptRoot\..\ShotLib.ps1"
Use-ShotInstance

Invoke-ShotClick 118 695 -Double -WaitMs 900     # double-click "control" in the plot group tree
Invoke-ShotClick 660 700 -WaitMs 500             # inside the window - clears the nav frame of the name field
Clear-ShotHover
Save-Shot "PlotSettings"
Close-ShotDialog
