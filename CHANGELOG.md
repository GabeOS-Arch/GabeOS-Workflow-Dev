# Changelog

## [Unreleased]
### Added
- New boot menu entries for low-memory and safe-mode scenarios on both GRUB and SYSLINUX loaders
- BOOT_OPTIONS.md reference guide for ISO boot parameters and VM troubleshooting
- IMPROVEMENTS.md technical summary of RAM-related fixes and optimizations
- systemd-zram-generator-based swap configuration for the live environment

### Changed
- Default boot entries now allocate larger CoW space and disable CPU mitigations for better VM performance
- Initramfs compression switched to fast ZSTD (`-3 -T0`) for lower memory footprint during boot
- Hyprland initial-boot script hardened with better error handling and quoting

