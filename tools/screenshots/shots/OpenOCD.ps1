# STM32 and OpenOCD example - Examples/STM32_OpenOCD/images/AcquisitionSettings.png, Flashing.png and Start.gif.
# Starts OpenOCD with the ST-Link the same way the example does (the target is resumed on gdb attach, nothing is
# flashed), connects MCUViewer to it as GDBSERVER, records a short run and switches back to the ST-Link probe.
param(
    [string]$OpenOcd = "openocd",
    [string]$StlinkSerial = "002B001F3431511531343632"
)
. "$PSScriptRoot\..\ShotLib.ps1"
Use-ShotInstance

$repo = Resolve-Path "$PSScriptRoot\..\..\.."
$out = Join-Path $repo "Examples\STM32_OpenOCD\images"
$dialog = @(214, 193, 898, 677)

Show-ShotVarViewer
Invoke-Mcp "stop_acquisition" | Out-Null
# release the ST-Link: "Connected" in the menu bar disconnects the probe
if ((Get-ShotPixel 1063 42)[1] -gt 100) { Invoke-ShotClick 1063 42 -WaitMs 1500 }

$ocdArgs = @('-c', 'gdb_port 3333', '-f', 'interface/stlink.cfg', '-f', 'target/stm32g4x.cfg', '-c', 'adapter speed 20000',
             '-c', '$_TARGETNAME configure -event gdb-attach { resume }', '-c', 'gdb memory_map disable')
$ocd = Start-Process -FilePath $OpenOcd -ArgumentList ($ocdArgs | ForEach-Object { "`"$_`"" }) -PassThru -WindowStyle Hidden `
    -RedirectStandardError (Join-Path $env:TEMP "mcuviewer-docs-shots\openocd.log")
try {
    for ($i = 0; $i -lt 20 -and -not (Get-NetTCPConnection -State Listen -LocalPort 3333 -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Milliseconds 500 }
    if (-not (Get-NetTCPConnection -State Listen -LocalPort 3333 -ErrorAction SilentlyContinue)) { throw "OpenOCD did not start - see openocd.log" }

    Invoke-Mcp "set_debug_probe" @{ type = "gdbserver"; keep_connection = 0 } | Out-Null
    Invoke-Mcp "configure_probe" @{ ip = "127.0.0.1"; port = 3333 } | Out-Null

    Open-ShotAcquisitionSettings
    Clear-ShotHover
    Save-Shot "OpenOCDAcquisitionSettings" -Crop $dialog | Out-Null
    Copy-Item (Join-Path $script:ShotRawDir "OpenOCDAcquisitionSettings.png") (Join-Path $out "AcquisitionSettings.png") -Force

    # the GIF starts with the settings window open, closes it and runs the acquisition for a few seconds
    Save-ShotGif (Join-Path $out "Start.gif") -Seconds 10 -Fps 10 -Actions @{
        1.5 = { Close-ShotDialog }
        3.0 = { Send-ShotKey 0x20 }
        8.5 = { Send-ShotKey 0x20 }
    }

    Open-ShotFlashingSettings
    Clear-ShotHover
    Save-Shot "OpenOCDFlashing" -Crop @(264, 282, 799, 500) | Out-Null
    Copy-Item (Join-Path $script:ShotRawDir "OpenOCDFlashing.png") (Join-Path $out "Flashing.png") -Force
    Close-ShotDialog
}
finally {
    Invoke-Mcp "stop_acquisition" | Out-Null
    Start-Sleep -Seconds 1
    Stop-Process -Id $ocd.Id -ErrorAction SilentlyContinue
    Invoke-Mcp "set_debug_probe" @{ type = "stlink"; serial_number = $StlinkSerial; speed_khz = 10000; keep_connection = 1 } | Out-Null
}
