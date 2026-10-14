# Variable Edit windows - VariableViewer/images/VariableProperties.png, ErrorBits.png, Fractional.png
. "$PSScriptRoot\..\ShotLib.ps1"
Use-ShotInstance

Open-ShotVariableEdit 358            # test.frac_i16
Save-Shot "VariableProperties"
Close-ShotDialog

Open-ShotVariableEdit 228            # ErrorOvervoltage - test.errorWord >> 5 & 0x1
Save-Shot "ErrorBits"
Close-ShotDialog

Open-ShotVariableEdit 384            # test.frac_i16_FR - copy of test.frac_i16 interpreted as fixed point
Save-Shot "Fractional"
Close-ShotDialog
