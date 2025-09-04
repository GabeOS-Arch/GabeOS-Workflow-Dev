#!/bin/bash
# GabeOS ISO Build Script
# Author: thesomewhatyou (GabrielDPP)
#
# This script builds a GabeOS-themed Arch-based ISO using mkarchiso and Calamares

if [[ $EUID -ne 0 ]]; then
  echo "You must be root to execute this script"
  exit 1
fi

# Set theme variables
ISO_NAME="GabeOS"
WORK_DIR="/tmp/gabeos-archiso"
OUT_DIR="out"
PROFILE_DIR="."

# Build the ISO with mkarchiso (modern syntax)
mkarchiso build -v -w "$WORK_DIR" -o "$OUT_DIR" -P "$PROFILE_DIR"

echo "GabeOS ISO build complete! Output is in $OUT_DIR."