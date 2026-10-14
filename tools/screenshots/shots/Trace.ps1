# Trace Viewer - TraceViewer/images/TraceViewer.png (also used by TraceViewerChannels), TraceViewerControlPanel.png,
#   TraceErrors.png and TraceAcquisitionSettings.png.
# Needs the MCUViewer_test firmware: ITM channels 0/1 are digital (1 kHz / 5 kHz tasks), channel 4 carries test.triangle.
# The triangle runs at 10 Hz by default, which is too slow for the 80 ms viewport, so it is sped up to 200 Hz first
# (a RAM write through the Var Viewer - nothing is flashed; a target reset restores it).
. "$PSScriptRoot\..\ShotLib.ps1"
Use-ShotInstance

# Space toggles the acquisition of the shown tab - more reliable than clicking STOP while the app runs at 60 fps
function Start-StopTrace([int]$RunMs = 3000) {
    Send-ShotKey 0x20; Start-Sleep -Milliseconds $RunMs      # START
    Send-ShotKey 0x20; Start-Sleep -Milliseconds 1500        # STOP
    Invoke-ShotClick 592 860 -Double -WaitMs 800             # double-click the CH4 Y axis - fits it to the data
    Clear-ShotHover
}

function Set-TraceField([int]$Y, [string]$Text) {
    Invoke-ShotClick 385 $Y -WaitMs 300
    Set-ShotFieldText $Text
    Invoke-ShotClick 300 960 -WaitMs 500         # empty part of the left pane - applies the value
}

# --- speed up the triangle (Var Viewer write) ---
Show-ShotVarViewer
Invoke-Mcp "add_variable" @{ name = "test.triangleFrequency" } | Out-Null
Invoke-Mcp "refresh_variable_addresses" | Out-Null
Invoke-Mcp "start_acquisition" | Out-Null
Start-Sleep -Seconds 2
Invoke-Mcp "set_variable_value" @{ name = "test.triangleFrequency"; value = 200 } | Out-Null
Invoke-Mcp "stop_acquisition" | Out-Null
Invoke-Mcp "remove_variable" @{ name = "test.triangleFrequency" } | Out-Null
Start-Sleep -Seconds 1
Show-ShotTraceViewer

# --- acquisition settings: 80 ms viewport ---
Open-ShotAcquisitionSettings
Invoke-ShotClick 1092 432 -WaitMs 2500          # refresh the probe list - it is empty while the Var Viewer holds the probe
Invoke-ShotClick 745 294 -WaitMs 400
Set-ShotFieldText "80"
Invoke-ShotClick 660 700 -WaitMs 800
Clear-ShotHover
Save-Shot "TraceAcquisitionSettings" | Out-Null
Close-ShotDialog

# --- main view with CH4 selected ---
Invoke-ShotClick 100 678 -WaitMs 500            # select CH4 in the channel list
Start-StopTrace
Save-Shot "TraceViewer" | Out-Null

# --- trigger on CH4 (the level comes from the trigger line on the plot - 0 by default) ---
Invoke-ShotClick 380 263 -WaitMs 800            # trigger channel combo
Invoke-ShotClick 300 387 -WaitMs 600            # CH4
Send-ShotKey 0x20; Start-Sleep -Seconds 4       # START - stops by itself after the trigger
Clear-ShotHover
Save-Shot "TraceViewerControlPanel" | Out-Null
Invoke-ShotClick 380 263 -WaitMs 800            # the list now scrolls to CH4 - scroll it back up and pick OFF
Invoke-ShotWheel 380 330 -Notches 5
Invoke-ShotClick 300 287 -WaitMs 600

# --- prescaler close to the probe's SWO limit: error frames (below 6 the SWO clock exceeds the ST-Link's
#     24 MHz and the trace refuses to start) ---
Set-TraceField 211 "6"
Start-StopTrace
Save-Shot "TraceErrors" | Out-Null
Set-TraceField 211 "10"

# --- restore the triangle to its firmware default (10 Hz) ---
Show-ShotVarViewer
Invoke-Mcp "add_variable" @{ name = "test.triangleFrequency" } | Out-Null
Invoke-Mcp "refresh_variable_addresses" | Out-Null
Invoke-Mcp "start_acquisition" | Out-Null
Start-Sleep -Seconds 2
Invoke-Mcp "set_variable_value" @{ name = "test.triangleFrequency"; value = 10 } | Out-Null
Invoke-Mcp "stop_acquisition" | Out-Null
Invoke-Mcp "remove_variable" @{ name = "test.triangleFrequency" } | Out-Null
