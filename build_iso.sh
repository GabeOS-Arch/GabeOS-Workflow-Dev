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

# Ensure archiso is installed
pacman -Sy --noconfirm archlinux-keyring >/dev/null 2>&1 || true
pacman -Syu --noconfirm archiso

# Performance Optimizations
# Use all cores for compilation (if any packages are built, though archiso mostly installs binary pkgs)
export MAKEFLAGS="-j$(nproc)"
# Use all cores for SquashFS creation
export MKSQUASHFS_PROCS=$(nproc)

# Output dir
mkdir -p ./out

# Clean up previous work dir if it exists to avoid conflicts
rm -rf /tmp/archiso-work

# Create a temporary working directory for the profile
# This allows us to modify permissions without affecting the git repository
PROFILE_WORK_DIR=$(mktemp -d /tmp/gabeos-profile-XXXXXX)
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
  -w /tmp/archiso-work \
  -o ./out \
  "$PROFILE_WORK_DIR"

# Cleanup
rm -rf "$PROFILE_WORK_DIR"


echo "Build complete. Output in ./out"
ls -la ./out
