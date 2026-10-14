# Serial driver - SerialDriver/images/SerialDriver.png and (when detection works) SerialDriverDetected.png.
# The MCUViewer_test firmware runs the serial driver on USART3 at 230400 baud. On the board used in October 2026
# the detection failed (the ST-Link VCP is probably not wired to USART3), so SerialDriverDetected.png was left as
# it was. The probe is switched back to the ST-Link at the end.
param(
    [string]$Port = "COM12",
    [int]$Baudrate = 230400,
    [string]$StlinkSerial = "002B001F3431511531343632"
)
. "$PSScriptRoot\..\ShotLib.ps1"
Use-ShotInstance

$dialog = @(214, 193, 898, 677)
Show-ShotVarViewer
Invoke-Mcp "set_debug_probe" @{ type = "serial"; serial_number = $Port } | Out-Null
Invoke-Mcp "configure_probe" @{ baudrate = $Baudrate } | Out-Null

Open-ShotAcquisitionSettings
Clear-ShotHover
Save-Shot "SerialDriver" -Crop $dialog | Out-Null
Invoke-ShotClick 1021 484 -WaitMs 4000            # Detect serial
Clear-ShotHover
$detected = -not ((Get-ShotPixel 430 510)[0] -gt 180)    # the status text turns red on failure
if ($detected) { Save-Shot "SerialDriverDetected" -Crop $dialog | Out-Null } else { Write-Warning "serial driver not detected - SerialDriverDetected not captured" }
Close-ShotDialog

Invoke-Mcp "set_debug_probe" @{ type = "stlink"; serial_number = $StlinkSerial; speed_khz = 10000; keep_connection = 1 } | Out-Null
