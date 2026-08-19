# Blender for Android

Port of Blender to Android (ARM64). Uses a GitHub-hosted **`ubuntu-24.04-arm`**
(native ARM64) runner so the code-generation host tools are built natively and
run directly on the worker; only the Blender app targets ARM64-Android via the
NDK.

## How it works

1. **Patch** — `port/blender_android.patch` contains the working-tree diff of
   tracked Blender sources (SDL/EGL windowing, `blenlib` fixes for Bionic,
   `makesdna`/`makesrna`/`datatoc`/`shader_tool` switched to
   `add_blender_host_tool`, etc.) against the pinned commit in `android.yml`.
2. **Port files** — `port/platform_android.cmake` + `port/GHOST_ContextSDL_EGL.*`
   are untracked-new files copied into the Blender tree.
3. **Host tools** — vcpkg (`arm64-linux`) provides native deps; the four
   generation tools are built natively and exported via `BLENDER_HOST_TOOLS_DIR`.
4. **Android app** — vcpkg (`arm64-android`) cross-libs + NDK; `ninja blender`.

## Requirements

- Public repo (free ARM larger-runner minutes) with **paid GitHub minutes**
  enabled: Settings → Billing → Paid minutes. Trigger from
  **Actions → Android Build → Run workflow**.

## Local reference scripts

- `port/build_android.ps1` — Windows cross-build using a native MSVC host build
  in `build_windows` (host tools are `.exe` there). Useful for machines with
  Visual Studio + Windows precompiled libs (`lib/windows_x64`).