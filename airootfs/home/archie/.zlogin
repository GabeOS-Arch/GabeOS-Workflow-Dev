# fix for screen readers
if grep -Fqa 'accessibility=' /proc/cmdline &> /dev/null; then
    setopt SINGLE_LINE_ZLE
fi
# why do we bother for the screen readers? ¯\_(ツ)_/¯
# hypr, afaik, doesn't even DO well with screen readers.
# keeping this so i hope it works

~/.automated_script.sh

# Auto-start Hyprland on tty1
if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
    exec Hyprland
fi
