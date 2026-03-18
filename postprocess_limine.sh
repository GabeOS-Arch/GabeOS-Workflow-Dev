#!/usr/bin/env bash
# postprocess_limine.sh – Inject Limine BIOS + UEFI boot into the GabeOS ISO.
#
# Called by build_iso.sh immediately after mkarchiso completes.
# Requires (must be installed in the build environment):
#   xorriso   – extract ISO and rebuild with new boot parameters
#   limine    – provides boot binaries and the 'limine bios-install' command
#
# What it does:
#   1. Extracts the ISO produced by mkarchiso (out/*.iso) to a temp directory.
#   2. Copies Limine BIOS + UEFI boot files into a limine/ sub-directory.
#   3. Writes a limine.conf from the repo template, substituting real values.
#   4. Rebuilds the ISO with xorriso using Limine El Torito / UEFI boot entries.
#   5. Runs 'limine bios-install' to embed the BIOS stage into the ISO.
#   6. Replaces the original ISO so the upload step picks it up automatically.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/out"

# Profile constants (must match profiledef.sh)
INSTALL_DIR="arch"
ARCH="x86_64"

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------
for cmd in xorriso limine; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
        echo "ERROR: Required tool not found in PATH: ${cmd}" >&2
        exit 1
    fi
done

LIMINE_SHARE="/usr/share/limine"
for f in \
    "${LIMINE_SHARE}/limine-bios-cd.bin" \
    "${LIMINE_SHARE}/limine-uefi-cd.bin" \
    "${LIMINE_SHARE}/limine-bios.sys"; do
    if [[ ! -f "${f}" ]]; then
        echo "ERROR: Required Limine file not found: ${f}" >&2
        exit 1
    fi
done

