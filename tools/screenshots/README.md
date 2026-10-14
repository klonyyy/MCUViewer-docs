# Documentation screenshots

Scripts that regenerate the screenshots and GIFs of the documentation from a running MCUViewer.

```
tools/screenshots/
  ShotLib.ps1     helpers: instance, input, capture, GIFs, MCP client, annotation build
  annotate.py     spec -> .drawio (callouts, dashed areas, drag paths)
  All.ps1         runs everything in order and builds all images
  shots/*.ps1     one script per screen - brings the app into a state and saves raw/<name>.png
  specs/*.json    one spec per documentation image - raw image, output path, annotations
  raw/*.png       captured screenshots (1326x1032 window or a cropped dialog)
```

## Requirements

- Windows, MCUViewer installed in `C:\Program Files\MCUViewer`, a license loaded in MCUViewer (the window title shows the plan).
- draw.io desktop (`C:\Program Files\draw.io`), Python 3, ffmpeg (GIFs).
- An ST-Link with an STM32G474 running `example/STM32/MCUViewer_test` from the MCUViewer repository. Nothing is flashed - the scripts only read and write RAM variables (and `OpenOCD.ps1` runs OpenOCD with `resume` on attach).
- `D:\MCUViewer_test.lic` and `D:\MCUViewer_test_seat.lic` for the General Settings shots (parameters of `GeneralSettings.ps1`).

## Usage

```powershell
.\All.ps1                          # everything: starts the instance, all shots, builds all images
.\All.ps1 -BuildOnly               # only rebuild images from raw/ + specs/ (e.g. after moving a callout)
. .\ShotLib.ps1; Start-ShotInstance ..\..\example_project\example.mcuv   # start the instance by hand
.\All.ps1 -Only Trace,Recorder     # selected shots on the running instance
```

How the instance works:

- It runs with its own `%APPDATA%` (`%LOCALAPPDATA%\MCUViewer-docs`), so the user's config, recent projects and layout are not touched. The config is copied from the user's one (license included).
- The window sits at x=4000, outside of every monitor, so the real mouse never hovers it. If it gets minimized (Win+D), `Use-ShotInstance` restores it.
- Input goes through window messages posted while the GUI thread is suspended (see `ShotNative.Burst`); state changes that are easier through the API go through the built-in MCP server (`Invoke-Mcp`).
- All coordinates in scripts and specs are screenshot pixels of the 1326x1032 window, title bar included.

## Adding or changing an image

1. Write or extend a `shots/<Name>.ps1` that gets the app into the right state and calls `Save-Shot "<Name>"` (optionally `-Crop x,y,w,h` for a dialog).
2. Write `specs/<Name>.json`:

```json
{
  "image": "raw/<Name>.png",
  "output": "<Page>/images/<Name>.drawio",
  "callouts": [{"n": 1, "circle": [x, y], "target": [x, y]}],
  "areas": [{"rect": [x, y, w, h]}],
  "paths": [{"points": [[x, y], [x, y], [x, y]]}]
}
```

   `circle` is the top-left corner of the 50x50 numbered circle; `targets` (a list) draws several lines from one circle. Without annotations the `output` is a `.png` and the screenshot is copied.
3. `Build-ShotAnnotation <Name>` (or `All.ps1 -BuildOnly`) writes the `.drawio` and exports the `.png` next to it (draw.io, scale 2).

## Quirks worth knowing

- A single click on a tree arrow does not register - double-click the label (`Expand-ShotGroup0`).
- Dock tabs (Var Viewer / Trace Viewer) need the button held over several frames - `Show-ShotVarViewer` / `Show-ShotTraceViewer`. The last shown tab is restored on start.
- Menus need mouse movement between frames before they react; `Invoke-ShotClick` already does it.
- Escape closes dialogs but leaves a keyboard nav frame - `Close-ShotDialog` clicks the status bar afterwards.
- When the app is not focused it runs at 10 fps; while acquiring at 60 fps. Clicking STOP is unreliable then - use `Send-ShotKey 0x20` (Space).
- The Hardware ID in General Settings identifies the computer - `GeneralSettings.ps1` paints it over in the raw image (`Hide-ShotRegion`), because the `.drawio` files embed the raw image.
- The trace SWO clock above the ST-Link's 24 MHz refuses to start; prescaler 6 gives error frames for `TraceErrors`.
- Variables added through MCP get random colours.
- The MCP server drops idle sessions; `Invoke-Mcp` reconnects.
- draw.io is started with `ELECTRON_RUN_AS_NODE` removed, which the VS Code terminal sets.

Not covered (need other hardware or old setups): `Examples/C2000/*`, `Examples/GDBServer/*`, `SerialDriver/images/Setup.png`, `Profiling*.png`, `Speedup.gif`, `SerialDriverDetected.png`, `GeneralSettingsOnlineLicense.png` (needs a free seat on the test seat license).
