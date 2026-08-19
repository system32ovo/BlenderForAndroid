# SPDX-FileCopyrightText: 2025 Blender Authors
#
# SPDX-License-Identifier: GPL-2.0-or-later

# Libraries configuration for Android.

# Android is always cross-compiled. The NDK provides the toolchain.
# Build with:
#   cmake -B build_android \
#     -DCMAKE_SYSTEM_NAME=Android \
#     -DCMAKE_ANDROID_NDK=/path/to/ndk \
#     -DCMAKE_ANDROID_ARCH_ABI=arm64-v8a \
#     -DCMAKE_ANDROID_API=26 \
#     -DWITH_GHOST_SDL=ON \
#     -DWITH_OPENGL_BACKEND=ON \
#     -DWITH_CYCLES=OFF \
#     -DWITH_PYTHON=OFF \
#     -DWITH_AUDASPACE=OFF \
#     ..
#   cmake --build build_android

# Android minimum API level.
if(CMAKE_ANDROID_API LESS 26)
  message(FATAL_ERROR "Android API level 26 (Android 8.0) or higher is required.")
endif()

# Only arm64-v8a is supported for now.
if(NOT CMAKE_ANDROID_ARCH_ABI STREQUAL "arm64-v8a")
  message(WARNING
    "Only arm64-v8a is tested. "
    "CMAKE_ANDROID_ARCH_ABI=${CMAKE_ANDROID_ARCH_ABI} may not work."
  )
endif()

# --------------------------------------------------------------------------
# Force SDL backend for windowing.
# Android has no native X11/Wayland/Win32, SDL is the only option.
set(WITH_GHOST_SDL ON CACHE BOOL "" FORCE)
set(WITH_GHOST_X11 OFF CACHE BOOL "" FORCE)
set(WITH_GHOST_WAYLAND OFF CACHE BOOL "" FORCE)

# --------------------------------------------------------------------------
# Force OpenGL ES backend via EGL (no desktop GL on Android).
set(WITH_OPENGL_BACKEND ON CACHE BOOL "" FORCE)

# Vulkan is available on Android 7+ but the Blender Vulkan backend is
# still in development. Enable at your own risk.
# set(WITH_VULKAN_BACKEND ON CACHE BOOL "" FORCE)

# --------------------------------------------------------------------------
# Disable features that don't make sense on Android initially.
# These can be re-enabled as dependencies are ported.

set(WITH_CYCLES OFF CACHE BOOL "" FORCE)
set(WITH_CYCLES_STANDALONE OFF CACHE BOOL "" FORCE)
set(WITH_CYCLES_HYDRA_RENDER_DELEGATE OFF CACHE BOOL "" FORCE)

set(WITH_PYTHON OFF CACHE BOOL "" FORCE)
set(WITH_PYTHON_MODULE OFF CACHE BOOL "" FORCE)

set(WITH_AUDASPACE OFF CACHE BOOL "" FORCE)
set(WITH_OPENAL OFF CACHE BOOL "" FORCE)
set(WITH_SDL_AUDIO OFF CACHE BOOL "" FORCE)
set(WITH_JACK OFF CACHE BOOL "" FORCE)
set(WITH_PULSEAUDIO OFF CACHE BOOL "" FORCE)
set(WITH_WASAPI OFF CACHE BOOL "" FORCE)
set(WITH_COREAUDIO OFF CACHE BOOL "" FORCE)

set(WITH_FFMPEG OFF CACHE BOOL "" FORCE)

set(WITH_OPENVDB OFF CACHE BOOL "" FORCE)
set(WITH_EMBREE OFF CACHE BOOL "" FORCE)
set(WITH_NANOVDB OFF CACHE BOOL "" FORCE)
set(WITH_OPENCOLORIO OFF CACHE BOOL "" FORCE)
set(WITH_OPENIMAGEDENOISE OFF CACHE BOOL "" FORCE)
set(WITH_OPENSUBDIV OFF CACHE BOOL "" FORCE)
set(WITH_OPENPGL OFF CACHE BOOL "" FORCE)
set(WITH_XR_OPENXR OFF CACHE BOOL "" FORCE)

set(WITH_BOOST OFF CACHE BOOL "" FORCE)
set(WITH_USD OFF CACHE BOOL "" FORCE)
set(WITH_ALEMBIC OFF CACHE BOOL "" FORCE)
set(WITH_MATERIALX OFF CACHE BOOL "" FORCE)
set(WITH_HYDRA OFF CACHE BOOL "" FORCE)

