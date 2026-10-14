# Displays pane

Inventory items ST-DSP-01 to ST-DSP-03, sheet SH-NS-01. Light captured.

## Pane

1. Arrangement: one thumbnail per display, an arrange button.
2. A pop-up for how the selected display is used (its options were not listed).
3. Resolution list; the native mode is marked as the default (2560 × 1440 on the
   reference panel, which offered no HiDPI modes).
4. A switch to list every resolution.
5. Pop-ups: colour profile, refresh rate, rotation, TV mode.
6. Advanced and night colour buttons.

## Night colour sheet (SH-NS-01)

| Item | Value |
| --- | --- |
| Sheet | **528 × 316** |
| Controls | schedule pop-up (off by default), "on until tomorrow" switch, colour temperature slider (default at the middle, 0.5; less warm ↔ more warm), help button, Done |

- Turning it on changes nothing in screenshots: the warm shift is applied after the image
  is composed (in the display's colour tables). Silica should do the same, so that
  screenshots stay neutral.

## Silica

Settings talks to silica-daemon (`System1.Outputs`, `ConfigureOutput`, `SetNightLight`; the
`displays` and `nightlight.*` state keys); Ossido applies a change at once and keeps it in
`displays.json` per display (the key is the display's identity, so a display gets its choice
back on any connector).

- The pane shows one thumbnail per display, and for the chosen one a resolution pop-up (the
  sizes of its modes, largest first, the native one marked), a refresh rate pop-up for that
  size, a scale pop-up (1 to 4 in quarter steps) and a rotation pop-up (standard, 90°, 180°,
  270°). Only the display in use is configurable for now.
- A change of resolution, refresh rate, scale or rotation opens the sheet **Keep these display
  settings?** with a 15 second countdown. Keep leaves it; Revert, running out of time, or
  closing the sheet by any other way applies the previous mode, scale and rotation again.
  *Provisional: the reference's countdown is not measured.*
- Night light (the sheet is 528 wide, provisional) has a switch (`enabled`), a schedule pop-up
  (all day: on while enabled, sunset to sunrise, or custom with from and to times in 24-hour
  form), and a colour temperature slider from neutral (6500 K) to the warmest (1900 K). It maps
  one to one onto the daemon's keys, unlike the reference's schedule pop-up plus "until
  tomorrow" switch. Only the end of a slider drag is sent.
- Without answer from the compositor the pane lists what `/sys/class/drm` knows, read-only.
- The arrangement of several displays, the main display and the colour profile still wait for
  their backends (#63).
