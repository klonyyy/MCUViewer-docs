# Regenerates every documentation screenshot: starts the screenshot instance, runs all shot scripts in an order
# where each one starts from the state the previous one left, and builds the annotated images from specs/.
#   .\All.ps1                      - everything
#   .\All.ps1 -Only Trace,Gifs     - selected shot scripts (the instance has to be running already, or use -Start)
#   .\All.ps1 -BuildOnly           - only rebuild the images from raw/ and specs/ (no MCUViewer, no hardware)
param(
    [string[]]$Only = @(),
    [switch]$Start,
    [switch]$BuildOnly,
    [string]$OpenOcd = "openocd"
)
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\ShotLib.ps1"
$repo = Resolve-Path "$PSScriptRoot\..\.."

$order = @("Setup", "VarViewer", "AcquisitionSettings", "Flashing", "GeneralSettings", "AddVariable", "VariableEdit",
           "PlotSettings", "DragNDrop", "WriteValue", "Cursors", "Statistics", "Setup", "Trace", "Recorder", "Serial",
           "Gifs", "OpenOCD")

if (-not $BuildOnly) {
    $scripts = if ($Only.Count -gt 0) { $Only } else { $order }
    if ($Only.Count -eq 0 -or $Start) { Start-ShotInstance (Join-Path $repo "example_project\example.mcuv") }
    foreach ($s in $scripts) {
        Write-Host "==> $s"
        if ($s -eq "OpenOCD") { & "$PSScriptRoot\shots\$s.ps1" -OpenOcd $OpenOcd } else { & "$PSScriptRoot\shots\$s.ps1" | Out-Null }
    }
    if ($Only.Count -eq 0) { Use-ShotInstance; Invoke-Mcp "save_project" | Out-Null; Stop-ShotInstance }
}

foreach ($spec in Get-ChildItem "$PSScriptRoot\specs\*.json") {
    $image = (Get-Content $spec.FullName -Raw | ConvertFrom-Json).image
    if (-not (Test-Path (Join-Path $PSScriptRoot $image))) { Write-Warning "$($spec.BaseName): $image missing, skipped"; continue }
    Write-Host "build $($spec.BaseName)"
    Build-ShotAnnotation $spec.FullName | Out-Null
}
