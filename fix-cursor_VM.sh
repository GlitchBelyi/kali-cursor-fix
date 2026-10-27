#!/bin/bash
# fix-cursor.sh
# Fixes the invisible mouse cursor in Kali Linux on VMware:
#   - removes "nomodeset" and "psmouse.proto=bare" from GRUB
#   - blacklists the vmwgfx kernel module
#   - configures Xorg to use the modesetting driver with a software cursor
# Safe to run multiple times: it only changes things that need changing.

set -e

if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo: sudo bash $0"
    exit 1
fi

# Warn if this does not look like a VMware guest
if command -v systemd-detect-virt >/dev/null 2>&1; then
    VIRT=$(systemd-detect-virt || true)
    if [ "$VIRT" != "vmware" ]; then
        echo "Detected virtualization: ${VIRT:-none} (this script targets VMware)."
        read -p "Continue anyway? (y/n): " a
        if [ "$a" != "y" ]; then
            exit 1
        fi
    fi
fi

GRUB=/etc/default/grub
BL=/etc/modprobe.d/blacklist-vmwgfx.conf
XC=/etc/X11/xorg.conf.d/10-modesetting.conf
CHANGED_GRUB=0
CHANGED_INITRAMFS=0

# --- 1. GRUB: remove nomodeset and psmouse options, only if present ---
if grep -Eq 'nomodeset|psmouse.proto=bare' "$GRUB"; then
    echo "[1/3] Fixing GRUB (backup will be created)..."
    cp "$GRUB" "$GRUB.bak.$(date +%F-%H%M%S)"
    sed -i 's/ nomodeset//; s/nomodeset //; s/ psmouse.proto=bare//' "$GRUB"
    CHANGED_GRUB=1
else
    echo "[1/3] GRUB is already clean, skipping."
fi
grep '^GRUB_CMDLINE_LINUX_DEFAULT' "$GRUB"

# --- 2. Blacklist vmwgfx ---
if [ "$(cat "$BL" 2>/dev/null)" = "blacklist vmwgfx" ]; then
    echo "[2/3] vmwgfx is already blacklisted, skipping."
else
    echo "[2/3] Blacklisting vmwgfx..."
    echo "blacklist vmwgfx" > "$BL"
    CHANGED_INITRAMFS=1
fi

# --- 3. Xorg: modesetting driver + software cursor ---
NEW_CONF='Section "Device"
    Identifier "Card0"
    Driver "modesetting"
    Option "SWCursor" "true"
EndSection'

if [ "$(cat "$XC" 2>/dev/null)" = "$NEW_CONF" ]; then
    echo "[3/3] Xorg config is already correct, skipping."
else
    echo "[3/3] Writing Xorg config..."
    mkdir -p /etc/X11/xorg.conf.d
    # remove only conflicting configs (vmware/fbdev drivers), not all files
    for f in /etc/X11/xorg.conf.d/*.conf; do
        if [ -e "$f" ] && [ "$f" != "$XC" ] && grep -qE 'Driver +"(vmware|fbdev)"' "$f"; then
            rm -f "$f"
        fi
    done
    echo "$NEW_CONF" > "$XC"
    CHANGED_INITRAMFS=1
fi

# --- Apply changes only when needed ---
if [ $CHANGED_INITRAMFS -eq 1 ]; then
    echo "Updating initramfs..."
    update-initramfs -u
fi
if [ $CHANGED_GRUB -eq 1 ]; then
    echo "Updating GRUB..."
    update-grub
fi

echo
if [ $CHANGED_GRUB -eq 0 ] && [ $CHANGED_INITRAMFS -eq 0 ]; then
    echo "No changes were needed, everything is already configured."
else
    echo "Done."
    read -p "Reboot now? (y/n): " ans
    if [ "$ans" = "y" ]; then
        reboot
    fi
fi