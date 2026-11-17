# Security

## Threat model
Hopper runs locally and launches `adb`, `scrcpy` and `flutter` on the user's behalf, and talks to phones on the local network. Risks: command injection, malicious paths or APKs, connecting to the wrong device, over-broad permissions, tampered downloads or updates.

## Controls
- **No shell strings.** Processes are started with argument lists; `runInShell` is never used.
- **Input validation:** IPs, ports, serials, package names and paths are validated before use; paths are normalized and checked.
- **Pairing secrets stay short-lived.** QR passwords are random, single-use and never written to disk or logs.
- **No key handling.** adb manages its own keys (`~/.android`); Hopper stores only device labels, mDNS instance names, last IP and port, and settings.
- **Explicit device targeting.** Every command uses `-s <serial>`; no implicit "default device".
- **Logs:** Logcat data stays in memory unless the user exports it; app logs avoid secrets and are redacted.
- **No telemetry by default; no backend.** Everything runs locally.
- **Bundled tools verified:** pinned versions with SHA-256 checksums checked before extraction.
- **Process cleanup:** Windows Job Object kills child processes when Hopper exits or crashes.
- **Signed releases and signed update metadata.**
- **Dependency hygiene:** `flutter pub outdated`, Dependabot, review of new packages.

## User guidance
- Wireless debugging grants powerful access to your phone. Pair only on networks you trust.
- Turn Wireless debugging off when you're done, especially on shared Wi-Fi.
- Revoke authorizations in Developer options if you lose a laptop.

## Reporting a vulnerability
Email **security@<your-domain>** or use GitHub private vulnerability reporting. Please don't open public issues for security bugs. Expect an acknowledgment within 5 business days.
