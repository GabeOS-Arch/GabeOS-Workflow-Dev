#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="GabeOS_ISO"
iso_label="ARCH_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="GabeOS"
iso_application="GabeOS Live/Rescue Drive... Disk... idgaf"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.limine-bios.mbr' 'uefi-x64.limine-uefi.esp')

# Ensure Limine tooling is available when using Limine boot modes
if printf '%s\n' "${bootmodes[@]}" | grep -q 'limine'; then
  if ! command -v limine-install >/dev/null 2>&1; then
    echo "Error: Limine boot modes are configured in profiledef.sh, but 'limine-install' is not available in PATH." >&2
    echo "Please install the 'limine' package (or provide 'limine-install') on the build host/CI before running mkarchiso." >&2
    return 1 2>/dev/null || exit 1
  fi
fi

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
  ["/home/archie/.automated_script.sh"]="1000:1000:755"
  ["/home/archie/.config"]="1000:1000:755"
  ["/home/archie/Pictures"]="1000:1000:755"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
)
