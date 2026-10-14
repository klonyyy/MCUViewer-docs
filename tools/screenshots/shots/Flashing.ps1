# Options -> Flashing - Flashing/images/Flashing.png (the "Test flash" button is not pressed - it would flash the target)
. "$PSScriptRoot\..\ShotLib.ps1"
Use-ShotInstance

Open-ShotFlashingSettings
Clear-ShotHover
Save-Shot "Flashing"
Close-ShotDialog
