# Recorder - Recorder/images/RecorderSettings.png and RecorderUsage.png.
# Needs the MCUViewer_test firmware (recorderStep() in the 100 kHz interrupt). The temporary recorder group is
# removed and the recorder disabled again at the end.
. "$PSScriptRoot\..\ShotLib.ps1"
Use-ShotInstance

Show-ShotVarViewer
Invoke-Mcp "set_recorder_enabled" @{ enabled = 1 } | Out-Null

Open-ShotAcquisitionSettings
Invoke-ShotClick 501 596 -WaitMs 3000            # Detect recorder
Clear-ShotHover
Save-Shot "RecorderSettings" | Out-Null
Close-ShotDialog

Invoke-Mcp "add_group" @{ name = "recorder group"; type = "recorder" } | Out-Null
Invoke-Mcp "add_plot" @{ group = "recorder group"; name = "sine"; type = "curve" } | Out-Null
Invoke-Mcp "add_variable_to_plot" @{ group = "recorder group"; plot = "sine"; variables = '["test.a","test.b"]' } | Out-Null
Invoke-Mcp "set_active_group" @{ name = "recorder group" } | Out-Null
Invoke-Mcp "set_recorder_mode" @{ mode = "single" } | Out-Null
Invoke-Mcp "set_recorder_trigger" @{ source_variable = "test.a"; edge = "rising"; value = 0.2; pre_trigger_samples = 2000; enabled = 1 } | Out-Null

Invoke-Mcp "start_acquisition" | Out-Null
Start-Sleep -Seconds 5                             # single mode - one triggered buffer
Invoke-Mcp "stop_acquisition" | Out-Null
Start-Sleep -Seconds 1
# expand the recorder group (third row of the tree) so its plot is visible
for ($i = 0; $i -lt 3 -and -not (Test-ShotPixelLit 48 747); $i++) { Invoke-ShotClick 116 721 -Double -WaitMs 700 }
Clear-ShotHover
Save-Shot "RecorderUsage" | Out-Null

Invoke-Mcp "set_active_group" @{ name = "new group0" } | Out-Null
Invoke-Mcp "remove_group" @{ name = "recorder group" } | Out-Null
Invoke-Mcp "set_recorder_enabled" @{ enabled = 0 } | Out-Null
