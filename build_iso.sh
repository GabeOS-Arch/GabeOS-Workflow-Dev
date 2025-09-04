#!/usr/bin/env bash
# GabeOS ISO Build Script
# Author: thesomewhatyou (GabrielDPP)
#
# Builds a GabeOS-themed Arch ISO with mkarchiso.
# - Creates a temporary archiso profile based on releng
# - Applies branding (name/label/publisher/application/install_dir)
# - Optionally seeds Calamares placeholders (packages + config dirs)
# - Invokes mkarchiso with explicit parameters
#
# Requirements: run as root in a privileged Arch Linux container.

set -euo pipefail

# 0) Root check (mkarchiso needs root + mount caps)
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "You must be root to execute this script" >&2
  exit 1
fi

# 1) Ensure archiso is installed (safe if already present)
pacman -Sy --noconfirm archlinux-keyring >/dev/null 2>&1 || true
pacman -Syu --noconfirm archiso

# 2) Create a temporary profile from the official releng
PROFILE_DIR="$(mktemp -d -t gabeos-profile-XXXXXX)"
cleanup() {
  # mkarchiso -r cleans its own work dir; remove temp profile afterward
  rm -rf -- "$PROFILE_DIR"
}
trap cleanup EXIT

cp -a /usr/share/archiso/configs/releng/. "$PROFILE_DIR"/  # Known-good base profile [8]

# 3) “GabeOS” branding in profiledef.sh
#    - install_dir must be <=8 chars and [a-z0-9] only (mkarchiso constraint)
#    - iso_label can be anything reasonable; keep it simple
sed -i \
  -e 's/^iso_name=.*/iso_name="gabeos"/' \
  -e 's/^iso_label=.*/iso_label="GabeOS_2025_09_ByteBiter"/' \
  -e 's/^iso_publisher=.*/iso_publisher="GabeOS <https:\/\/example.com>"/' \
  -e 's/^iso_application=.*/iso_application="GabeOS Live ISO"/' \
  -e 's/^install_dir=.*/install_dir="gabeos"/' \
  "$PROFILE_DIR/profiledef.sh"  # profiledef.sh is authoritative for ISO metadata [21]

# 4) Optional: ensure a hostname and add a couple utilities
echo "GabeOS" > "$PROFILE_DIR/airootfs/etc/hostname"  # airootfs becomes live /etc/hostname [8]
# Append a couple of nice-to-haves if not present
if ! grep -q '^vim$' "$PROFILE_DIR/packages.x86_64"; then echo "vim" >> "$PROFILE_DIR/packages.x86_64"; fi
if ! grep -q '^htop$' "$PROFILE_DIR/packages.x86_64"; then echo "htop" >> "$PROFILE_DIR/packages.x86_64"; fi

# 5) Optional Calamares placeholders (commented by default)
# To actually include Calamares, provide a working calamares package (e.g., from AUR or a custom repo)
# and proper /etc/calamares configuration in the live root. See distro examples (ALCI, ArcoLinux). [3][17][18]
# Uncomment to seed directories for configs:
# mkdir -p "$PROFILE_DIR/airootfs/etc/calamares" \
#          "$PROFILE_DIR/airootfs/usr/share/calamares"
# echo "calamares" >> "$PROFILE_DIR/packages.x86_64"  # requires providing a repo/package first [3][18]

# 6) Prepare output directory and run mkarchiso with explicit parameters
mkdir -p ./out

mkarchiso \
  -v \
  -m "iso" \
  -A "GabeOS" \
  -L "GabeOS_2025_09_ByteBiter" \
  -P "GabeOS" \
  -D gabeos \
  -r \
  -w /tmp/ht-archiso \
  -o ./out \
  "$PROFILE_DIR"  # final arg must be the profile directory [22][8]

# 7) List the resulting ISO(s)
ls -la ./out
