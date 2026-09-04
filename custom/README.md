# QGC A3N3 BRIDGE — Custom GCS

Custom build overlay for the A3N3 BRIDGE telemetry link (DJI N3/A3 -> MAVLink).
Part of the CopterFilms drone-control project. Overlay lives in `custom/`.

# QGroundControl Ground Control Station

## Custom Build Example

To build this sample custom version:

1. Clean your build directory of any previous build.
2. Rename `custom-example` to `custom`.
3. `cd custom` and build QGC.

![Custom Build Screenshot](README.jpg)

See the [QGC Dev Guide](https://dev.qgroundcontrol.com/en/custom_build/custom_build.html) for what a
custom build is and how to create your own.

This example demonstrates:

- **Off-the-shelf commercial vehicle** — most vehicle setup is hidden (pre-configured by the vendor),
  giving a simpler UI; the full experience stays available in **Advanced Mode**.
- **Custom branding** — images and color palette matching a corporate identity.
- **Custom interface** — e.g. a custom instrument widget replacing the standard QGC UI (see screenshot).
- **Overridden application settings** — hides options users shouldn't change and adjusts defaults.
- **Fully commented source** explaining what it does and why.
