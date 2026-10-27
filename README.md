# kali-cursor-fix

Fix for the missing mouse cursor in Kali Linux on VMware.

## What it does
- Removes `nomodeset` and `psmouse.proto=bare` from GRUB (if present)
- Blacklists the `vmwgfx` module
- Sets Xorg to use the `modesetting` driver with a software cursor

## Usage
1. Download `fix-cursor_VM.sh` from this repository (click the file, then "Download raw file").
2. Open a terminal in the folder where the file is saved and run:

       sudo bash fix-cursor_VM.sh

3. Reboot when the script asks.

If the mouse is invisible, press Ctrl+Alt+F3 to open a TTY and log in with the keyboard first.

One run + reboot is enough. Running it again is harmless (it skips what is already done).

## Notes
- Take a VM snapshot before running.
- In VMware, turn off "Accelerate 3D graphics".
- Side effect: no 3D acceleration, and screen auto-resize may not work.
- Tested on Kali 2026.1 with VMware Workstation only.

## Revert
    sudo rm /etc/modprobe.d/blacklist-vmwgfx.conf
    sudo rm /etc/X11/xorg.conf.d/10-modesetting.conf
    sudo update-initramfs -u && sudo reboot

## License
MIT. Use at your own risk.
