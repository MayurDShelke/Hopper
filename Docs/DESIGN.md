# Hopper: UI/UX Design

## 1. Principles
1. **One obvious action.** The primary button for the current state is always the biggest thing on screen.
2. **Never ask for what we can discover.** No typing IPs or ports unless every fallback failed.
3. **Status at a glance.** Connection state is always visible and never color-only.
4. **Failures explain themselves.** *What happened → Why → Fix*, with a fix button where possible.
5. **Calm developer tool.** Dense, fast, quiet.

## 2. Window layout (min 1000x650)

```
┌──────────────────────────────────────────────────────────────┐
│ Hopper                         [ + Pair new phone ]   ⚙  ─ □ ✕ │
├───────────────┬──────────────────────────────────────────────┤
│ MY PHONES     │  Pixel 7 · Android 14 · Wi-Fi · 82%          │
│ ● Pixel 7     │  [Overview][Mirror][Logcat][Install][Flutter]│
│   connected   │ ───────────────────────────────────────────  │
│ ◌ Redmi Note  │                                              │
│   not found   │          (active tab content)                │
│ ◐ Galaxy A52  │                                              │
│   connecting  │                                              │
│ ───────────── │                                              │
│ [Diagnostics] │                                              │
├───────────────┴──────────────────────────────────────────────┤
│ adb 35.0 (SDK) · server ok · Wi-Fi: Home_5G (Private)  Jobs: 1│
└──────────────────────────────────────────────────────────────┘
```

## 3. Key screens

**Home / empty state:** Large *Pair your phone* button; three-step phone checklist (Developer options → Wireless debugging → Scan QR); link to Diagnostics.

**Pairing wizard (3 steps):**
1. **Scan:** big QR, live status "Waiting for your phone…". Tab to switch to *Use pairing code*.
2. **Pairing:** spinner, shows detected phone name.
3. **Done:** "Connected. Save this phone?" with name field and *Auto-reconnect* toggle.
Code mode: only a 6-digit input is shown; the address is auto-filled.

**Phone card (sidebar):** state icon + text, name, transport, battery. States: Connected, Connecting, Found (tap to connect), Not found, Needs approval, Offline. Hover reveals Connect / Disconnect / Forget.

**Overview:** device info (model, Android/API, ABI, battery, storage, IP:port, serial); quick actions: Mirror, Screenshot, Install APK, Open Logcat, Run Flutter app.

**Mirror:** Start/Stop; options (max size, bitrate, audio, stay awake, screen off).

**Logcat:** level chips (V D I W E F), package picker, tag filter, regex search, pause/resume, clear, auto-scroll, export. Monospace list, level-colored, tap to expand. Footer: line count and rate.

**Install:** big drop zone, recent APKs, options (reinstall, grant permissions, allow downgrade).

**Flutter panel:** project folder picker, build mode (debug/profile/release), **Run**, **Hot reload (r)**, **Hot restart (R)**, **Stop**; console output with clickable errors.

**Diagnostics:** checklist with pass/fail and a **Fix** action per row:
- adb found and server running
- Wi-Fi network profile is Private
- mDNS available (UDP 5353 / firewall)
- Phone reachable on the network (TCP test)
- Wireless debugging detected on the phone
- Same subnet
- adb version conflict

## 4. State matrix

| State | Sidebar | Main panel |
|---|---|---|
| Connected | Green dot, "connected" | Tabs enabled |
| Found | Blue dot, "found nearby" | **Connect** button |
| Connecting | Spinner | Progress and cancel |
| Needs approval | Amber, "tap Allow on phone" | Banner and Retry |
| Not found | Grey | "Turn on Wireless debugging" + Diagnostics |
| Offline | Red | Reconnect and Diagnostics |
| adb server down | Footer red | Auto-restart notice |

## 5. Visual style
- **Theme:** dark default, light option, follows system.
- **Tokens:** background `#0E1116`, surface `#161B22`, border `#252C36`, text `#E6EAF0`, muted `#8B95A5`, accent `#2DD4BF` (teal), success `#34D399`, warning `#F5B83D`, error `#F26D6D`, info `#60A5FA`.
- **Type:** Inter (UI), JetBrains Mono (logs, serials, IPs).
- **Shape:** 8 px radius, 4 px spacing grid, 1 px borders, minimal shadow.
- **Icons:** Material Symbols / Lucide.
- **Motion:** 120-180 ms; none on log rows.
- **Logo idea:** a small hopping arc between a laptop and a phone. No Android robot or the word "Android" in the logo.

## 6. Interaction details
- Command palette (`Ctrl+K`): "mirror", "pair", "install", "logcat", "run".
- System tray: status icon, quick Connect per saved phone, Quit.
- Notifications: "Pixel 7 connected", "Pixel 7 disconnected" (toggleable).
- Keyboard: full tab navigation, visible focus, shortcuts for hot reload (`R`) when the Flutter panel is focused.

## 7. Accessibility
Status never by color alone; AA contrast; respects system text scaling and reduced motion; semantic labels on all controls.

## 8. Copy guidelines
Short and specific. "Turn on Wireless debugging on your phone", not "Service unavailable". Error format: **What happened → Why → Fix**.
