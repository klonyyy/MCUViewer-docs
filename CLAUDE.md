# MCUViewer documentation

User documentation of MCUViewer, built with MyST / Jupyter Book (`myst.yml` holds the page order) and deployed to
https://docs.mcuviewer.com by `.github/workflows/deploy.yml` on push to `main`. The application source lives in
`C:\Users\klonyyy\PROJECTS\MCUViewer_\code\MCUViewer-private` (tags `vX.Y.Z`).

## Pages and where their content comes from

| Page | Source of truth in MCUViewer-private |
| --- | --- |
| `Introduction/` | `cmake/modules/PostBuildAndPackaging.cmake`, `.github/workflows/build_*.yaml` (packages, min OS versions) |
| `VariableViewer/` | `src/Gui/Gui.cpp`, `GuiPlotsTree.cpp`, `GuiVariableTableWindow.hpp`, `GuiVariableEditWindow.hpp`, `GuiPlotEdit.hpp`, `GuiGroupEdit.hpp`, `GuiStatisticsWindow.hpp`, `Common/PlotContextMenu.cpp`, `Common/CursorRenderer.cpp`, `PlotCanvas/` |
| `TraceViewer/` | `src/Gui/GuiSwoControl.cpp`, `GuiSwoPlots.cpp`, trace part of `GuiAcqusition.cpp` |
| `Recorder/` | `src/Gui/GuiPlotsTree.cpp` (`drawRecorderRunMode`), `drawRecorder` in `GuiAcqusition.cpp`, `srcTarget/Recorder` |
| `SerialDriver/` | `drawDebugProbeSettingsSerial` in `GuiAcqusition.cpp`, `srcTarget/SerialDriver` |
| `AcquisitionSettings/` | `src/Gui/GuiAcqusition.cpp`, probe names in `src/Core/MemoryReader/IDebugProbe.hpp` |
| `Flashing/` | `src/Gui/Flashing/FlashingWindow.hpp`, `drawFlashButton` / `drawFlashOutputPopup` in `Gui.cpp` |
| `GeneralSettings/` | `src/Gui/Settings/GeneralSettingsWindow.hpp` |
| `MCPServer/` | `src/MCPServer/` (tools in `Tools/*.hpp`), indicator in `src/Gui/StatusBar/StatusBar.cpp` |
| `FAQ/`, `Examples/` | mixed; examples use `example/STM32/MCUViewer_test`, `example/C2000`, `example/RPI_pico` |

UI strings (window titles, tooltips, labels) are literals in those files - grep for them rather than guessing.

## Updating for a new release

1. `git log --oneline <last-documented-tag>..<new-tag>` in MCUViewer-private, then diff the GUI files above
   (`git diff <old>..<new> -- src/Gui src/MCPServer`) and update the matching pages.
2. Build with `npx jupyter-book build --html` - it lists broken `{ref}` targets. `_build/` is ignored.
3. Regenerate screenshots with `tools/screenshots/All.ps1` (see `tools/screenshots/README.md` for requirements
   and quirks). After moving a callout only, `All.ps1 -BuildOnly` rebuilds without MCUViewer or hardware.

## Conventions

- Markdown files use LF line endings; images are referenced with MyST `{figure}` blocks at `:width: 1000px`.
  Every figure has an `:alt:` line describing what it shows - search engines and AI crawlers only see that text.
- `tools/postprocess_site.py` runs on the build in `deploy.yml`: canonical/og:url tags, removal of the BASE_URL
  fallback dialog, and `llms.txt` / `llms-full.txt` generated from the pages in `myst.yml` order.
- Annotated images: yellow numbered circles with a line to the control, numbered in the order the page text uses.
  The `.drawio` next to an image is generated - change the spec in `tools/screenshots/specs`, not the `.drawio`.
- `example_project/example.mcuv` is the project all screenshots are taken with (its *.elf path points into
  MCUViewer-private). `example.mcuvproj` is the old 1.2.x version of it.
- Never show the Hardware ID of the machine in a screenshot (`Hide-ShotRegion`).
