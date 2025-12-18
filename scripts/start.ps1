# W.A.C.H. - Start Script
# Usage: .\scripts\start.ps1 [platform]
# Platforms: android, ios, web, chrome, windows, macos, linux

param(
    [string]$Platform = "chrome",
    [switch]$Release,
    [switch]$Profile,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$FlutterPath = "C:\Sources\Flutter\flutter\bin\flutter.bat"
$ProjectPath = "$PSScriptRoot\..\wach_flutter"

# Colors
function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Cyan }
function Write-Success { Write-Host "[OK] $args" -ForegroundColor Green }
function Write-Warn { Write-Host "[WARN] $args" -ForegroundColor Yellow }
function Write-Err { Write-Host "[ERROR] $args" -ForegroundColor Red }

# Header
Write-Host ""
Write-Host "  W.A.C.H. - Workout Awareness & Continuous Health" -ForegroundColor Green
Write-Host "  =================================================" -ForegroundColor Green
Write-Host ""

# Check Flutter
Write-Info "Checking Flutter..."
if (-not (Test-Path $FlutterPath)) {
    Write-Err "Flutter not found at $FlutterPath"
    Write-Info "Please update FlutterPath in this script"
    exit 1
}
Write-Success "Flutter found"

# Check project
Write-Info "Checking project..."
if (-not (Test-Path "$ProjectPath\pubspec.yaml")) {
    Write-Err "Project not found at $ProjectPath"
    exit 1
}
Write-Success "Project found"

# Get dependencies
Write-Info "Getting dependencies..."
Push-Location $ProjectPath
& $FlutterPath pub get
if ($LASTEXITCODE -ne 0) {
    Write-Err "Failed to get dependencies"
    Pop-Location
    exit 1
}
Write-Success "Dependencies ready"

# Build arguments
$BuildArgs = @()
if ($Release) { $BuildArgs += "--release" }
if ($Profile) { $BuildArgs += "--profile" }
if ($Verbose) { $BuildArgs += "--verbose" }

# Start backends (placeholder for future)
Write-Info "Starting backends..."
# TODO: Add backend services here when needed
# Example: Start-Process -FilePath "docker" -ArgumentList "compose up -d"
Write-Success "No backends required (offline-first)"

# Run app
Write-Host ""
Write-Info "Starting W.A.C.H. on $Platform..."
Write-Host ""

$DeviceArg = switch ($Platform.ToLower()) {
    "chrome"  { "-d chrome" }
    "web"     { "-d web-server --web-port=8080" }
    "android" { "-d android" }
    "ios"     { "-d ios" }
    "windows" { "-d windows" }
    "macos"   { "-d macos" }
    "linux"   { "-d linux" }
    default   { "-d chrome" }
}

$FullArgs = "run $DeviceArg $($BuildArgs -join ' ')"
Write-Info "Command: flutter $FullArgs"
Write-Host ""

& $FlutterPath run $DeviceArg.Split(' ') @BuildArgs

Pop-Location
