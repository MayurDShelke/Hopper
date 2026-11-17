# Contributing

Thanks for helping make wireless debugging painless.

## Setup
See Development setup in [README.md](README.md). You need Flutter (stable) with Windows desktop, Visual Studio C++ workload, and at least one Android 11+ phone for wireless testing.

## Workflow
1. Open or comment on an issue before large changes.
2. Branch from `main`: `feat/…`, `fix/…`, `docs/…`.
3. Keep PRs small and focused; include screenshots for UI changes.
4. Run checks, then open a PR.

## Checks
```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Conventions
- **Commits:** Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `chore:`).
- **Structure:** feature-first under `lib/features/`; shared logic in `lib/core/`.
- **State:** Riverpod; no business logic in widgets.
- **Processes:** argument lists only, never `runInShell`; every external input validated.
- **Errors:** use `AppError` with title, cause and fix; no raw adb output shown without translation.
- **Tests:** parsers, validators and state machines require unit tests; use fake `AdbBackend` / `DiscoveryBackend`.
- **Docs:** update the relevant `.md` and CHANGELOG with the change.

## Adding a feature
1. Add a service in `core/` (or extend one) with an interface for faking.
2. Add providers and a folder under `features/`.
3. Add tests and update docs.
4. Verify cleanup: no stray processes after exit.

## Reporting bugs
Include Windows version, phone model and Android version, router/network type (home, hotspot, guest), Hopper version, steps to reproduce, and the exported diagnostics file.

## Testing on real devices
Wireless issues depend heavily on OEM and network. If you test on a phone model not listed in the compatibility notes, please report the result (works / quirks) in an issue.
