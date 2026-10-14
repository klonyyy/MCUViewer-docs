# Settings -> General with an offline license, then with a seat license -
#   GeneralSettings/images/GeneralSettings.png, GeneralSettingsOfflineLicense.png, GeneralSettingsOnlineLicense.png
# The seat license only syncs with the seat server - "Take" is never pressed and auto take is off in the shot config.
param(
    [string]$OfflineLicense = "D:\MCUViewer_test.lic",
    [string]$SeatLicense = "D:\MCUViewer_test_seat.lic"
)
. "$PSScriptRoot\..\ShotLib.ps1"
Use-ShotInstance

$dialog = @(214, 193, 898, 677)    # the General Settings window inside the screenshot

function Set-License([string]$Path) {
    Invoke-ShotClick 700 518                  # license file field
    Set-ShotFieldText $Path
    Invoke-ShotClick 660 780 -WaitMs 1000     # empty part of the window - leaving the field applies the path
    Start-Sleep -Seconds 6                    # license check and seat server sync
}

# the Hardware ID field identifies this computer - it is replaced with a placeholder in the raw images
function Hide-HardwareId([string]$Name) { Hide-ShotRegion $Name 206 470 610 22 -Text "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX-XXXX" }

Open-ShotGeneralSettings
Set-License $OfflineLicense
Clear-ShotHover
Save-Shot "GeneralSettings" -Crop $dialog
Hide-HardwareId "GeneralSettings"

Set-License $SeatLicense
Clear-ShotHover
Save-Shot "GeneralSettingsOnlineLicense" -Crop $dialog
Hide-HardwareId "GeneralSettingsOnlineLicense"

Set-License $OfflineLicense
Close-ShotDialog
