#!/bin/bash
# W.A.C.H. - Start Script (Unix)
# Usage: ./scripts/start.sh [platform]
# Platforms: android, ios, web, chrome, windows, macos, linux

set -e

PLATFORM="${1:-chrome}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_PATH="$SCRIPT_DIR/../wach_flutter"
FLUTTER_PATH="${FLUTTER_PATH:-flutter}"

# Colors
info() { echo -e "\033[36m[INFO]\033[0m $*"; }
success() { echo -e "\033[32m[OK]\033[0m $*"; }
warn() { echo -e "\033[33m[WARN]\033[0m $*"; }
error() { echo -e "\033[31m[ERROR]\033[0m $*"; }

# Header
echo ""
echo -e "\033[32m  W.A.C.H. - Workout Awareness & Continuous Health\033[0m"
echo -e "\033[32m  =================================================\033[0m"
echo ""

# Check Flutter
info "Checking Flutter..."
if ! command -v $FLUTTER_PATH &> /dev/null; then
    error "Flutter not found. Please install Flutter or set FLUTTER_PATH"
    exit 1
fi
success "Flutter found: $($FLUTTER_PATH --version | head -1)"

# Check project
info "Checking project..."
if [ ! -f "$PROJECT_PATH/pubspec.yaml" ]; then
    error "Project not found at $PROJECT_PATH"
    exit 1
fi
success "Project found"

# Get dependencies
info "Getting dependencies..."
cd "$PROJECT_PATH"
$FLUTTER_PATH pub get
success "Dependencies ready"

# Start backends (placeholder)
info "Starting backends..."
# TODO: Add backend services here when needed
# Example: docker compose up -d
success "No backends required (offline-first)"

# Device argument
case "${PLATFORM,,}" in
    chrome)  DEVICE="-d chrome" ;;
    web)     DEVICE="-d web-server --web-port=8080" ;;
    android) DEVICE="-d android" ;;
    ios)     DEVICE="-d ios" ;;
    windows) DEVICE="-d windows" ;;
    macos)   DEVICE="-d macos" ;;
    linux)   DEVICE="-d linux" ;;
    *)       DEVICE="-d chrome" ;;
esac

# Run
echo ""
info "Starting W.A.C.H. on $PLATFORM..."
info "Command: flutter run $DEVICE"
echo ""

$FLUTTER_PATH run $DEVICE
