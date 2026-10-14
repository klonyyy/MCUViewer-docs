# test.errorWord dragged from the variable table onto the "control" table plot (captured mid-drag) -
#   VariableViewer/images/DragNDrop.png. It is dropped where it already is, so the project does not change.
. "$PSScriptRoot\..\ShotLib.ps1"
Use-ShotInstance

Invoke-ShotDrag 100 332 760 112 -Steps 12 -NoRelease -Hold 40 -WaitMs 2800
Save-Shot "DragNDrop"
Complete-ShotDrag 760 112
Clear-ShotHover
