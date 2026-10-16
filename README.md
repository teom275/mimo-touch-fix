# Mimo Touch Screen Mapping Fix for Windows

Utility to fix the issue where touching an external USB Mimo touchscreen clicks on the primary monitor (or at the current mouse cursor location) instead of interacting directly on the Mimo display.

---

## Technical Overview

In Windows, the mapping between HID touch digitizers and physical display monitors is stored in the **WISP** subsystem registry:
```
HKLM\SOFTWARE\Microsoft\Wisp\Pen\Digimon
```

When a USB touch display is reconnected to a different USB port or hub, Windows generates a new hardware instance path (PnP Instance ID). If this new path is not yet mapped in `Digimon`:
1. Windows fails to link the touch digitizer with the secondary display.
2. Touch input falls back to the **Primary Monitor**.
3. Touches are sent as left-clicks at the cursor's current location.

---

## Usage

### Automated Script (Recommended)

1. Right-click on `Run-Fix.bat` and select **Run as administrator**.
2. Accept the Windows UAC elevation prompt.
3. The script will:
   - Automatically detect the connected Mimo monitor and its touch digitizer.
   - Clean up stale/inactive mapping entries in the registry.
   - Register the active touch-to-display mapping in `HKLM\SOFTWARE\Microsoft\Wisp\Pen\Digimon`.
   - Restart the HID touch device using `pnputil` to apply the configuration immediately without requiring a reboot.

---

## Native Windows Alternative

You can also configure the mapping using Windows' built-in Tablet PC tool:
1. Press `Win + R`, type `multidigimon -touch` and press **Enter** (or open *Control Panel* -> *Tablet PC Settings* -> *Setup...*).
2. On non-touch screens, press **Enter** to advance.
3. When the prompt appears on the Mimo touchscreen, tap the screen with your finger to bind it.
