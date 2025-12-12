# Plan: Substitute GRUB with Limine

## Current boot setup
- GRUB is enabled for UEFI via `bootmodes=('bios.syslinux.mbr' 'uefi-x64.grub.esp')` in `profiledef.sh`, with menu definitions in `grub/`.
- Systemd-boot style entries live under `efiboot/loader/entries/`, and BIOS uses Syslinux configs in `syslinux/`.
- Packages include both `grub` and `syslinux` (see `packages.x86_64`), and the build is orchestrated by `build_iso.sh`.

## Migration steps
1. **Packages**: Replace `grub` (and related dependencies like `os-prober`) with `limine` in `packages.x86_64` while keeping `syslinux` for BIOS. Ensure `limine` binaries (`limine-bios.sys`, `limine-bios-cd.bin`, `limine-uefi-cd.bin`, `BOOTX64.EFI`) are available in the build environment.
2. **Boot mode definition**: Switch UEFI boot mode from GRUB to Limine in `profiledef.sh` (e.g., `'bios.syslinux.mbr' 'uefi-x64.limine.esp'`). If archiso lacks a preset, stage Limine files manually in the profile so mkarchiso picks them up.
3. **Limine configuration**: Add a `limine.cfg` mirroring current entries (GabeOS linux-zen, speech/accessible entry if desired, memtest, UEFI shell, reboot/shutdown) using the same `%INSTALL_DIR%`/`%ARCHISO_UUID%` variables.
4. **Image staging**: Place Limine loader assets in the EFI and ISO root equivalents (`efiboot/EFI/BOOT/BOOTX64.EFI`, Limine BIOS/UEFI CD binaries at the root) and remove/stop installing GRUB themes/configs. Ensure kernel/initramfs paths remain `/arch/boot/x86_64/…`.
5. **Build script updates**: In `build_iso.sh`, copy Limine assets from the host package into the temporary profile before invoking `mkarchiso`, then post-process the produced ISO with `limine bios-install` (covers both BIOS/UEFI images per upstream docs).
6. **Verification**: Boot the produced ISO in both OVMF (UEFI) and SeaBIOS QEMU runs, verifying each menu entry, memtest, and the UEFI shell chainloader. Confirm secure boot expectations (likely unchanged/off) and that Syslinux BIOS path still works as fallback.

## Rollout notes
- Keep Syslinux for BIOS initially to minimize risk; swap it only after Limine BIOS flow is proven.
- Retire GRUB assets (`grub/` directory, bootmode entry) once Limine boots successfully in both firmware modes.
- Document any manual steps or mkarchiso workarounds in `README.md` after implementation.
