#!/usr/bin/env bash
# GabeOS ISO Build Script
# Author: thesomewhatyou (GabrielDPP)
# Refactored to use local profile and apply optimizations

set -euo pipefail

# Root check
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "You must be root to execute this script" >&2
  exit 1
fi

# Function to check if a package is installed
is_installed() {
    pacman -Qi "$1" &>/dev/null
}

# Ensure archiso is installed
if ! is_installed archiso; then
    echo "archiso is not installed. Installing..."
    pacman -Sy --noconfirm archiso
else
    echo "archiso is already installed."
fi

# Performance Optimizations
# Use all cores for compilation (if any packages are built)
export MAKEFLAGS="-j$(nproc)"
# Use all cores for SquashFS creation
export MKSQUASHFS_PROCS=$(nproc)

# Output dir
mkdir -p ./out

# Create temporary directories
# WORK_DIR for mkarchiso working files
WORK_DIR=$(mktemp -d -t gabeos-build-XXXXXX)
# PROFILE_WORK_DIR for the modified profile
PROFILE_WORK_DIR=$(mktemp -d -t gabeos-profile-XXXXXX)

# Cleanup function to ensure temporary directories are removed
cleanup() {
    echo "Cleaning up..."
    if [[ -d "$PROFILE_WORK_DIR" ]]; then
        rm -rf "$PROFILE_WORK_DIR"
    fi
    if [[ -d "$WORK_DIR" ]]; then
        # Check if we want to keep it for debugging, but generally remove it
        # Uncomment the next line to keep work dir on failure
        # echo "Keeping work dir: $WORK_DIR"
        rm -rf "$WORK_DIR"
    fi
}
trap cleanup EXIT INT TERM

echo "Copying profile to temporary location: $PROFILE_WORK_DIR"
cp -a . "$PROFILE_WORK_DIR"

echo "Setting up permissions for user archie..."
# Fix permissions for archie's home directory recursively
if [[ -d "$PROFILE_WORK_DIR/airootfs/home/archie" ]]; then
    chown -R 1000:1000 "$PROFILE_WORK_DIR/airootfs/home/archie"
fi

echo "Building GabeOS ISO..."

# Build using the temporary profile directory
mkarchiso \
  -v \
  -m "iso" \
  -A "GabeOS Live ISO" \
  -L "GabeOS_$(date +%Y%m%d)" \
  -P "GabeOS" \
  -D "gabeos" \
  -w "$WORK_DIR" \
  -o ./out \
  "$PROFILE_WORK_DIR"

echo "Build complete. Output in ./out"
ls -la ./out