set(WITH_BULLET OFF CACHE BOOL "" FORCE)
set(WITH_MOD_FLUID OFF CACHE BOOL "" FORCE)
set(WITH_MOD_OCEANSIM OFF CACHE BOOL "" FORCE)

set(WITH_TBB OFF CACHE BOOL "" FORCE)
set(WITH_POTRACE OFF CACHE BOOL "" FORCE)
set(WITH_HARU OFF CACHE BOOL "" FORCE)

set(WITH_INTERNATIONAL OFF CACHE BOOL "" FORCE)
set(WITH_INPUT_IME OFF CACHE BOOL "" FORCE)
set(WITH_INPUT_NDOF OFF CACHE BOOL "" FORCE)

set(WITH_COMPILER_ASAN OFF CACHE BOOL "" FORCE)
set(WITH_CPU_CHECK OFF CACHE BOOL "" FORCE)
set(WITH_HEADLESS OFF CACHE BOOL "" FORCE)

# --------------------------------------------------------------------------
# Android cross-build host tools.
# The `makesdna`/`makesrna`/`datatoc`/`shader_tool` executables generate
# source at build time. They are cross-compiled for Android here, which is
# wrong: an Android ELF binary cannot run on the build host. When provided,
# BLENDER_HOST_TOOLS_DIR points at natively built versions (with the same
# basenames) that the custom commands call instead of the target-built ones.
#
# Build the host tools once on Windows with:
#   make.bat 2026 x64 ninja nobuild builddir D:\blender\build_windows
#   ninja -C D:\blender\build_windows datatoc makesdna makesrna shader_tool
set(BLENDER_HOST_TOOLS_DIR "" CACHE STRING "Directory of natively built Blender host tools (datatoc, makesdna, makesrna, shader_tool).")

# Create a native tool target for the code-generation executables
# (`makesdna`, `makesrna`, `datatoc`, `shader_tool` refer to themselves in
# add_custom_command via $<TARGET_FILE:...>). When cross-compiling for Android
# an Android ELF binary cannot run on the host, so if BLENDER_HOST_TOOLS_DIR is
# set they resolve to the natively built host executables instead of being
# cross-compiled. For an IMPORTED executable $<TARGET_FILE:> resolves to
# IMPORTED_LOCATION.
macro(add_blender_host_tool _blender_tool_name)
  if(BLENDER_HOST_TOOLS_DIR)
    # The cross-compiled target has no executable suffix (CMAKE_EXECUTABLE_SUFFIX
    # is empty for Android), but the host tools run on the build host. Prefer
    # the `.exe` form on Windows and the bare name on Linux/macOS.
    set(_blender_host_tool_path "${BLENDER_HOST_TOOLS_DIR}/${_blender_tool_name}.exe")
    if(NOT EXISTS "${_blender_host_tool_path}")
      set(_blender_host_tool_path "${BLENDER_HOST_TOOLS_DIR}/${_blender_tool_name}")
    endif()
    if(NOT EXISTS "${_blender_host_tool_path}")
      message(FATAL_ERROR "Host tool not found: ${_blender_host_tool_path}")
    endif()
    add_executable(${_blender_tool_name} IMPORTED GLOBAL)
    set_target_properties(${_blender_tool_name} PROPERTIES IMPORTED_LOCATION "${_blender_host_tool_path}")
    message(STATUS "Using prebuilt host tool ${_blender_tool_name}: ${_blender_host_tool_path}")
  else()
    add_executable(${_blender_tool_name} ${ARGN})
  endif()
endmacro()

if(BLENDER_HOST_TOOLS_DIR)
  message(STATUS "Using host tools from: ${BLENDER_HOST_TOOLS_DIR}")

  # The host tools may be dynamically linked against external libraries.
  # Expose their bin/lib folders on the PATH (Windows) or LD_LIBRARY_PATH
  # (Linux/macOS) used by the generation custom commands (PLATFORM_ENV_BUILD).
  # Semi-colons must be escaped so the value stays a single argument to
  # `cmake -E env`.
  if(WIN32)
    set(_host_win_libdir "${CMAKE_SOURCE_DIR}/lib/windows_x64")
    file(GLOB _host_dirs "${_host_win_libdir}/*/bin" "${_host_win_libdir}/*/lib")
    list(JOIN _host_dirs "\\;" _host_path_literal)
    set(PLATFORM_ENV_BUILD "PATH=${_host_path_literal}")
    unset(_host_dirs)
    unset(_host_path_literal)
    unset(_host_win_libdir)
  else()
    # On Linux the host tools are built natively and statically-linked where
    # possible; if they are dynamic, point LD_LIBRARY_PATH at their build dir.
    set(_host_path_literal "${BLENDER_HOST_TOOLS_DIR}")
    set(PLATFORM_ENV_BUILD "LD_LIBRARY_PATH=${_host_path_literal}")
    unset(_host_path_literal)
  endif()
