# Animated demos - Introduction/images/VariableViewer.gif and Recorder/images/RecorderDemo.gif.
# Builds temporary "demo" groups in the example project, records them while test.step (the speed of the
# test.a/b/c sines, ~800 Hz per unit) is written through MCP - like a user typing in the table - and removes
# everything again at the end. Only a RAM variable of the MCUViewer_test firmware is written.
# Note: variables added through MCP get a random colour, which is why the demo uses only already imported ones
# for its curves.
. "$PSScriptRoot\..\ShotLib.ps1"
Use-ShotInstance

$repo = Resolve-Path "$PSScriptRoot\..\..\.."

function Write-Value([string]$Name, [double]$Value) { Invoke-Mcp "set_variable_value" @{ name = $Name; value = $Value } | Out-Null }
function Remove-Demo {
    Invoke-Mcp "set_active_group" @{ name = "new group0" } | Out-Null
    foreach ($g in "demo", "recorder demo") { try { Invoke-Mcp "remove_group" @{ name = $g } | Out-Null } catch {} }
    try { Invoke-Mcp "remove_variable" @{ name = "test.step" } | Out-Null } catch {}
}

Remove-Demo
Invoke-Mcp "add_variable" @{ name = "test.step" } | Out-Null
Invoke-Mcp "refresh_variable_addresses" | Out-Null

# --- Var Viewer demo: a table to write from, the sines as curves and bars ---
Invoke-Mcp "add_group" @{ name = "demo"; type = "sampling" } | Out-Null
Invoke-Mcp "add_plot" @{ group = "demo"; name = "control"; type = "table" } | Out-Null
Invoke-Mcp "add_plot" @{ group = "demo"; name = "sines"; type = "curve" } | Out-Null
Invoke-Mcp "add_plot" @{ group = "demo"; name = "bars"; type = "bar" } | Out-Null
Invoke-Mcp "add_variable_to_plot" @{ group = "demo"; plot = "control"; variable = "test.step" } | Out-Null
Invoke-Mcp "add_variable_to_plot" @{ group = "demo"; plot = "sines"; variables = '["test.a","test.b","test.c"]' } | Out-Null
Invoke-Mcp "add_variable_to_plot" @{ group = "demo"; plot = "bars"; variables = '["test.a","test.b","test.c"]' } | Out-Null
Invoke-Mcp "set_active_group" @{ name = "demo" } | Out-Null
Invoke-Mcp "set_sampling" @{ sample_frequency_hz = 1000; viewport_width_ms = 1000 } | Out-Null

Invoke-Mcp "start_acquisition" | Out-Null
Start-Sleep -Milliseconds 500
Write-Value "test.step" 0.004
Start-Sleep -Seconds 4
Clear-ShotHover
Save-ShotGif (Join-Path $repo "Introduction\images\VariableViewer.gif") -Seconds 12 -Fps 10 -Actions @{
    4.0 = { Write-Value "test.step" 0.012 }
    8.0 = { Write-Value "test.step" 0.002 }
}
Invoke-Mcp "stop_acquisition" | Out-Null
Start-Sleep -Seconds 1

# --- Recorder demo: normal trigger mode on test.a, the sine speed changed while recording ---
Invoke-Mcp "add_group" @{ name = "recorder demo"; type = "recorder" } | Out-Null
Invoke-Mcp "add_plot" @{ group = "recorder demo"; name = "sines"; type = "curve" } | Out-Null
Invoke-Mcp "add_plot" @{ group = "recorder demo"; name = "control"; type = "table" } | Out-Null
Invoke-Mcp "add_variable_to_plot" @{ group = "recorder demo"; plot = "sines"; variables = '["test.a","test.b","test.c"]' } | Out-Null
Invoke-Mcp "add_variable_to_plot" @{ group = "recorder demo"; plot = "control"; variable = "test.step" } | Out-Null
Invoke-Mcp "set_active_group" @{ name = "recorder demo" } | Out-Null
Invoke-Mcp "set_recorder_mode" @{ mode = "normal" } | Out-Null
Invoke-Mcp "set_recorder_trigger" @{ source_variable = "test.a"; edge = "rising"; value = 0; pre_trigger_samples = 4000; enabled = 1 } | Out-Null

Invoke-Mcp "start_acquisition" | Out-Null
Start-Sleep -Milliseconds 500
Write-Value "test.step" 0.01
Start-Sleep -Seconds 2
Clear-ShotHover
Save-ShotGif (Join-Path $repo "Recorder\images\RecorderDemo.gif") -Seconds 12 -Fps 10 -Actions @{
    4.0 = { Write-Value "test.step" 0.02 }
    8.0 = { Write-Value "test.step" 0.04 }
}
Invoke-Mcp "stop_acquisition" | Out-Null
Start-Sleep -Seconds 1

# --- restore the firmware default and the project ---
Invoke-Mcp "set_active_group" @{ name = "new group0" } | Out-Null
Invoke-Mcp "start_acquisition" | Out-Null
Start-Sleep -Seconds 1
Write-Value "test.step" 0.02
Invoke-Mcp "stop_acquisition" | Out-Null
Invoke-Mcp "set_sampling" @{ sample_frequency_hz = 1000; viewport_width_ms = 500 } | Out-Null
Remove-Demo
