# Blender for Android

Port of Blender to Android (ARM64). Builds on the standard **`ubuntu-24.04`**
(x86_64) GitHub runner: the Android NDK only ships x86_64 Linux host binaries,
so a native-ARM runner cannot run it. The code-generation host tools
(`datatoc`, `makesdna`, `makesrna`, `shader_tool`) are built natively as
x86_64-Linux and run on the worker; only the Blender app is cross-compiled to
ARM64-Android via the NDK.

## How it works

1. **Patch** — `port/blender_android.patch` contains the working-tree diff of
   tracked Blender sources (SDL/EGL windowing, `blenlib` fixes for Bionic,
   `makesdna`/`makesrna`/`datatoc`/`shader_tool` switched to
   `add_blender_host_tool`, etc.) against the pinned commit in `android.yml`.
2. **Port files** — `port/platform_android.cmake` + `port/GHOST_ContextSDL_EGL.*`
   are untracked-new files copied into the Blender tree.
3. **Host tools** — vcpkg (`x86_64-linux`) provides native deps; the four
   generation tools are built natively and exported via `BLENDER_HOST_TOOLS_DIR`.
4. **Android app** — vcpkg (`arm64-android`) cross-libs + NDK; `ninja blender`.

## Requirements

- Runs on the standard (free) `ubuntu-24.04` runner; no paid minutes needed.
  Trigger from **Actions → Android Build → Run workflow**. A full Android build
  on 2 cores takes a while but is hands-off.

## Local reference scripts

- `port/build_android.ps1` — Windows cross-build using a native MSVC host build
  in `build_windows` (host tools are `.exe` there). Useful for machines with
  Visual Studio + Windows precompiled libs (`lib/windows_x64`).