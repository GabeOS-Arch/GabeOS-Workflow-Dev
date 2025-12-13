#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="GabeOS_iso"
iso_label="ARCH_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="GabeOS"
iso_application="GabeOS Live/Rescue Drive... Disk... idgaf"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
# Bootloader contract: mkarchiso/systemd-boot populate the ESP; build_iso.sh leaves EFI/BOOT untouched.
bootmodes=('bios.syslinux.mbr' 'uefi-x64.systemd-boot.esp')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'lz4' '-Xhc' '-b' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '-6')
file_permissions=(
  ["/etc/shadow"]="0:0:0400"
  ["/etc/gshadow"]="0:0:0400"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/root/.gnupg"]="0:0:700"
  ["/home/archie"]="1000:1000:750"
  ["/home/archie/.zlogin"]="1000:1000:644"
  ["/home/archie/.config"]="1000:1000:755"
  ["/home/archie/Pictures"]="1000:1000:755"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
)
