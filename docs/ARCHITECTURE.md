# Hopper: Architecture

## 1. Overview

```
┌──────────────────────── Flutter app (Windows) ────────────────────────┐
│  UI (widgets)  ◄── Riverpod providers (state) ◄── Services (Dart)      │
│                                                                        │
│  Services: Discovery · Pairing · ConnectionManager · AdbClient         │
│            ProcessManager · LogcatService · FlutterRunner · Store      │
└──────┬──────────────┬───────────────────┬────────────────┬─────────────┘
       │ UDP 5353     │ TCP :5037         │ spawn          │ spawn
       ▼ (mDNS)       ▼                   ▼                ▼
   Phone on LAN    adb server         adb.exe          scrcpy.exe / flutter
```

**Principle:** services own all logic and state; widgets only render providers and call service methods.

## 2. Project structure (feature-first)

```
lib/
  main.dart
  app/                    app shell, routing, theme, window setup
  core/
    adb/                  adb_locator, adb_client (socket), adb_runner (process)
    discovery/            mdns_service, service_models
    process/              process_manager, job_object (win32)
    diagnostics/          checks (network profile, firewall, reachability)
    errors/               app_error, error_mapper
    storage/              saved_devices_repo, settings_repo
    utils/                validators, logger
  features/
    connect/              pairing wizard, QR, saved devices, auto-reconnect
    devices/              device list and cards
    mirror/               scrcpy control
    logcat/               stream, parser, filters, UI
    install/              APK drag and drop
    flutter_panel/        run / hot reload / stop console
    diagnostics/          checklist UI
    settings/
  shared/                 widgets, theme tokens
assets/bin/               platform-tools + scrcpy archives
test/
```

## 3. Key services

| Service | Responsibility |
|---|---|
| `AdbLocator` | Find SDK adb (`ANDROID_HOME`, `ANDROID_SDK_ROOT`, `flutter doctor` path, `%LOCALAPPDATA%\Android\Sdk`), else bundled adb |
| `AdbClient` | Talk to the adb server at `127.0.0.1:5037` over a socket (`host:track-devices`, `host:version`, `host:devices-l`) |
| `AdbRunner` | Run adb as a process for operations needing progress output (`pair`, `connect`, `install`) |
| `DiscoveryService` | mDNS browsing for `_adb-tls-pairing._tcp` and `_adb-tls-connect._tcp` |
| `PairingService` | QR payload generation, `adb pair`, success detection |
| `ConnectionManager` | Per-device state machine, reconnect/backoff, saved device matching |
| `ProcessManager` | Registry of child processes, kill-on-exit, Windows Job Object |
| `LogcatService` | Spawn logcat, parse in an isolate, ring buffer, batched stream |
| `FlutterRunner` | Spawn `flutter run -d <serial>`, forward `r` / `R` / `q` to stdin, stream output |
| `DiagnosticsService` | Run connection checks and map results to fixes |
| `Store` | Persist saved devices and settings |

## 4. ADB socket protocol (AdbClient)
Requests: 4 hex digits of payload length + payload (e.g. `0012host:track-devices`). Replies start with `OKAY` or `FAIL`; `track-devices` then streams updates, each prefixed with a 4-hex length. `AdbClient`:
1. Ensures the server is running (`adb start-server` via `AdbRunner`).
2. Opens the tracking connection and emits `List<AdbDevice>` on every change.
3. On drop, restarts the server and re-subscribes with backoff.

## 5. Discovery details
- `multicast_dns` client bound to the Wi-Fi interface (skip virtual adapters).
- Emits `DiscoveredService { type, instanceName, ip, port }` streams.
- Fallbacks: `adb mdns services` parsing, then manual entry. Full flows in [WIRELESS.md](WIRELESS.md).

