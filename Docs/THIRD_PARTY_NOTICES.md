# Third-Party Notices

Hopper bundles or depends on the software below. Ship each project's full license text in the installer under `licenses/`. **Verify every license and version before each release**; the table is a starting point.

| Component | Purpose | License (verify) | Source |
|---|---|---|---|
| Android SDK Platform Tools (`adb`, `AdbWinApi.dll`, `AdbWinUsbApi.dll`) | Device communication | Apache 2.0 / Android SDK terms | developer.android.com/tools/releases/platform-tools |
| scrcpy | Screen mirroring | Apache 2.0 | github.com/Genymobile/scrcpy |
| Flutter / Dart | Framework | BSD-3-Clause | flutter.dev |
| flutter_riverpod | State management | MIT | pub.dev |
| multicast_dns | mDNS discovery | BSD-3-Clause | pub.dev |
| qr_flutter | QR rendering | BSD-3-Clause | pub.dev |
| window_manager, tray_manager, desktop_drop | Desktop integration | MIT | pub.dev |
| win32 | Windows FFI | BSD-3-Clause | pub.dev |
| freezed, json_serializable | Code generation | MIT / BSD-3-Clause | pub.dev |
| Inter, JetBrains Mono | Fonts | SIL OFL 1.1 | respective repos |

## Release checklist
1. Update pinned tool versions and checksums in `assets/bin/VERSIONS.md`.
2. Regenerate the dependency license list (`flutter pub deps` and a license-check tool).
3. Confirm each license text is included in the installer.

Android is a trademark of Google LLC. Hopper is independent and not affiliated with or endorsed by Google or Genymobile.
