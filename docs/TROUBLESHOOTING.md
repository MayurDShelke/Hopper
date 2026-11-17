# Troubleshooting

Each section matches a check in Hopper's **Diagnostics** screen.

## Phone is never found
1. Phone: Developer options → **Wireless debugging** is **On**.
2. Phone and laptop are on the **same Wi-Fi** (same network name; avoid guest networks and mobile data).
3. Windows network profile is **Private**: Settings → Network & Internet → Wi-Fi → your network → Network profile type → *Private network*. Public profiles block discovery.
4. Firewall allows Hopper on private networks (UDP 5353 for discovery). Let Hopper add the rule, or allow it when Windows prompts.
5. Turn VPNs off; they can capture multicast traffic.
6. Toggle Wireless debugging off and on, then press *Refresh*.

## Pairing fails
- **Code expired:** reopen *Pair device with pairing code* on the phone and enter the new code quickly.
- **QR not detected:** keep the pairing screen open on the phone and stay on the QR screen in Hopper; try *Pair with code*.
- **Wrong port:** the pairing port differs from the connect port. Hopper fills this automatically; for manual entry use the port shown on the pairing dialog.
- Restart Wireless debugging and try again.

## "Needs approval" / unauthorized
Unlock the phone and tap **Allow** on the prompt. Tick **Always allow on this network**. If no prompt appears: Developer options → *Revoke USB debugging authorizations*, then pair again.

## Connection drops or says offline
- Wireless debugging turns off when the phone changes Wi-Fi or locks into aggressive battery saving. Turn it back on.
- Developer options → **Disable adb authorization timeout** reduces re-authorization prompts.
- Exclude your phone from battery optimization for system settings if the OEM kills Wireless debugging.

## Phone reboots or the port changes
Nothing to do. Hopper rediscovers the new port for saved phones. If it doesn't, check the Diagnostics screen; discovery is probably blocked.

## Found, but connection times out
Likely **router client isolation** (AP isolation), common on guest, hotel, college and office Wi-Fi. Try a home network or your phone's hotspot, or disable isolation in router settings.

## adb version conflict or server keeps restarting
Another tool (Android Studio, another SDK) runs a different adb. Hopper prefers your SDK adb so they should agree; close extra tools, or point Hopper to your SDK in Settings. Check with `adb version`.

## `flutter devices` doesn't show the phone
- Confirm Hopper shows **Connected**.
- Run `adb devices`; the phone should be listed as `ip:port  device`.
- Make sure Flutter uses the same SDK adb (`flutter doctor -v` shows the Android SDK path).

## Android 10 and older
No wireless pairing exists. Use Hopper's **USB fallback** once per phone reboot.

## Install fails
| Code | Meaning | Fix |
|---|---|---|
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | Signature mismatch | Uninstall the existing app first |
| `INSTALL_FAILED_VERSION_DOWNGRADE` | Older than installed | Enable allow downgrade |
| `INSTALL_FAILED_INSUFFICIENT_STORAGE` | No space | Free space |
| `INSTALL_FAILED_USER_RESTRICTED` | Blocked by the phone | Xiaomi: enable *Install via USB* |
| `INSTALL_PARSE_FAILED_*` | Invalid APK | Rebuild |

## Mirroring issues
Black screen on secure apps is expected. No audio needs Android 11+. Lower max size or bitrate if laggy; Wi-Fi 5 GHz helps a lot.

## Still stuck?
Settings → **Export diagnostics** and attach the file to a GitHub issue.
