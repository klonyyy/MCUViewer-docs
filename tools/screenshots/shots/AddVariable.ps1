# Right-click in the empty part of the variable table -> New -> Variable - VariableViewer/images/AddVariable.png
. "$PSScriptRoot\..\ShotLib.ps1"
Use-ShotInstance

Invoke-ShotClick 190 590 -Right -WaitMs 600
Invoke-ShotHover 237 602 -Hold 20 -WaitMs 800      # "New" opens its submenu
# hover "Variable" - a mouse highlight instead of the keyboard nav frame
Save-ShotWhen "AddVariable" 375 596 { param($c) Test-ShotBlue $c } { Invoke-ShotHover 335 603 -Hold 40 -WaitMs 300 }
Close-ShotDialog
Close-ShotDialog
