# Hopper

> **Hop onto your Android phone over Wi-Fi. No cable. No commands.**

Hopper is a lightweight Windows desktop app that connects physical Android phones to your laptop **wirelessly**, in one click. It automates ADB pairing, discovery, connection and reconnection, so you can run and debug apps on a real device without an emulator and without typing `adb pair` / `adb connect`.

![status](https://img.shields.io/badge/status-in%20development-orange)
![platform](https://img.shields.io/badge/platform-Windows%2010%2F11-blue)
![built with](https://img.shields.io/badge/built%20with-Flutter-02569B)
![license](https://img.shields.io/badge/license-MIT-green)

<!-- Demo GIF: docs/assets/demo.gif -->

## Why Hopper exists

Not every laptop can run the Android emulator smoothly. The alternative is a real phone, but the setup is painful: enable debugging, pair with a code, copy an IP and a port that changes every time, connect, repeat after every reboot.

Hopper removes that. Pair once, then your phone reconnects on its own.

## How it works

1. **Pair once:** scan a QR code shown in Hopper (phone: Developer options → Wireless debugging → *Pair device with QR code*).
2. **Connect:** Hopper finds the phone on your network and connects. One click, or automatic.
3. **Develop:** run your Flutter or native app, mirror the screen, read logs, install APKs.

## Features

| Feature | Status |
|---|---|
| QR and code pairing with automatic discovery (mDNS) | Planned (MVP) |
| Saved devices, one-click and auto reconnect | Planned (MVP) |
| Live device list with status | Planned (MVP) |
| Connection diagnostics (why isn't my phone connecting?) | Planned (MVP) |
| Screen mirroring (scrcpy) | Planned (MVP) |
| Live Logcat with filters | Planned (MVP) |
| One-click APK install | Planned (MVP) |
| Flutter panel: run, hot reload, hot restart, stop | Planned (MVP) |
| USB fallback for Android 10 and older | Planned (v1.1) |
| `adb reverse` port manager | Planned (v1.1) |
| File transfer, app manager, screen recording | Planned (v2) |

## Requirements

- Windows 10 or 11 (x64)
- Android 11 or newer for fully cable-free pairing (older phones need USB once)
- Phone and laptop on the **same Wi-Fi network** (not a guest/isolated network)
- Windows network profile set to **Private** (Hopper helps you check this)

Android Studio is **not** required. Hopper uses your existing Android SDK `adb` if found, otherwise its bundled Platform Tools.

## Install (users)

Download the latest installer from **Releases** and run it.

## Development setup

Prerequisites: Flutter (stable) with Windows desktop enabled, Visual Studio with the "Desktop development with C++" workload.

```bash
git clone https://github.com/<your-username>/hopper.git
cd hopper
flutter config --enable-windows-desktop
flutter pub get
flutter run -d windows
```

```bash
flutter build windows --release
```

Bundled tools (Platform Tools, scrcpy) go in `assets/bin/`. See [ARCHITECTURE.md](ARCHITECTURE.md#9-bundled-tools).

## Documentation

| Doc | Purpose |
|---|---|
| [PROJECT.md](PROJECT.md) | Vision, scope, requirements, roadmap |
| [ARCHITECTURE.md](ARCHITECTURE.md) | System design, modules, data flow |
| [WIRELESS.md](WIRELESS.md) | Pairing, discovery and reconnect in detail |
| [DESIGN.md](DESIGN.md) | UI/UX, screens, components |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Connection problems and fixes |
| [SECURITY.md](SECURITY.md) | Security model and reporting |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute |
| [CHANGELOG.md](CHANGELOG.md) | Release history |
| [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) | Bundled software and licenses |

## License

MIT. Bundled tools keep their own licenses (see THIRD_PARTY_NOTICES.md). Android is a trademark of Google LLC. Hopper is independent and not affiliated with or endorsed by Google.