endif()

# --------------------------------------------------------------------------
# The NDK toolchain restricts find_* searches to its own sysroot by setting
# CMAKE_FIND_ROOT_PATH_MODE_* to ONLY. That re-roots any external absolute
# paths (CMAKE_PREFIX_PATH, EPOXY_ROOT_DIR) into the sysroot and thus hides
# our vcpkg cross-compiled libraries. Allow searching both the sysroot and
# the vcpkg install dir so find_package/find_library can locate them.
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE BOTH)

# --------------------------------------------------------------------------
# SDL3 library setup.
# On Android, SDL3 provides the native glue (SDL_android_main, etc.).
# The SDL3 library must be pre-built for Android or provided as a CMake
# find_package target.

# SDL3 can be built as part of the dependency build or provided externally.
# Example: use vcpkg or build SDL3 with Android NDK separately.
if(NOT TARGET SDL3::SDL3)
  find_package(SDL3 CONFIG QUIET)
  if(NOT SDL3_FOUND)
    message(STATUS
      "SDL3 not found via find_package. "
      "Set SDL3_DIR to the SDL3 CMake config directory."
    )
  endif()
endif()

# --------------------------------------------------------------------------
# EGL and OpenGL ES are provided by the Android NDK.
# No additional find_package needed - they are part of the NDK sysroot.

# The epoxy library (GL/EGL loader) must be cross-compiled for Android.
# libepoxy ships no CMake config, so use Blender's own FindEpoxy module.
# Point EPOXY_ROOT_DIR at the vcpkg triplet install dir (set in build_android.ps1).
find_package(Epoxy REQUIRED)

# --------------------------------------------------------------------------
# Mandatory "modern" dependencies.
# These are always required by Blender's build system and ship CMake config
# files (fmt::fmt, OpenEXR::OpenEXR, OpenImageIO::OpenImageIO,
# OpenColorIO::OpenColorIO). build_files/cmake/platform/dependency_targets.cmake
# creates ALIAS targets to them unconditionally, so they MUST be found here.
# Cross-compile them for arm64-android with vcpkg and point CMAKE_PREFIX_PATH
# at the vcpkg triplet install dir (done in build_android.ps1):
#   vcpkg install fmt openexr opencolorio openimageio --triplet arm64-android
find_package(fmt REQUIRED CONFIG)
find_package(OpenEXR REQUIRED CONFIG)
find_package(OpenImageIO REQUIRED CONFIG)
find_package(OpenColorIO REQUIRED CONFIG)

# --------------------------------------------------------------------------
# Remaining mandatory dependencies whose link targets are referenced
# unconditionally by dependency_targets.cmake. Each must be cross-compiled
# for arm64-android with vcpkg (and located via CMAKE_PREFIX_PATH):
#   vcpkg install eigen3 freetype brotli zlib zstd libpng libjpeg-turbo \
#     --triplet arm64-android
find_package(Eigen3 REQUIRED CONFIG)

find_package(Freetype REQUIRED)
find_package(Brotli REQUIRED)

find_package(ZLIB REQUIRED)
find_package(PNG REQUIRED)
find_package(JPEG REQUIRED)
find_package(Zstd REQUIRED)

# --------------------------------------------------------------------------
# Compiler flags for Android.
add_definitions(-DANDROID -D__ANDROID__)

# Android uses `posix_memalign` instead of `aligned_alloc`.
add_definitions(-DHAVE_POSIX_MEMALIGN)

# Disable execinfo (not available on Bionic libc).
add_definitions(-DHAVE_EXECINFO_H=0)

# --------------------------------------------------------------------------
# Linker flags.
# Android needs the log, android, and EGL/GLESv3 libraries.
list(APPEND PLATFORM_LINKLIBS
  log
  android
  EGL
  GLESv3
)

# --------------------------------------------------------------------------
# Override system paths detection.
# On Android, there is no "system" Python/FFmpeg/etc.
# Everything is cross-compiled.

macro(find_package_wrapper)
  # On Android, we don't use system libraries.
  # Dependencies must be cross-compiled and provided via CMake find_package.
  find_package(${ARGV})
endmacro()

function(print_found_status lib_name lib_path)
  if(FIRST_RUN)
    if(lib_path)
      message(STATUS "Found ${lib_name}: ${lib_path}")
    else()
      message(WARNING "Could NOT find ${lib_name}")
    endif()
  endif()
endfunction()