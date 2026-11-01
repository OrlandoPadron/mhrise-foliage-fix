# MH Rise Foliage Fix

Fixes the flickering grass, foliage and rocks in **Monster Hunter Rise** (PC) on **Linux with NVIDIA GPUs** (Proton / vkd3d-proton). Objects pop in and out depending on the camera angle, regardless of graphics settings.

No mods, no modified DLLs and no game files are touched: it is a text file that tells Proton's own vkd3d-proton to apply one of its built-in shader workarounds to the affected shaders. There is no measurable performance cost.

> **Status:** a permanent fix has been submitted to vkd3d-proton in [HansKristian-Work/vkd3d-proton#3436](https://github.com/HansKristian-Work/vkd3d-proton/pull/3436). Once it is merged and included in a Proton release, this workaround will no longer be needed.

## Cause

Some of the game's compute shaders, including the GPU culling that decides which instanced objects (grass, foliage, rocks) are visible each frame, write to group shared memory and read it back without the barrier needed to make those writes visible to the other threads in the group. AMD and Qualcomm (Adreno/Turnip) GPUs happen to produce the right result anyway; NVIDIA's driver does not, so the culling sometimes gets wrong results and objects flicker as the camera moves.

vkd3d-proton already has a workaround for this class of bug, `FORCE_TGSM_BARRIERS`, which inserts a barrier after every write to group shared memory. It is just not enabled for Monster Hunter Rise.

## Fix

1. Download [`quirks.txt`](quirks.txt) and save it somewhere permanent, e.g. `~/.local/share/rise-vkd3d-fix/quirks.txt`.
2. In Steam, open Monster Hunter Rise → Properties → Launch Options and add (use the full path to the file):
   ```
   VKD3D_SHADER_QUIRKS=/home/<user>/.local/share/rise-vkd3d-fix/quirks.txt %command%
   ```
3. Launch the game. The first minutes may stutter while shaders recompile.

`quirks.txt` applies `FORCE_TGSM_BARRIERS` to a single compute shader, `aae07660844b89cf`, found by bisecting the game's shaders. The hash identifies the game's shader bytecode, so it is the same on every machine.

### If something still flickers

The fix was verified in the Shrine Ruins, the Sandy Plains and the training area. If you still see flickering somewhere, use [`quirks-all.txt`](quirks-all.txt) instead, which applies the workaround to every shader, and please open an issue. It costs a bit more performance, but it only affects shaders that use group shared memory.

## Tested on

- RTX 5070 Ti, NVIDIA driver 615.78.08, CachyOS
- Proton CachyOS 11 (vkd3d-proton 3.1.0), DirectX 12

## What did not help

For reference, none of these changed the flickering: Image Quality at 100% or a 60 fps cap (vkd3d-proton issue [#1347](https://github.com/HansKristian-Work/vkd3d-proton/issues/1347)), clearing shader caches, vkd3d-proton 2.8 to 3.1, `VKD3D_CONFIG` flags (`single_queue`, `no_upload_hvv`, compression toggles…), disabling `VK_EXT_device_generated_commands`, 32-bit precision and the other vkd3d-proton shader workarounds (`FORCE_DEVICE_MEMORY_BARRIER_THREAD_GROUP_COHERENCY`, `FORCE_SUBGROUP_SIZE_1`, the RE Engine culling quirks…), and lowering the grass alpha-test cutoff. An earlier version of this repo shipped an REFramework script that changed the alpha-test value per mesh; it only worked because it accidentally disabled GPU instancing for the grass, at a large CPU cost.

## Uninstall

Remove `VKD3D_SHADER_QUIRKS=…` from the launch options.
