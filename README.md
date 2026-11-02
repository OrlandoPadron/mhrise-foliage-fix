# Monster Hunter Rise grass and foliage flickering fix for Linux (NVIDIA + Proton)

Fixes the **flickering grass, foliage and rocks** in **Monster Hunter Rise** when playing on **Linux with an NVIDIA GPU** through Steam Proton. No mods and no game files are changed, and there is no performance cost.

**Symptoms this fixes:**
- Grass, plants and bushes flicker or pop in and out.
- Rocks and other environment objects disappear and reappear.
- It depends on the camera angle and distance, and no graphics setting helps.

> **Status:** the permanent fix was merged into vkd3d-proton in [HansKristian-Work/vkd3d-proton#3436](https://github.com/HansKristian-Work/vkd3d-proton/pull/3436) (November 2026). Once your Proton version includes a vkd3d-proton release newer than v3.1, this workaround is no longer needed.

## Install

1. Download `quirks.txt`:
   ```
   mkdir -p ~/.local/share/rise-vkd3d-fix
   curl -L -o ~/.local/share/rise-vkd3d-fix/quirks.txt https://raw.githubusercontent.com/OrlandoPadron/mhrise-foliage-fix/main/quirks.txt
   ```
2. In Steam, open Monster Hunter Rise → **Properties** → **Launch Options** and add (replace `<user>` with your username):
   ```
   VKD3D_SHADER_QUIRKS=/home/<user>/.local/share/rise-vkd3d-fix/quirks.txt %command%
   ```
3. Launch the game. The first minutes may stutter while shaders recompile.

## Still flickering?

Use [`quirks-all.txt`](quirks-all.txt) instead of `quirks.txt` (same steps), and please open an issue. It applies the workaround to every shader, at a small performance cost.

## Uninstall

Remove `VKD3D_SHADER_QUIRKS=…` from the launch options.

## How it works

A compute shader in the game reads shared memory without the barrier it needs, which produces wrong results on NVIDIA GPUs. `quirks.txt` tells vkd3d-proton (the DirectX 12 to Vulkan layer in Proton) to apply its built-in `FORCE_TGSM_BARRIERS` workaround to that shader (`aae07660844b89cf`), which adds the missing synchronization.

Tested on an RTX 5070 Ti (driver 615.78.08), CachyOS and Proton CachyOS 11, across all regions of the game. Other recent Proton versions (Proton Experimental, GE-Proton) should work the same way.