## 6. State management
Riverpod providers:
- `adbPathProvider`, `adbServerStatusProvider`
- `discoveredServicesProvider` (stream)
- `savedDevicesProvider` (notifier + storage)
- `connectionStateProvider(deviceId)` (state machine)
- `devicesProvider` (merged: adb devices + saved + discovered)
- `logcatProvider(serial)`, `flutterRunProvider(serial)`

Models use `freezed`; JSON via `json_serializable`.

## 7. Command execution rules
- Every device command includes `-s <serial>` (wireless serial is `ip:port`).
- Arguments are passed as `List<String>`; **never** `runInShell: true`, never string concatenation.
- Inputs (IP, port, package, path) are validated before use (`core/utils/validators.dart`).
- Long jobs expose `Stream<JobProgress>` and a `cancel()`.

## 8. Feature flows

**Pair (QR):** generate payload → show QR → discover pairing service by name → `adb pair` → await connect service → `adb connect` → save device.

**Reconnect:** saved device + connect service seen → reachability check → `adb disconnect` (stale) → `adb connect` → verify `device` state.

**Mirror:** spawn `scrcpy --serial <serial>` (options: max size, bitrate, no audio, stay awake) → register PID → stop on request or app exit.

**Logcat:** spawn `adb -s S logcat -v threadtime` → isolate parses lines → append to ring buffer (default 100k) → emit batches every ~50 ms → `ListView.builder` renders → filters applied in the isolate.

**Install:** `adb -s S install -r <apk>` → parse result codes (`INSTALL_FAILED_*`) → friendly message.

**Flutter panel:** `flutter run -d <serial>` in the chosen project directory; `r` hot reload, `R` hot restart, `q` quit via stdin; output streamed to a console view.

## 9. Bundled tools
```
assets/bin/
  platform-tools-windows.zip   (adb.exe, AdbWinApi.dll, AdbWinUsbApi.dll)
  scrcpy-windows.zip
  VERSIONS.md                  pinned versions + checksums
```
- Executables can't run from the Flutter asset bundle. On first run, extract to `%APPDATA%\Hopper\bin\<version>\` and verify checksums.
- Used only when no SDK adb is found.

## 10. Process lifecycle and cleanup
- Every spawned process is registered in `ProcessManager`.
- Windows Job Object with `JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE` (via `win32` FFI) so children die even if Hopper crashes.
- Single instance: named mutex via `win32`; second launch focuses the first.
- On startup, optionally clean leftover Hopper-spawned scrcpy processes.

## 11. Error model
`AppError` sealed class: `AdbNotFound`, `AdbServerConflict`, `PairingFailed(reason)`, `DiscoveryUnavailable`, `DeviceUnreachable`, `DeviceUnauthorized`, `InstallFailed(code)`, `ProcessFailed`, `InvalidInput`. Each maps to *title, cause, fix*; diagnostics reuses the same mapping.

## 12. Persistence
`shared_preferences` (or a JSON file in `%APPDATA%\Hopper`): saved devices, settings (theme, auto-reconnect, Logcat buffer, scrcpy options, Flutter project paths). No keys or secrets stored; adb manages its own keys.

## 13. Packages (planned)
`flutter_riverpod`, `freezed`, `json_serializable`, `multicast_dns`, `qr_flutter`, `window_manager`, `tray_manager`, `desktop_drop`, `file_picker`, `path_provider`, `shared_preferences`, `archive`, `crypto`, `win32`, `auto_updater`.

## 14. Build and release
- GitHub Actions on `windows-latest`: `flutter analyze`, `flutter test`, `flutter build windows --release`
- Inno Setup installer, code-signed
- Update channel: GitHub Releases (via `auto_updater` or a custom check)

## 15. Testing
- **Unit:** adb protocol parser, mDNS record handling, Logcat parser, validators, state machine, error mapping
- **Fakes:** `AdbBackend` and `DiscoveryBackend` interfaces with fake implementations for service tests
- **Widget tests:** pairing wizard, device cards, Logcat filters
- **Manual matrix:** at least 3 real phones (different OEMs), Android 11 to latest, home Wi-Fi and a restrictive network
