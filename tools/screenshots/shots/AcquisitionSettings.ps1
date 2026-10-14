# Options -> Acquisition with an ST-Link - used by AcquisitionGeneral and AcquisitionAdvanced
. "$PSScriptRoot\..\ShotLib.ps1"
Use-ShotInstance

Invoke-Mcp "set_debug_probe" @{ type = "stlink"; speed_khz = 10000; keep_connection = 1 } | Out-Null
Invoke-Mcp "set_sampling" @{ sample_frequency_hz = 1000; viewport_width_ms = 500 } | Out-Null

Open-ShotAcquisitionSettings
Clear-ShotHover
Save-Shot "AcquisitionSettings"
Close-ShotDialog
