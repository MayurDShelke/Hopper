# Wireless ADB: How Hopper Connects

The core of Hopper. This document describes the exact flows and failure handling.

## 1. Background (Android 11+)
- **Wireless debugging** exposes two mDNS services on the phone:
  - `_adb-tls-pairing._tcp`: appears only while a pairing dialog (code or QR) is open
  - `_adb-tls-connect._tcp`: appears while Wireless debugging is on; its **port changes** on each toggle/reboot
- **Pairing** exchanges keys once; the phone then remembers the laptop. Hopper never handles keys itself (adb stores them in `~/.android`).
- Wireless debugging turns itself off when the phone leaves the Wi-Fi network.

## 2. Discovery (Dart `multicast_dns`)
- Query PTR for both service types, then resolve SRV (port) and A (IPv4) records.
- Bind to the **Wi-Fi adapter's interface** (skip VPN, WSL, Hyper-V and virtual adapters).
- Poll with short bursts while the pairing/connect screens are open; slow background watch for saved devices.
- If binding fails (port 5353 in use, e.g. by Bonjour), fall back to parsing `adb mdns services`, then to manual entry.

## 3. QR pairing
1. Hopper generates a random service name (`hopper-<random>`) and a 6-digit-or-longer random password.
2. QR payload: `WIFI:T:ADB;S:<name>;P:<password>;;`
3. User scans from the phone's *Pair device with QR code*.
4. Phone advertises `_adb-tls-pairing._tcp` with instance name `<name>`.
5. Hopper matches the instance name, reads IP and port, runs `adb pair <ip>:<port> <password>`.
6. On success, Hopper waits for `_adb-tls-connect._tcp` from the same phone and connects.

## 4. Code pairing
1. User opens *Pair device with pairing code* on the phone.
2. Hopper discovers the `_adb-tls-pairing._tcp` service (IP and port) automatically.
3. User types only the 6-digit code.
4. `adb pair <ip>:<port> <code>`, then connect as above.

## 5. Connection manager state machine

```
          ┌────────────┐  service seen   ┌───────────┐
 start ─► │ Unreachable│ ───────────────►│ Discovered│
          └─────▲──────┘                 └─────┬─────┘
                │ lost / timeout               │ connect
          ┌─────┴──────┐   adb connect ok ┌────▼─────┐
          │  Offline   │◄─────────────────│Connecting│
          └─────▲──────┘     fail/retry   └────┬─────┘
                │ drop                          │ ok
          ┌─────┴──────┐                  ┌────▼─────┐
          │Unauthorized│◄─────────────────│Connected │
          └────────────┘   not trusted    └──────────┘
```

## 6. Reconnect logic (saved device)
1. Saved record: `{ instanceName, label, lastIp, lastPort, autoReconnect }`.
2. Watch mDNS for a `_adb-tls-connect._tcp` instance matching `instanceName`.
3. When seen: TCP reachability check to `ip:port` → `adb connect ip:port` → verify state `device`.
4. On failure: retry with backoff (1s, 2s, 4s, 8s, then every 30s), capped; show reason.
5. If mDNS is silent but `lastIp` responds on the last port, try it once.
6. If still failing, show diagnostics and the manual port-only field (IP prefilled).

## 7. Edge cases

| Case | Handling |
|---|---|
| Port changed | Rediscover via mDNS; never ask the user |
| IP changed (DHCP) | Match by instance name |
| Phone left Wi-Fi / Wireless debugging auto-off | Show "Turn Wireless debugging back on" |
| Two phones with similar names | Match on full instance name |
| Stale `adb connect` entry | `adb disconnect` before reconnect |
| Windows network profile Public | Detect via PowerShell/WMI call; guide to switch to Private |
| Firewall blocks UDP 5353 | Offer a one-click rule (requires admin) or instructions |
| Router client isolation | Reachability test fails while mDNS silent → explain |
| adb server restarted by another tool | Detect disconnect, re-run connect |
| Pairing code expired | Prompt to reopen the pairing dialog |

## 8. Android 10 and older (USB fallback)
No wireless pairing exists. Flow: detect USB device → read IP → `adb tcpip 5555` → `adb connect ip:5555` → save. Needs a cable once per phone reboot.

## 9. Phone-side checklist shown in the app
1. Developer options on
2. Wireless debugging on
3. Same Wi-Fi as the laptop
4. Developer options → **Disable adb authorization timeout** (optional, reduces re-auth prompts)
5. On first connect, tick **Always allow on this network**