# ---------------------------------------------------------------------------
# Locate source ISO
# ---------------------------------------------------------------------------
ISO_FILES=( "${OUT_DIR}"/*.iso )
ISO_FILE="${ISO_FILES[0]:-}"
if [[ -z "${ISO_FILE}" || ! -f "${ISO_FILE}" ]]; then
    echo "ERROR: No ISO found in ${OUT_DIR}/" >&2
    exit 1
fi

echo "=== Limine Post-Processing ==="
echo "Input ISO : ${ISO_FILE}"

# ---------------------------------------------------------------------------
# Extract ISO contents
# ---------------------------------------------------------------------------
WORK_DIR=$(mktemp -d -t limine-pp-XXXXXX)
trap 'echo "Cleaning up ${WORK_DIR}..."; rm -rf "${WORK_DIR}"' EXIT INT TERM

ISO_ROOT="${WORK_DIR}/isoroot"
mkdir -p "${ISO_ROOT}"

echo "Extracting ISO to ${ISO_ROOT} ..."
xorriso -osirrox on \
    -indev "${ISO_FILE}" \
    -extract / "${ISO_ROOT}" \
    -- 2>/dev/null

# Ensure we can write into the extracted tree
chmod -R u+rwX "${ISO_ROOT}"

# ---------------------------------------------------------------------------
# Determine ARCHISO_UUID from the grub.cfg that mkarchiso already substituted
# ---------------------------------------------------------------------------
ISO_UUID=""
GRUB_CFG="${ISO_ROOT}/boot/grub/grub.cfg"
if [[ -f "${GRUB_CFG}" ]]; then
    ISO_UUID=$(grep -oP 'archisosearchuuid=\K[^[:space:]]+' "${GRUB_CFG}" | head -n1 || true)
fi
if [[ -z "${ISO_UUID}" ]]; then
    echo "WARNING: Could not read ARCHISO_UUID from ${GRUB_CFG}; boot entries will lack UUID search" >&2
fi
echo "ARCHISO_UUID: ${ISO_UUID:-<not found>}"

# ---------------------------------------------------------------------------
# Place Limine boot files in ISO root
# ---------------------------------------------------------------------------
LIMINE_DIR="${ISO_ROOT}/limine"
mkdir -p "${LIMINE_DIR}"

cp "${LIMINE_SHARE}/limine-bios-cd.bin" "${LIMINE_DIR}/"
cp "${LIMINE_SHARE}/limine-uefi-cd.bin" "${LIMINE_DIR}/"
cp "${LIMINE_SHARE}/limine-bios.sys"    "${LIMINE_DIR}/"

# ---------------------------------------------------------------------------
# Write limine.conf (substitute template variables)
# ---------------------------------------------------------------------------
# Build the UUID kernel parameter; omit it entirely when the UUID is unknown
# to avoid passing a literal empty 'archisosearchuuid=' on the kernel cmdline.
if [[ -n "${ISO_UUID}" ]]; then
    UUID_PARAM="archisosearchuuid=${ISO_UUID} "
else
    UUID_PARAM=""
fi

TEMPLATE_CONF="${SCRIPT_DIR}/limine/limine.conf"
if [[ -f "${TEMPLATE_CONF}" ]]; then
    sed \
        -e "s|%INSTALL_DIR%|${INSTALL_DIR}|g" \
        -e "s|%ARCH%|${ARCH}|g" \
        -e "s|%ARCHISO_UUID%|${ISO_UUID}|g" \
        "${TEMPLATE_CONF}" > "${LIMINE_DIR}/limine.conf"
else
    echo "WARNING: ${TEMPLATE_CONF} not found; writing a minimal limine.conf" >&2
    cat > "${LIMINE_DIR}/limine.conf" <<EOF
# GabeOS Limine Boot Configuration (auto-generated)
timeout: 10

:GabeOS Live (${ARCH})
    protocol: linux
    kernel_path: boot():/${INSTALL_DIR}/boot/${ARCH}/vmlinuz-linux-zen
    module_path: boot():/${INSTALL_DIR}/boot/${ARCH}/initramfs-linux-zen.img
    cmdline: archisobasedir=${INSTALL_DIR} ${UUID_PARAM}cow_spacesize=4G mitigations=off quiet splash

:GabeOS - Low Memory Mode
    protocol: linux
    kernel_path: boot():/${INSTALL_DIR}/boot/${ARCH}/vmlinuz-linux-zen
    module_path: boot():/${INSTALL_DIR}/boot/${ARCH}/initramfs-linux-zen.img
    cmdline: archisobasedir=${INSTALL_DIR} ${UUID_PARAM}cow_spacesize=2G mitigations=off systemd.unit=multi-user.target

:GabeOS - Safe Mode (nomodeset)
    protocol: linux
    kernel_path: boot():/${INSTALL_DIR}/boot/${ARCH}/vmlinuz-linux-zen
    module_path: boot():/${INSTALL_DIR}/boot/${ARCH}/initramfs-linux-zen.img
    cmdline: archisobasedir=${INSTALL_DIR} ${UUID_PARAM}cow_spacesize=4G nomodeset mitigations=off
EOF
fi

# ---------------------------------------------------------------------------
# Rebuild ISO with Limine BIOS + UEFI boot
# ---------------------------------------------------------------------------
OUTPUT_ISO="${WORK_DIR}/output.iso"
echo "Building Limine-bootable ISO: ${OUTPUT_ISO}"

xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -joliet -joliet-long \
    -rational-rock \
    -b limine/limine-bios-cd.bin \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    --efi-boot limine/limine-uefi-cd.bin \
    -efi-boot-part \
    --efi-boot-image \
    --protective-msdos-label \
    -o "${OUTPUT_ISO}" \
    "${ISO_ROOT}"

# ---------------------------------------------------------------------------
# Install Limine BIOS stage into the ISO
# ---------------------------------------------------------------------------
echo "Installing Limine BIOS bootloader stage..."
limine bios-install "${OUTPUT_ISO}"

# ---------------------------------------------------------------------------
# Replace original ISO
# ---------------------------------------------------------------------------
echo "Replacing original ISO with Limine-enabled ISO..."
mv "${OUTPUT_ISO}" "${ISO_FILE}"

echo "=== Limine post-processing complete ==="
echo "Output ISO: ${ISO_FILE}"
ls -lh "${ISO_FILE}"
