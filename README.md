# GabeOS-Workflow-Dev

This repository contains the development files and resources for the GabeOS project. It includes scripts, configurations, and more for maintaining the GabeOS system.

Yes yes very nice yes.

## System Requirements – UEFI Only

> **GabeOS is UEFI-only. Legacy BIOS / CSM boot is not supported.**

| Requirement | Details |
|---|---|
| Firmware | UEFI (disable CSM/Legacy boot in firmware settings) |
| Partition table | GPT |
| EFI System Partition | FAT32, minimum 512 MiB, mounted at `/boot/efi` |
| Bootloader | GRUB (`x86_64-efi` target) |
| Secure Boot | Not implemented – disable Secure Boot or use Setup Mode |

### Troubleshooting

- **System won't boot from USB** – Ensure your firmware is set to UEFI mode and CSM/Legacy boot is disabled. The USB must be booted from the UEFI boot menu entry (not a legacy entry).
- **"This media requires UEFI firmware" error** – You are booting in legacy BIOS mode. Enter your firmware settings, enable UEFI, and disable CSM.
- **Calamares installer fails at the UEFI check** – Same as above; the installer detected it is not running under UEFI firmware.
- **GRUB install fails** – Make sure an EFI System Partition (type `EF00`, FAT32) exists on a GPT disk and is mounted at `/boot/efi` before installation.
- **Secure Boot** – GabeOS does not ship signed kernels. Disable Secure Boot in your firmware if it prevents booting.

# Contents

A workflow which deploys to GCS buckets (Switch variably depending on your needs). Ran by GitHub Actions.

This is... totally more serious from what I normally do, but idgaf. :octocat: :3c

# License

Whatever the fuck Arch Linux uses.

# OwO why did you make this pubwic?

 \_(^q^)_/

Why didn't I update the README.md after making this public?

Crack. That's why. Crack. 
