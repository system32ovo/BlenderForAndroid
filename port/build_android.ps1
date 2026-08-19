# Blender Android Build Script
# Builds Blender for Android (arm64-v8a) with SDL3 + OpenGL ES via EGL.
#
# Prerequisites:
#   1. Android SDK + NDK (r27 or later)
#   2. CMake 3.21+
#   3. Ninja
#   4. Git
#
# Usage:
#   .\build_android.ps1 -NdkPath "C:\Android\ndk\27.0.12077973"
#
# Or set ANDROID_NDK_HOME environment variable:
#   $env:ANDROID_NDK_HOME = "C:\Android\ndk\27.0.12077973"
#   .\build_android.ps1

param(
    [string]$NdkPath = $env:ANDROID_NDK_HOME,
    [string]$BuildDir = "build_android",
    [string]$ApiLevel = "26",
    [string]$Arch = "arm64-v8a",
    [string]$HostToolsDir = "D:/blender/build_windows/bin",
    [switch]$Clean
)

$ErrorActionPreference = "Stop"

# --------------------------------------------------------------------------
# Check prerequisites
if (-not $NdkPath) {
    Write-Error "Android NDK path not set. Use -NdkPath or set ANDROID_NDK_HOME."
    exit 1
}

if (-not (Test-Path $NdkPath)) {
    Write-Error "Android NDK not found at: $NdkPath"
    exit 1
}

Write-Host "=== Android NDK: $NdkPath" -ForegroundColor Cyan

# NDK toolchain file
$ToolchainFile = "$NdkPath/build/cmake/android.toolchain.cmake"
if (-not (Test-Path $ToolchainFile)) {
    Write-Error "NDK toolchain file not found: $ToolchainFile"
    exit 1
}

# --------------------------------------------------------------------------
# Clean build directory if requested
if ($Clean -and (Test-Path $BuildDir)) {
    Write-Host "=== Cleaning build directory: $BuildDir" -ForegroundColor Yellow
    Remove-Item -Recurse -Force $BuildDir
}

# --------------------------------------------------------------------------
# Configure CMake
Write-Host "=== Configuring CMake..." -ForegroundColor Cyan

$cmakeArgs = @(
    "-B", $BuildDir,
    "-S", ".",
    "-G", "Ninja",
    "-DCMAKE_TOOLCHAIN_FILE=$ToolchainFile",
    "-DCMAKE_SYSTEM_NAME=Android",
    "-DCMAKE_ANDROID_NDK=$NdkPath",
    "-DCMAKE_ANDROID_ARCH_ABI=$Arch",
    "-DCMAKE_ANDROID_API=$ApiLevel",
    # The NDK's legacy toolchain file reads ANDROID_ABI / ANDROID_PLATFORM and
    # ignores CMAKE_ANDROID_ARCH_ABI / CMAKE_ANDROID_API, defaulting the ABI to
    # armeabi-v7a (32-bit). Set both explicitly so we truly target arm64-v8a at
    # API 26, matching the vcpkg arm64-android triplet.
    "-DANDROID_ABI=$Arch",
    "-DANDROID_PLATFORM=android-$ApiLevel",
    "-DCMAKE_BUILD_TYPE=Release",
    # SDL3 and EGL
    "-DWITH_GHOST_SDL=ON",
    "-DWITH_OPENGL_BACKEND=ON",
    "-DWITH_VULKAN_BACKEND=OFF",
    # Disable heavy features
    "-DWITH_CYCLES=OFF",
    "-DWITH_PYTHON=OFF",
    "-DWITH_AUDASPACE=OFF",
    # Freestyle render style engine depends on Python.h.
    "-DWITH_FREESTYLE=OFF",
    "-DWITH_FFMPEG=OFF",
    "-DWITH_INTERNATIONAL=OFF",
    "-DWITH_OPENVDB=OFF",
    "-DWITH_OPENCOLORIO=OFF",
    "-DWITH_OPENSUBDIV=OFF",
    "-DWITH_USD=OFF",
    "-DWITH_ALEMBIC=OFF",
    "-DWITH_BULLET=OFF",
    "-DWITH_MOD_FLUID=OFF",
    "-DWITH_TBB=OFF",
    # GMP (exact-arithmetic nodes) and FFTW3 (FFT optimization) are not
    # cross-compiled for Android. Disable to match the available vcpkg deps.
    "-DWITH_GMP=OFF",
    "-DWITH_FFTW3=OFF",
    # Motion tracking (libmv) requires Ceres + SuiteSparse which are not
    # cross-compiled for Android. Disable to use the libmv stub. Re-enable
    # later once Ceres is available for arm64-android.
    "-DWITH_LIBMV=OFF",
    # Disable tests for faster build
    "-DWITH_GTESTS=OFF",
    "-DWITH_PYTHON_INSTALL=OFF",
    # Disable XR
    "-DWITH_XR_OPENXR=OFF",
    # Disable GPU compute (no CUDA/OptiX/HIP on Android)
    "-DWITH_CYCLES_DEVICE_OPTIX=OFF",
    "-DWITH_CYCLES_DEVICE_CUDA=OFF",
    "-DWITH_CYCLES_DEVICE_HIP=OFF",
    "-DWITH_CYCLES_DEVICE_ONEAPI=OFF",
    # Disable install steps (Android uses APK, not make install)
    "-DWITH_INSTALL_PORTABLE=OFF",
    "-DWITH_BLENDER_THUMBNAILER=OFF",
    "-DWITH_DOC_MANPAGE=OFF"
)

