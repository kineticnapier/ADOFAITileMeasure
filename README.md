# ADOFAITileMeasure

ADOFAI editor tile-distance ruler exposed as an external pane in [ADOFAIWorkbench](https://github.com/kineticnapier/ADOFAIWorkbench).

## What it measures

Select a contiguous tile range in the ADOFAI level editor. The `Measure` pane uses the first and last selected tiles by `seqID` and reports the displacement between their tile-center positions.

- `Delta X`: horizontal displacement in tile units
- `Delta Y`: vertical displacement in tile units
- `Distance`: Euclidean distance in tile units

World-space displacement is divided by ADOFAI's runtime `tileSize`, so `1.000` means one tile length.

## Requirements

- A Dance of Fire and Ice
- Unity Mod Manager
- ADOFAIWorkbench

ADOFAITileMeasure consumes Workbench through its public `IDockablePaneProvider` API. It does not modify or bundle Workbench.

## Usage

1. Install and enable ADOFAIWorkbench.
2. Install and enable ADOFAITileMeasure.
3. Open the ADOFAI level editor.
4. Select a range of at least two tiles.
5. Open `Measure` from the Workbench `Panes` menu.

The pane updates automatically while the selection changes.

## Build

```powershell
.\build.ps1
```

The build script looks for `ADOFAIWorkbench.dll` in the installed game mod directory or a sibling `ADOFAIWorkbench` checkout. Override it with `-WorkbenchDir` when necessary.
