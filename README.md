# Glance VR

**Your Mac's windows, floating around you on Meta Quest. Look at one, and control it with your hands.**

Every open window on your Mac becomes its own floating panel in your Quest, with passthrough so you still see your
room. Look at a panel to select it. Then pinch to click, pinch twice to open, point to scroll, grab to move, and pinch
with both hands to zoom. No controller, no mouse, no keyboard.

**Demo video:** [youtube.com/watch?v=RoXALA7M2vg](https://www.youtube.com/watch?v=RoXALA7M2vg) ·
**Devpost:** [devpost.com/software/glance-vr](https://devpost.com/software/glance-vr) ·
Built for the **Meta VR Start Developer Competition 2026** (Productivity track, New Experience)

This repo has two parts:

| Folder | What it is | Language |
|---|---|---|
| [`mac/`](mac/) | **The Mac app.** Streams your windows to the headset, and clicks or scrolls in them when the headset asks | Swift |
| [`quest/`](quest/) | **The Quest app.** Shows the panels, tracks your gaze and hands, and sends what you do to the Mac | Godot 4.7 (GDScript) + OpenXR |

---

## How it works

```
        MAC  (mac/)                                         QUEST  (quest/)
 ┌───────────────────────────┐                     ┌───────────────────────────────┐
 │ 1. List the open windows  │  ── window list ──▶ │ 3. One floating panel per     │
 │    (WindowRegistry)       │                     │    window, placed around you  │
 │                           │                     │                               │
 │ 2. Capture each window    │  ── pictures ─────▶ │ 4. Your gaze picks a panel    │
 │    (WindowStreamPool)     │     (JPEG)          │    → it lights up             │
 │                           │                     │                               │
 │ 6. Bring that window to   │  ◀── "click window  │ 5. Your hand does something   │
 │    the front, then post a │      #42 at x,y" ── │    (pinch, point, grab)       │
 │    real click / scroll    │                     │    → a message to the Mac     │
 │    (GazeInput)            │                     │                               │
 └───────────────────────────┘                     └───────────────────────────────┘
              one WebSocket on port 47811: over the USB cable or the same Wi-Fi
```

Step by step:

1. **The Mac lists your windows.** `WindowRegistry` asks macOS about the normal windows on screen: app, title, size,
   which one is in front. It checks again every second and tells the headset when something changes, for example
   when you open a new app.
2. **The Mac captures each window.** `WindowStreamPool` uses ScreenCaptureKit to take a picture of each window on its
   own. The window you look at streams live, about 8 times a second. The others take turns as small stills, so each one
   refreshes every 1 to 3 seconds.
3. **The Quest shows one panel per window.** `quest/gaze.gd` builds a floating panel for each window, in an arc in
   front of you, with your room visible around them (passthrough).
4. **Your gaze picks a panel.** The headset draws an invisible line from your eyes (Quest Pro, Meta VR Glasses) or
   from your head (Quest 3, 3S) and finds the panel it hits, and the spot on it, for example 40% across and 70% down.
   That panel lights up. It only switches after a short hold, so it doesn't flicker at the edges.
5. **Your hands act.** The headset reads your hand joints 72+ times a second and turns them into gestures (table
   below). Each gesture becomes a small message like `{"type":"click","window":42,"x":0.4,"y":0.7}`.
6. **The Mac acts in that exact window.** `GazeInput` finds window 42, brings it to the front, converts 40% / 70% into
   a point on your screen, and posts a real mouse click or scroll there. To macOS, it looks like you used your mouse.

The full message list is in [PROTOCOL.md](PROTOCOL.md).

## Gestures

| Gesture | What it does |
|---|---|
| **Look** at a window | Selects it: the panel lights up and shows its name |
| **Left hand, short pinch** (thumb + index) | Click where you look |
| **Left hand, two quick pinches** | Open, as a double-click (e.g. a file in Finder) |
| **Point** (fist, index finger out), move up / down | Scroll the window. Flick and let go to fling |
| **Left hand, long pinch**, move up / down | Scroll too |
| **Right hand, pinch and move your hand** | Move the panel. It stays where you put it |
| **Right hand, pinch and hold while you look across a window** | Drag inside the window |
| **Both hands pinched**, spread apart / bring together | Zoom the panel in / out |
| **Right pinch on empty space, hold 2 s** | Bring the panels back in front of you |

A small legend shows these for 12 seconds when your windows appear. Glowing dots on your fingers show what the
headset sees of your hands.

## Quick start

**You need:** a Mac with macOS 14 (Sonoma) or newer and Xcode 16+, a Meta Quest 3, 3S or Pro with
[developer mode](https://developers.meta.com/horizon/documentation/native/android/mobile-device-setup/) on, and a
USB-C cable (or the same Wi-Fi). No accounts and no API keys.

### 1. Start the Mac app

```
cd mac
swift run -c release GlanceVR
```

Or double-click `mac/Start Glance VR.command`. The first time, macOS asks for two permissions for your terminal
app. Allow them in **System Settings → Privacy & Security**, then start the app again:

- **Screen & System Audio Recording**, so your windows can be shown in the headset
- **Accessibility**, so the app can click and scroll for you

Keep the window open while you use the headset.

### 2. Install the Quest app

Get `GlanceVR.apk` from this repo's **Releases** page, or build it (next section). Plug the Quest into the Mac and run:

```
cd quest
APK=~/Downloads/GlanceVR.apk zsh cable.sh install     # or just: zsh cable.sh install, after building
```

Accept **"Allow USB debugging"** in the headset if it asks. This installs the app and links it to the Mac over the
cable.

### 3. Use it

In the headset, open **Library → Unknown sources → Glance VR**. It finds your Mac by itself, over the cable or on the
same Wi-Fi, and your windows appear around you.

## Build the Quest app

You need:
- Godot 4.7.2, with the Android export templates
- The Android SDK
- JDK 17 (the one inside Android Studio works)

```
cd quest
zsh build.sh          # → quest/builds/GlanceVR.apk
zsh cable.sh install  # install it on the plugged-in Quest
```

- **Finding the tools:** `build.sh` looks for Godot, the SDK and the JDK by itself. You can also set them yourself
  with `GODOT=…`, `ANDROID_HOME=…` and `JAVA_HOME=…`.
- **Signing:** without a key you get a **debug-signed** APK, which installs on your own headset. To upload to the Meta
  Developer Dashboard, put your own key in `quest/signing/` (`glancevr-release.keystore` plus `keystore.env` with
  `GLANCEVR_KEYSTORE_PASSWORD` and `GLANCEVR_KEY_ALIAS`). That folder is in `.gitignore`. Never commit it.
- **Dashboard rules:** the Dashboard accepts **target SDK 34** or lower (set in `quest/export_presets.cfg`), and every
  upload needs a higher version code: `zsh build.sh 4`.

## What's in the code

### Mac app (`mac/Sources/GlanceVR/`)

| File | What it does |
|---|---|
| `main.swift` | Starts everything and asks for the two permissions |
| `QuestHub.swift` | The WebSocket server on port 47811, Wi-Fi discovery (UDP 47812), the optional token, and sending window lists and pictures |
| `WindowRegistry.swift` | Keeps the list of windows (frontmost first, at most 8), and notices changes |
| `WindowStreamPool.swift` | Captures windows with ScreenCaptureKit: the highlighted one live, the others as stills |
| `ScreenStream.swift` | Captures the whole display, for the single-screen fallback |
| `GazeInput.swift` | Turns headset messages into real mouse and scroll events in the right window, with safety timers so a mouse button is never left down |
| `AX.swift`, `WindowLocator.swift`, `Capture.swift` | macOS helpers: find windows, bring one to the front, take a window's picture |

### Quest app (`quest/`)

Everything happens in **`gaze.gd`**, attached to `main.tscn`:

| Part | What it does |
|---|---|
| Connection | Finds the Mac (USB first, then Wi-Fi discovery), sends `hello`, keeps reconnecting |
| Panels | Builds, updates and removes one panel per window, lays them out in an arc, remembers where you moved them |
| Gaze | Eyes when the headset has eye tracking, otherwise the head. Ray against every panel, nearest hit wins |
| Highlight | Lights up the panel you look at after a short hold, and tells the Mac to stream it live |
| Hands | Pinch detection (Meta's own when available, fingertip distance otherwise), the point pose, two-hand zoom, glowing joint dots |
| Gestures | Click / double-click timing, scroll and fling, grab-to-move, drag |
| Legend | The small gesture help that hides after 12 s |

`addons/` holds the Godot OpenXR Vendors plugin (Meta's OpenXR features) and a small `StartXR` helper.

## Why it's built this way

- **Windows are identified by ID, not by the mouse pointer.**
  - *What we saw:* clicking "where the pointer is" fails when the window you look at is behind another window on the
    Mac.
  - *What we chose:* every action carries the window's ID, and the Mac brings that window forward first.
  - *Trade-off:* the Mac's window order changes when you act. It never changes just because you looked somewhere.
- **One live stream, stills for the rest.**
  - *What we saw:* decoding 8 live window streams would overload the headset.
  - *What we chose:* only the window you look at streams live (about 8 per second). The others take turns as stills.
  - *Trade-off:* a window you're not looking at can be 1 to 3 seconds behind.
- **The headset does the highlighting.**
  - *Why:* it needs no round trip to the Mac, so it feels instant.
  - *What the Mac gets:* a short note about which window to stream live.
- **Godot + OpenXR on the headset.** Passthrough, hand tracking, eye gaze and APK export all in one small project.
  Meta's Spatial SDK (Kotlin) would also work. Godot let us reuse a working gaze prototype.
- **USB cable first, Wi-Fi second.**
  - *USB* needs no network setup, keeps the link private, and charges the headset.
  - *Wi-Fi* is easier to walk around with, but anyone on the same network could connect, so set a token there (see
    Security).

## If something doesn't work

- **"Looking for Glance on your Mac…" doesn't go away:**
  - Check that the Mac app is running.
  - With a cable, run `zsh quest/cable.sh` again after re-plugging.
  - On Wi-Fi, both devices must be on the same network.
- **Panels are black:** Screen Recording isn't allowed for your terminal app yet. Allow it and restart the Mac app.
- **Clicks or scrolls do nothing:** Accessibility isn't allowed yet.
- **Watch the headset's log:** `adb logcat -s godot`

## Security

On Wi-Fi, another device on the same network could connect to the Mac app, and then click and scroll in your
windows. So either:
- Use it on **your own network**.
- Start the Mac app with **`GLANCE_QUEST_LAN=0`**, so it accepts the USB cable only.
- Set **`GLANCE_QUEST_TOKEN=<a word>`** on the Mac and the same word as `quest_token` in the Quest app.

## License

MIT, see [LICENSE](LICENSE).
