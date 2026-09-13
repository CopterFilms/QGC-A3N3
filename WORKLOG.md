# WORKLOG — QGroundControl A3N3 (CopterFilms custom)

Run log of decisions and incidents for the custom QGroundControl Android build
that pairs with `A3N3-MAVLINK-BRIDGE`. Purpose: when working on the bridge
firmware (or any other project), this file is the source of truth for what was
changed here and why.

Sibling project: `A3N3-MAVLINK-BRIDGE` firmware — see its `WORKLOG.md`.

## Context (all dates 2026-09-12)

Custom APK targets a telemetry-only chain:
`DJI N3 → ESP32 bridge (OSDK) → ELRS/Crossfire receiver (MAVLink) → GCS app`.
Built with `QGC_A3N3_BRIDGE` defined (`custom/CMakeLists.txt` →
`src/CMakeLists.txt`), Android SDK/NDK/Qt 6.11.1, signed v3.

## 2026-09-12 — Incidents & dispositions

### OSD freezes on ARM / almost blank — ROOT CAUSE IS IN THE BRIDGE, not in the app
- User reflashed bridge with `MAVLINK_RATE_HZ = 50` (bridge commit `9f7a60b`)
  and the VTX OSD froze on ARM. Diagnosis: synchronous per-byte serial write at
  115200 exceeded the 20 ms tick, starved the OSD DisplayPort feed, Ascent VTX
  dropped the session. **Bridge fix: default back to 20 Hz** (final state =
  M1-proven TX path). An extra attempt (non-blocking TX ring+drain + forced
  resync on arm edge, bridge commit `0395270`) left the OSD almost blank and was
  also reverted. See bridge `WORKLOG.md`; its "OSD almost blank" entry has the
  field caveat (power-cycle the VTX before blaming a build).
- The app reads raw facts (`CustomAttitudeWidget` → `vehicle.roll.rawValue`);
  there is **no** app-side smoothing or buffering, so latency/freezes observed
  in the app are chain-composed, not app bugs.

### GCS latency ~1.5 s (field complaint)
- Measured chain: ESP32 → receiver UART (115200, ~ms) → RF hop (ELRS/Crossfire)
  → relay to phone/WiFi. The ~1.5 s lives in the RF hop + relay, NOT in bridge
  or QGC code. Changing the bridge web setting `mavRateHz` (4→10) had no effect,
  consistent with this.
- Action for the user: raise the **telemetry ratio / packet rate on the
  transmitting radio** (ELRS: Packet Rate ≥250 Hz + telemetry ratio; Crossfire:
  telemetry 150 Hz/Auto). NOT a code change.

### Banners suppressed for telemetry-only builds
- "was unable to retrieve the full set of parameters…" → `ParameterManager.cc`,
  keep log, drop `QGC::showAppMessage` (`QGC_A3N3_BRIDGE`).
- "Parameters are missing from firmware… BAT_LOW_THR/CRIT/EMERGEN_THR" →
  `QGCApplication::reportMissingParameter` early-return. Triggered by
  `PX4BatteryIndicator.qml` reading those facts.
- Firmware-version banner → `PX4FirmwarePlugin::_handleAutopilotVersion`
  early-return.
- Param download skipped entirely: `Vehicle::_a3n3BridgeActive()` (PX4 +
  `(_custom_mode >> 16) == 0`) + `InitialConnectStateMachine` state skip.
  Mode names decoded from the low-byte DJI `DisplayMode`.

### UI changes
- `MainStatusIndicator.qml`: "Not Ready" → "Disarmed".
- `FlyViewCustomLayer.qml`: bottom compass bar removed (`compassBackground`
  circular keeps).

## Build artifacts

- APKs: `build/Android/android-build/Custom-QGroundControl.apk` (M1..M3).
- Bridge firmware: compiles 1,040,095 B (79 % flash). Flash via web `/firmware`
  or arduino-cli `esp32:esp32:esp32`.

## Chronology (QGC commits on `master`)

- F4 `05dc06ae2` detect A3N3 bridge w/o params · `8e127d0e5` suppress version
  banner · `44efb4297` remove bottom compass bar
- F5 `a37c40137` "Disarmed" · `59fa2ede2` silence param banners