# kali-cursor-fix

Fix for the missing mouse cursor in Kali Linux on VMware.

## What it does
- Removes `nomodeset` and `psmouse.proto=bare` from GRUB (if present)
- Blacklists the `vmwgfx` module
- Sets Xorg to use the `modesetting` driver with a software cursor

Safe to run multiple times.

## Usage
If the mouse is invisible, press Ctrl+Alt+F3 to open a TTY and log in, then:

    curl -O https://raw.githubusercontent.com/GlitchBelyi/kali-cursor-fix/main/fix-cursor_VM.sh
    sudo bash fix-cursor_VM.sh

Reboot when prompted.

## Notes
- Take a VM snapshot before running.
- In VMware, turn off "Accelerate 3D graphics".
- Side effect: no 3D acceleration, and screen auto-resize may not work.
- Tested on Kali 2026.1 with VMware Workstation only.

## Revert
    sudo rm /etc/modprobe.d/blacklist-vmwgfx.conf
    sudo rm /etc/X11/xorg.conf.d/10-modesetting.conf
    sudo update-initramfs -u && sudo reboot

Use at your own risk.
