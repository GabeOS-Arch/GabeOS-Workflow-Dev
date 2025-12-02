# Boot Options for GabeOS

This document describes the available boot options and their purposes.

## Quick Start - VM Users

If you're testing GabeOS in a VM:
1. **2-3GB RAM?** → Use "Low Memory Mode" boot option
2. **4GB+ RAM?** → Use default boot option
3. **Graphics issues?** → Use "Safe Mode (nomodeset)" boot option

The ISO now includes automatic compressed swap (ZRAM) to handle low-memory situations gracefully.

## Default Boot Entry

**🚀 Arch Linux (Standard Boot)**
- Boots into full Hyprland desktop environment
- Uses 4GB Copy-on-Write (CoW) space for system modifications
- Disables CPU mitigations for better VM performance
- Debug logging enabled

**Boot parameters:**
- `cow_spacesize=4G` - Allocates 4GB for the overlay filesystem (stores changes made during the live session)
- `mitigations=off` - Disables CPU security mitigations (Spectre/Meltdown) for better VM performance
- `debug` - Enables verbose kernel logging for troubleshooting

## Low Memory Mode

**🐏 Arch Linux - Low Memory Mode**
- Boots into multi-user.target (console/TTY only, no GUI)
- Uses only 2GB CoW space
- Ideal for systems with 2GB RAM or less, or troubleshooting
- Can start Hyprland manually with `systemctl start display-manager`

**Boot parameters:**
- `cow_spacesize=2G` - Reduced CoW space for low-memory systems
- `systemd.unit=multi-user.target` - Skips graphical.target, boots to console
- `mitigations=off` - Disables CPU security mitigations
- `debug` - Enables verbose kernel logging

## Safe Mode

**🔧 Arch Linux - Safe Mode (nomodeset)**
- Uses basic framebuffer instead of GPU drivers
- Useful for systems with problematic graphics cards
- Uses 4GB CoW space
- Good for older hardware or driver issues

**Boot parameters:**
- `nomodeset` - Disables kernel mode setting, uses basic VESA/framebuffer
- `cow_spacesize=4G` - Standard CoW space allocation
- `mitigations=off` - Disables CPU security mitigations
- `debug` - Enables verbose kernel logging

## VM Compatibility

The ISO is optimized for VM environments with:
- Hardware cursor emulation disabled in Hyprland
- Software rendering fallback enabled
- DRM modifier support disabled for better compatibility
- Proper QXL driver support for QEMU/KVM

## Live RAM Optimizations

To reduce memory pressure, the live system now enables compressed swap using `systemd-zram-generator`:
- Automatically creates a `zram0` swap device sized to half of available RAM
- Uses the `zstd` compression algorithm for a good balance of speed and ratio
- Gives low-memory VMs an extra safety net without touching the disk
- Activates before the graphical session starts so Hyprland has more headroom

No manual steps are required—zram swap is enabled on every boot (including installed systems if you retain the config).

## Memory Requirements

### Minimum Requirements:
- **Standard Boot**: 4GB RAM (2GB minimum with swap)
- **Low Memory Mode**: 2GB RAM (1GB minimum with swap)
- **Safe Mode**: 4GB RAM (2GB minimum with swap)

### Recommended Requirements:
- **Standard Boot**: 8GB+ RAM for comfortable usage
- **VM Testing**: 4GB+ RAM allocated to VM
- **Installation**: 8GB+ RAM recommended

## Troubleshooting

### System Freezes During Boot
1. Try **Low Memory Mode** first
2. If still freezing, try **Safe Mode**
3. Check VM settings: ensure VT-x/AMD-V is enabled
4. Increase VM RAM allocation to at least 4GB

### Invisible or Corrupted Cursor in VM
- This should be fixed automatically with `no_hardware_cursors=true`
- If issues persist, set `env = LIBGL_ALWAYS_SOFTWARE,1` in Hyprland config

### Out of Memory Errors
- Boot into **Low Memory Mode**
- Or add `cow_spacesize=1G` to reduce memory usage further
- Close unnecessary applications
- Install to disk for full system performance

### Graphics Issues
- Use **Safe Mode (nomodeset)** for basic display
- Check if VM has 3D acceleration enabled
- Try different VM graphics adapters (QXL, VirtIO, VMSVGA)

## Advanced Boot Parameters

You can add these manually by pressing 'e' in GRUB or 'Tab' in SYSLINUX:

- `copytoram` - Copy entire ISO to RAM (requires 4GB+ RAM, much faster but uses more memory)
- `cow_spacesize=<size>` - Change overlay size (1G, 2G, 4G, 8G, etc.)
- `systemd.unit=rescue.target` - Boot to rescue mode
- `systemd.unit=emergency.target` - Boot to emergency mode
- `quiet` - Reduce kernel messages (remove `debug` first)
- `loglevel=3` - Reduce kernel log verbosity
- `nomodeset` - Disable kernel mode setting
- `video=<mode>` - Force specific video resolution
- `mem=<size>` - Limit available memory (for testing low-memory scenarios)

## Post-Boot Optimization

After booting, you can optimize memory usage by:

1. **Disable compositor effects** (if using Low Memory Mode with GUI):
   ```bash
   systemctl start display-manager
   # In Hyprland, compositor is always active but lightweight
   ```

2. **Close unnecessary applications**:
   - Waybar, swaync can be stopped if not needed
   - Close librewolf or other browsers

3. **Check memory usage**:
   ```bash
   free -h
   htop
   systemd-cgtop
   ```

4. **Clear package cache**:
   ```bash
   sudo pacman -Scc
   ```
