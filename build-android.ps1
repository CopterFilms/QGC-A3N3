# ============================================================================
# build-android.ps1 — Build QGroundControl for Android (A3N3 BRIDGE custom).
#
# Local toolchain layout (see docs/A3N3_BUILD.md for the full manual):
#   JDK 21     : D:\jdk21
#   CMake 3.31 : D:\build-tools\cmake-<ver>-windows-x86_64
#   Ninja 1.13 : D:\build-tools\ninja
#   Qt 6.11.1  : D:\Qt\6.11.1\in  win64_msvc2022_64  (host, tools)
#                D:\Qt\6.11.1\android_arm64_v8a       (target SDK)
#   Android SDK: D:\AndroidSDK  (platforms;android-36, build-tools;36.0.0,
#                                platform-tools, ndk\27.2.12479018)
#   GStreamer  : D:\gstreamer\<abi>   (extracted universal 1.28.4 SDK)
#
# NOTE: this fork defaults QGC_CUSTOM_DIR=custom (cmake/CustomOptions.cmake),
# so every build carries the A3N3 BRIDGE overlay by default.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File build-android.ps1 [-Clean] [-Debug]
# ============================================================================
param(
    [switch]$Clean,
    [switch]$Debug
)

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------- toolchain
$env:JAVA_HOME              = "D:\jdk21"
$env:PATH                   = "D:\jdk21\bin;" + $env:PATH
$env:ANDROID_SDK_ROOT       = "D:\AndroidSDK"
$env:ANDROID_HOME           = "D:\AndroidSDK"
$env:ANDROID_NDK            = "D:\AndroidSDK\ndk\27.2.12479018"
$env:ANDROID_MIN_SDK        = "28"
$env:QT_TARGET_ROOT_DIR     = "D:\Qt\6.11.1\android_arm64_v8a"
$env:QT_HOST_PATH           = "D:\Qt\6.11.1\msvc2022_64"
$env:PATH                   = "D:\build-tools\ninja;" + $env:PATH

$cmakeExe = "D:\build-tools\cmake-3.31.12-windows-x86_64\bin\cmake.exe"
if (-not (Test-Path $cmakeExe)) {
    $cmakeExe = (Get-ChildItem "D:\build-tools" -Directory -Filter "cmake-*" |
        Sort-Object Name -Descending | Select-Object -First 1).FullName + "\bin\cmake.exe"
}

# ---------------------------------------------------------------- keystore
$keystoreDir = "D:\AndroidSDK\debug"
$keystore    = Join-Path $keystoreDir "debug.keystore"
if (-not (Test-Path $keystore)) {
    New-Item -ItemType Directory -Force -Path $keystoreDir | Out-Null
    & keytool -genkey -v `
        -keystore $keystore `
        -storepass android -alias androiddebugkey -keypass android `
        -keyalg RSA -keysize 2048 -validity 10000 `
        -dname "CN=Android Debug,O=CopterFilms,C=AR"
    if ($LASTEXITCODE -ne 0) { throw "keytool failed" }
}
$env:QT_ANDROID_KEYSTORE_PATH     = $keystore
$env:QT_ANDROID_KEYSTORE_ALIAS    = "androiddebugkey"
$env:QT_ANDROID_KEYSTORE_STORE_PASS = "android"
$env:QT_ANDROID_KEYSTORE_KEY_PASS   = "android"

# ---------------------------------------------------------------- configure
$root = $PSScriptRoot
$preset = "Android"
if ($Debug) { $preset = "Android-debug" }

if ($Clean -and (Test-Path (Join-Path $root "build\$preset"))) {
    Remove-Item -Recurse -Force (Join-Path $root "build\$preset")
}

& $cmakeExe --preset $preset `
    -DCMAKE_WARN_DEPRECATED=FALSE `
    -DCMAKE_TOOLCHAIN_FILE="$env:QT_TARGET_ROOT_DIR\lib\cmake\Qt6\qt.toolchain.cmake" `
    -DCMAKE_PREFIX_PATH="$env:QT_TARGET_ROOT_DIR" `
    -DQT_ANDROID_ABIS=arm64-v8a `
    -DQT_HOST_PATH="$env:QT_HOST_PATH" `
    -DQT_ANDROID_SIGN_APK=ON `
    -DQGC_CUSTOM_DIR=custom `
    -DGStreamer_ROOT_DIR="D:\gstreamer\arm64"
if ($LASTEXITCODE -ne 0) { throw "CMake configure failed" }

# ---------------------------------------------------------------- build
$env:GRADLE_OPTS = "-Dorg.gradle.daemon=false"
& $cmakeExe --build --preset $preset --parallel
if ($LASTEXITCODE -ne 0) { throw "Build failed" }

$apkDir = Join-Path $root "build\$preset\android-build"
$apks = Get-ChildItem $apkDir -Filter "*.apk" -Recurse -File
if (-not $apks) { throw "No APK produced under $apkDir" }
Write-Host ""
Write-Host "APK(s) produced:" -ForegroundColor Green
$apks | ForEach-Object { Write-Host "  $($_.FullName)  ($([math]::Round($_.Length/1MB,1)) MB)" -ForegroundColor Green }