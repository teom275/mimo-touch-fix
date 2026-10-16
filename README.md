# Mimo Touch Tools & EasyDeck

A lightweight, zero-dependency toolkit for secondary USB displays (such as Mimo monitors), featuring an automated touch digitizer mapping fix and **EasyDeck**, a plug-and-play touch Stream Deck controller.

---

## 🎮 EasyDeck (Touch Stream Deck)

EasyDeck transforms any secondary touchscreen or display into an interactive, touch-optimized Stream Deck controller.

### Highlights
- **Zero Installation:** Built with standard web technologies and native Windows PowerShell. No Python, Node.js, or package managers required.
- **Direct OBS Studio Integration:** Connects natively via OBS WebSocket v5 to switch scenes, toggle recording/streaming, and mute audio with real-time visual feedback (live glows, recording badges, mute indicators).
- **Windows System & Media Controls:** Volume up/down/mute, play/pause, next/previous track for Spotify, YouTube, and media players.
- **In-App Visual Editor:** Click the ⚙️ edit button to customize button labels, icons, actions, and colors directly through a graphical menu. Changes are saved automatically in the browser.
- **Portable Presets:** Includes pre-configured buttons and one-click configuration export/import.
- **Flexible Display:** Runs as a standalone frameless app (auto-positioned on secondary displays) or can be embedded directly inside OBS Studio as a Custom Browser Dock.

### How to Run EasyDeck
1. Double-click **`Abrir-EasyDeck.bat`**.
2. EasyDeck will start a local lightweight service and launch the controller in a clean, frameless window.
3. Tap buttons to control your audio, OBS, and media!

#### Connecting to OBS Studio
1. Open **OBS Studio**.
2. Go to **Tools** (Herramientas) $\rightarrow$ **WebSocket Server Settings** (Ajustes del servidor WebSocket).
3. Ensure **Enable WebSocket server** (Habilitar servidor WebSocket) is checked (default port is `4455`).
4. EasyDeck will connect automatically and display a 🟢 green indicator.

#### Using as an OBS Dock (Optional)
If you prefer to dock EasyDeck directly inside OBS:
1. In OBS, go to **Docks** $\rightarrow$ **Custom Browser Docks...** (Paneles de navegador personalizados).
2. Enter a name (e.g., `EasyDeck`) and URL: `http://localhost:8080`.
3. Click **Apply** and drag the dock to your external touchscreen!

---

## 🛠️ Touch Screen Mapping Fix

Fixes the common Windows issue where tapping an external USB touchscreen registers as a mouse click on the primary monitor instead of the touch display.

### Why this happens
In Windows, touchscreen-to-monitor bindings are maintained in the WISP subsystem registry (`HKLM\SOFTWARE\Microsoft\Wisp\Pen\Digimon`). When a USB touchscreen is plugged into a different USB port or hub, Windows assigns a new hardware path. If unmapped, Windows defaults touch input to the primary display.

### How to Apply the Touch Fix
1. Right-click **`Run-Fix.bat`** and select **Run as administrator**.
2. The script will automatically detect the USB touch display, update the registry binding, and restart the HID touch driver without requiring a reboot.
