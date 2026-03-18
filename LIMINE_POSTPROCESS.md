# Limine Post-Processing

This document explains how Limine UEFI boot support is added to the GabeOS ISO
and why the approach requires a two-stage build.

> **GabeOS is UEFI-only.** No BIOS/legacy or CSM boot support is provided.

---

## Why bootmodes were changed in profiledef.sh

`mkarchiso` (from the `archiso` package in the Arch Linux repositories) validates
the `bootmodes` array in `profiledef.sh` against a hard-coded list of supported
identifiers.  Limine-specific identifiers such as:

```
uefi-x64.limine-uefi.esp
```

are **not** in that list for the version currently shipped in the Arch repos.
Specifying them causes `mkarchiso` to abort immediately with:

```
[mkarchiso] ERROR: uefi-x64.limine-uefi.esp is not a valid boot mode!
```

…before any ISO is generated.

### Solution

`profiledef.sh` now declares the standard UEFI GRUB bootmode:

```bash
bootmodes=('uefi-x64.grub.esp')
```

This uses the GRUB (UEFI) assets that are already present in the repository
(`grub/`, `efiboot/`).  `mkarchiso` builds the ISO successfully, and then the
Limine post-processing step replaces the GRUB bootloader with Limine UEFI.

---

## How the Limine post-processing works (`postprocess_limine.sh`)

`build_iso.sh` calls `postprocess_limine.sh` immediately after `mkarchiso`
completes.  The script performs the following steps:

1. **Locate the ISO** – finds `out/*.iso` produced by `mkarchiso`.
2. **Extract ISO contents** – uses `xorriso -osirrox` to unpack the entire
   ISO tree into a temporary directory, preserving all files (squashfs images,
   kernel, initramfs, GRUB configs, etc.).
3. **Read ARCHISO_UUID** – extracts the UUID that `mkarchiso` already
   substituted into `/boot/grub/grub.cfg` inside the ISO.  This UUID is needed
   by the Arch Linux initramfs to locate the root filesystem at boot time.
4. **Place Limine UEFI boot file** – copies one file from `/usr/share/limine/`
   into a `limine/` sub-directory of the extracted ISO root:
   - `limine-uefi-cd.bin` – UEFI El Torito / GPT boot image
5. **Write `limine/limine.conf`** – substitutes `%INSTALL_DIR%`, `%ARCH%`, and
   `%ARCHISO_UUID%` in `limine/limine.conf` from the repository template.
6. **Rebuild ISO** – calls `xorriso -as mkisofs` with the Limine UEFI boot
   entry only:
   ```
   --efi-boot limine/limine-uefi-cd.bin   (UEFI El Torito / GPT boot image)
   ```
   No BIOS/MBR boot catalog or `--protective-msdos-label` is added.
7. **Replace original ISO** – moves the rebuilt ISO back to `out/`, so the
   existing upload step (which expects `out/*.iso`) continues to work without
   any changes.

### Required packages

| Package     | Purpose                             |
|-------------|-------------------------------------|
| `limine`    | UEFI boot binary                    |
| `xorriso`   | Extracting and rebuilding the ISO   |
| `mtools`    | (Transitive dep; FAT image support) |
| `dosfstools`| FAT filesystem utilities (ESP)      |

These are installed by the GitHub Actions workflow step alongside `archiso`.

---

## Running locally

You need an Arch Linux (or Arch-based) build host with the following packages:

```bash
sudo pacman -S --noconfirm archiso limine xorriso mtools dosfstools \
    grub edk2-shell memtest86+
```

Then run the build as root from the repository root:

```bash
sudo ./build_iso.sh
```

The script:
1. Calls `mkarchiso` to build the initial ISO into `out/`.
2. Calls `postprocess_limine.sh` to inject the Limine UEFI bootloader and
   replace the ISO in `out/`.

The final ISO in `out/` boots **only on UEFI hardware** using the Limine
bootloader and presents the GabeOS Limine boot menu (`limine/limine.conf`).
