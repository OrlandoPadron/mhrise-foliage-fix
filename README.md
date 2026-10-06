# MH Rise Foliage Fix

A [REFramework](https://github.com/praydog/REFramework) Lua script that fixes the grass flickering in **Monster Hunter Rise** (PC), where near and mid-distance grass keeps popping in and out regardless of graphics settings.

## Cause

Grass materials use alpha testing with a cutoff of `AlphaTest_Param = 0.5`. As you move away, the engine samples smaller mipmaps of the grass texture, where alpha gets averaged out. Thin blades end up hovering right around the 0.5 threshold, so they vanish and reappear as the distance changes. No in-game graphics option touches this value, and it is not caused by LOD, culling, camera dissolve or DLSS/anti-aliasing.

## Fix

The script lowers `AlphaTest_Param` to `0.25` on every loaded mesh material that has it, and rescans every 2 seconds to catch meshes streamed in as you move between areas. Original values are kept, so disabling the fix restores them.

## Installation

1. Install [REFramework for MH Rise](https://www.nexusmods.com/monsterhunterrise/mods/26) (`dinput8.dll` in the game folder).
   - On Linux/Proton, set the Steam launch options to `WINEDLLOVERRIDES="dinput8=n,b" %command%`.
2. Copy `reframework/autorun/foliage_fix.lua` into `<game folder>/reframework/autorun/`.
3. Launch the game. The fix is enabled by default.

## Configuration

Open the REFramework menu (**Insert**) → **Script Generated UI** → **Foliage Fix**:

- **Enabled**: toggle the fix (restores the original values when off).
- **Alpha-test cutoff**: game default is `0.5`; `0.25` works well. Lower values make grass slightly thicker.

Settings are saved to `<game folder>/reframework/data/foliage_fix.json`.

## Uninstall

Delete `reframework/autorun/foliage_fix.lua`.
