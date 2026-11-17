# Hopper: Project Definition

## 1. Vision
Make connecting a physical Android phone to a laptop **wirelessly** a one-click, set-and-forget experience, so developers on modest hardware can skip the emulator.

## 2. Problem
- Many laptops lag badly with the Android emulator, so developers test on a real phone.
- Wireless ADB needs several manual steps: enable Wireless debugging, pair with a code, copy an IP and port, run `adb pair` then `adb connect`.
- The connect port changes whenever Wireless debugging is toggled or the phone reboots, so the process repeats constantly.
- Failures give cryptic errors with no guidance.

## 3. Target users
- Flutter, Android and React Native developers testing on real devices
- Students and developers on low-spec laptops
- QA testers using personal phones

## 4. Goals
| Goal | Target |
|---|---|
| First pairing | Under 30 seconds, no typing of IP/port |
| Reconnect a saved phone | Under 5 seconds, no clicks when auto-reconnect is on |
| Cables needed (Android 11+) | Zero |
| Every failure | Shows cause and fix in plain language |
| Shared adb server | Never conflicts with Flutter or Android Studio |

## 5. Non-goals
- Not an IDE or emulator manager
- No cloud device farm or internet remote access
- No iOS
- No root-only features
- Windows only for v1

## 6. Functional requirements

| ID | Requirement | Priority |
|---|---|---|
| W1 | Pair via QR code with automatic discovery | Must |
| W2 | Pair via 6-digit code; Hopper finds the pairing service | Must |
| W3 | Discover connect service and connect automatically | Must |
| W4 | Save paired devices (identified by mDNS instance name, not IP) | Must |
| W5 | One-click and optional auto reconnect, including after port change | Must |
| W6 | Manual fallback: connect by IP:port | Must |
| D1 | Live device list with state (connected / unauthorized / offline / discovered) | Must |
| D2 | Connection diagnostics and checklist | Must |
| T1 | Screen mirroring via scrcpy | Must |
| T2 | Live Logcat with level, tag, package, regex filters; export | Must |
| T3 | APK install (drag and drop) with parsed errors | Must |
| T4 | Flutter panel: `flutter run -d`, hot reload, hot restart, stop | Must |
| U1 | USB fallback and switch-to-Wi-Fi for Android 10 and older | Should |
| T5 | Screenshot | Should |
| T6 | `adb reverse` manager | Should |
| T7 | File push/pull, app manager, screen recording | Could |

## 7. Non-functional requirements
- **Reliability:** no orphan `adb`/`scrcpy`/`flutter` processes after exit or crash
- **Compatibility:** coexists with Android Studio and Flutter adb (uses the SDK adb when present)
- **Performance:** UI stays responsive at 10k+ Logcat lines/s (isolate parsing, batching, ring buffer)
- **Privacy:** no telemetry by default; fully offline
- **Usability:** errors follow *What happened → Why → Fix*

## 8. Support matrix
| Scenario | Support |
|---|---|
| Android 11+, same Wi-Fi | Full, no cable ever |
| Android 10 and older | USB once, then wireless |
| Guest/isolated Wi-Fi | Not possible; Hopper detects and explains |
| Mobile hotspot from phone | Best effort |

## 9. Roadmap

| Milestone | Scope |
|---|---|
| **M0 Foundation** | Flutter project, bundled tools, adb locator, `adb version` in UI, CI |
| **M1 Wireless core** | mDNS discovery, QR/code pairing, connect, saved devices, auto-reconnect |
| **M2 Diagnostics** | Checklist (network profile, firewall, subnet, adb version, reachability) |
| **M3 Dev tools** | Device list polish, scrcpy, Logcat, APK install |
| **M4 Flutter panel** | Run, hot reload/restart, stop, output console |
| **M5 Fallbacks** | USB fallback and switch-to-Wi-Fi, manual IP:port |
| **M6 Release** | Installer, code signing, auto-update, docs, demo GIF |
| **Later** | `adb reverse`, file manager, app manager, macOS/Linux |

## 10. Success criteria
- A new user pairs and connects an Android 11+ phone without a cable, terminal or typing an IP
- After a phone reboot, the saved phone reconnects with no manual port entry
- `flutter devices` lists the phone while Hopper is running, with no adb server fights
- Clean exit leaves no stray processes

## 11. Risks

| Risk | Mitigation |
|---|---|
| mDNS blocked or unreliable on Windows (profile, firewall, multiple adapters) | Own Dart mDNS client bound to the Wi-Fi interface; fallback to `adb mdns services`; manual port entry; diagnostics |
| adb server version conflict | Prefer SDK adb; detect mismatch and explain |
| Router client isolation | Detect (reachability test) and explain |
| OEM quirks (Xiaomi, Oppo, Vivo) | Test matrix across real phones; per-OEM tips |
| SmartScreen warnings | Code-sign installer |
| Android auto-disables Wireless debugging on network change | Detect and prompt |

## 12. Key decisions
- **Flutter (Windows desktop):** matches author skills and goals; good UI productivity
- **Pure Dart ADB layer:** no Rust needed for v1; Rust bridge only if profiling demands it
- **Own mDNS client:** don't depend on adb's mDNS backend behaving on Windows
- **SDK adb first, bundled adb fallback:** avoid server conflicts
- **Inno Setup installer:** avoids MSIX sandbox limits for spawning tools and network access
- **Saved devices keyed by mDNS instance name:** survives IP and port changes
