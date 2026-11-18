# Glance VR

Use your Mac's windows on Meta Quest. Each window floats as its own panel in passthrough.
**Look** at a panel to select it, and use **hand gestures** to click, scroll, move and zoom.

▶ [Demo video](https://www.youtube.com/watch?v=RoXALA7M2vg) · [Devpost](https://devpost.com/software/glance-vr) · Meta VR Start Developer Competition 2026

## Project layout

```
GlanceVR/
├── mac/          Mac app (Swift): streams windows to the headset, runs clicks and scrolls
├── quest/        Quest app (Godot 4.7 + OpenXR): panels, gaze, hand gestures
└── PROTOCOL.md   every message between the two apps
```

## How it works

```
          MAC  (mac/)                                     QUEST  (quest/)
 ┌─────────────────────────┐   window list + JPEG   ┌──────────────────────────┐
 │ WindowRegistry          │ ─────────────────────▶ │ one floating panel per   │
 │ WindowStreamPool        │                        │ window                   │
 │                         │                        │                          │
 │ GazeInput               │ ◀───────────────────── │ gaze picks the panel,    │
 │ raises the window and   │  {"type":"click",      │ hand gesture picks the   │
 │ posts a real click      │   "window":42,         │ action                   │
 │                         │   "x":0.4,"y":0.7}     │                          │
 └─────────────────────────┘                        └──────────────────────────┘
              WebSocket on port 47811 (USB cable, or the same Wi-Fi)
```

1. **Mac → Quest:** the Mac sends the list of open windows and a picture of each one. The window you look at streams live, about 8 frames a second. The others refresh as stills.
2. **Quest:** shows each window as a panel. Your gaze selects one: eyes on Quest Pro, head on Quest 3. Your hands choose the action.
3. **Quest → Mac:** a short JSON message, e.g. `{"type":"click","window":42,"x":0.4,"y":0.7}`. Each message has the window ID and the point inside it, from 0 to 1.
4. **Mac:** brings window 42 to the front, turns the point into screen pixels, and posts a real mouse event.

### Main files

| Mac (`mac/Sources/GlanceVR/`) | Job |
|---|---|
| `QuestHub.swift` | WebSocket server (port 47811) and Wi-Fi discovery (UDP 47812) |
| `WindowRegistry.swift` | Keeps the list of open windows, up to 8 |
| `WindowStreamPool.swift` | Captures windows with ScreenCaptureKit |
| `GazeInput.swift` | Turns messages into real clicks, double-clicks, scrolls and drags |

| Quest (`quest/`) | Job |
|---|---|
| `gaze.gd` | All app logic: connection, panels, gaze ray, hand gestures |
| `addons/` | Godot OpenXR Vendors plugin (passthrough, hands, eye tracking) |

## Gestures

| Gesture | Action |
|---|---|
| Look at a panel | Select it |
| Left pinch | Click |
| Left pinch twice | Open (double-click) |
| Point (index finger out) + move up/down | Scroll; flick to fling |
| Right pinch + move hand | Move the panel |
| Both hands pinch, spread / close | Zoom in / out |
| Right pinch on empty space, hold 2 s | Recenter the panels |

## Setup and run

**You need:**
- a Mac with macOS 14 or newer and Xcode 16+
- a Meta Quest 3, 3S or Pro with developer mode on
- a USB-C cable

**1. Start the Mac app**
```
cd mac
swift run -c release GlanceVR
```
- The first time, macOS asks for **Screen Recording** and **Accessibility** for your terminal app.
- Allow both, then run the command again.

**2. Install the Quest app** (headset plugged in)
```
cd quest
APK=path/to/GlanceVR.apk zsh cable.sh install
```
- Get the APK from [Releases](https://github.com/ismkhanh/GlanceVR/releases).
- Or build it yourself: `zsh build.sh` (needs Godot 4.7.2, the Android SDK and JDK 17).

**3. Put the headset on.** `cable.sh` opens Glance VR for you, and your windows appear around you.
- To open it again later, run `zsh cable.sh`.
- Or in the headset: **App Library → filter (top right) → Unknown Sources → Glance VR**.

**If something goes wrong:**
- **Black panels:** allow Screen Recording.
- **Clicks do nothing:** allow Accessibility.
- **Stuck on "Looking for Glance":** check the Mac app is running, then run `zsh quest/cable.sh` again.

> **Security:** on shared Wi-Fi, start the Mac app with `GLANCE_QUEST_LAN=0`. It then accepts the USB cable only.

## License

MIT