# Point Blender at the natively built host tools (datatoc/makesdna/makesrna/
# shader_tool). These generate source at build time and must be Windows
# executables, not the Android ELF binaries that would otherwise be produced.
# Build them with: make.bat 2026 x64 ninja nobuild builddir D:\blender\build_windows
#   ninja -C D:\blender\build_windows datatoc makesdna makesrna shader_tool
if (Test-Path (Join-Path $HostToolsDir "datatoc.exe")) {
    $cmakeArgs += "-DBLENDER_HOST_TOOLS_DIR=$HostToolsDir"
} else {
    Write-Warning "Host tools not found at: $HostToolsDir"
}

# Blender's custom commands that invoke host `.py` scripts (discover_nodes.py,
# generate_datamodels.py, ...) reference ${PYTHON_EXECUTABLE}. Since
# WITH_PYTHON=OFF there is no self-built python, so point it at the bundled
# Windows host python. Invoking scripts via the `.py` file-association fails
# under the sandbox, so an explicit interpreter is required.
$HostPython = "D:/blender/lib/windows_x64/python/313/bin/python.exe"
if (Test-Path $HostPython) {
    $cmakeArgs += "-DPYTHON_EXECUTABLE=$HostPython"
    $cmakeArgs += "-DPYTHON_EXECUTABLE_VERSION=3.13"
}

# Point Blender at the vcpkg cross-compiled libraries (SDL3, epoxy, fmt, ...).
# These are installed by:
#   vcpkg install sdl3 libepoxy fmt openexr opencolorio openimageio \
#     eigen3 freetype brotli zlib zstd libpng libjpeg-turbo --triplet arm64-android
$VcpkgInstalled = "C:/vcpkg/installed/arm64-android"
if (Test-Path "$VcpkgInstalled/include/SDL3/SDL.h") {
    $cmakeArgs += "-DCMAKE_PREFIX_PATH=$VcpkgInstalled"
    # Blender's custom Find* modules (FindEpoxy/FindZstd/FindBrotli) only search
    # their own ROOT_DIR, so point them at the vcpkg install dir explicitly.
    $cmakeArgs += "-DEPOXY_ROOT_DIR=$VcpkgInstalled"
    $cmakeArgs += "-DZSTD_ROOT_DIR=$VcpkgInstalled"
    $cmakeArgs += "-DBROTLI_ROOT_DIR=$VcpkgInstalled"
} else {
    Write-Warning "vcpkg arm64-android libraries not found at: $VcpkgInstalled"
}

Write-Host "cmake $($cmakeArgs -join ' ')"
& cmake @cmakeArgs
if ($LASTEXITCODE -ne 0) {
    Write-Error "CMake configuration failed."
    exit 1
}

# --------------------------------------------------------------------------
# Build
Write-Host "=== Building Blender for Android..." -ForegroundColor Cyan
& cmake --build $BuildDir --config Release --parallel $env:NUMBER_OF_PROCESSORS
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed."
    exit 1
}

# --------------------------------------------------------------------------
# Output
$BinaryPath = "$BuildDir/bin/blender"
if (Test-Path $BinaryPath) {
    Write-Host ""
    Write-Host "=== Build SUCCESS ===" -ForegroundColor Green
    Write-Host "Binary: $BinaryPath"
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. Package the binary with SDL3 into an Android APK"
    Write-Host "  2. Create an Android Activity that loads the native binary"
    Write-Host "  3. Use SDL_android_main or a custom NativeActivity wrapper"
} else {
    Write-Warning "Binary not found at expected path: $BinaryPath"
    Write-Host "Check the build output for errors."
}