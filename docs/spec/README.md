# Settings · public specification

This folder describes how the system settings app of the reference system (macOS 27) is
organised and how it looks, as observed by measurement. Silica follows a clean-room
process: the observations were made on a real machine and are restated here in our own
words, with the numbers that came out of them. The raw material (screenshots, accessibility
dumps, session notes) stays in the private repository `silica-reference` and is not
reproduced here.

## Conventions

- **IDs.** `ST-xxx-nn` identifies an item of the settings inventory (for example `ST-NAV-04`
  is the grouped list layout, `ST-DSP-02` the display arrangement and colour options).
  `SH-xx-nn` identifies a measured sheet or panel opened from a pane. IDs are stable and
  are never renumbered.
- **Units.** Lengths are points at 1× (1 pt = 1 px on the reference display). Positions are
  measured from the top-left corner of the window or sheet named in each table.
- **Colours.** sRGB hex. Neutral grays were read directly; saturated colours were converted
  from the display profile to sRGB, and only the sRGB value is given.
- **Status.** Values marked *provisional* are estimates or single readings that need a
  second look; items marked *unmeasured* were not observed at all.
- **Names.** Panes, sections and controls are described in our own English words. The
  reference's labels are not quoted, and the reference's product and service names are
  replaced by a description of what they do.

## Reference conditions

Display 2560 × 1440 at 1×, 75 Hz, solid mid-gray wallpaper. Every pane was opened from
the sidebar and listed control by control without changing any setting; personal data
(accounts, device and network names) was never recorded. Light appearance for every pane,
dark for a few. The machine had no trackpad, no battery and no separate control-centre
pane, so those panes are absent.

## Files

| File | Covers |
| --- | --- |
| [window.md](window.md) | Window, sidebar, search, grouped list layout (ST-NAV-01..05) |
| [panes.md](panes.md) | Every pane, its sections and controls, measurement and Silica status |
| [appearance.md](appearance.md) | Appearance pane (ST-APP) |
| [desktop-dock.md](desktop-dock.md) | Desktop and Dock pane, hot corners sheet (ST-DSK) |
| [displays.md](displays.md) | Displays pane and night colour sheet (ST-DSP) |
| [wallpaper.md](wallpaper.md) | Wallpaper pane and screen saver sheet (ST-WLP, ST-SSV) |
| [keyboard.md](keyboard.md) | Keyboard pane and the system shortcut list (ST-KBD) |
| [accessibility.md](accessibility.md) | Accessibility display options and the shortcuts panel (ST-ACC) |
| [lock-screen.md](lock-screen.md) | Lock screen pane (ST-LCK) |
| [focus.md](focus.md) | Focus pane (ST-FOC) |
| [shell-config.md](shell-config.md) | The JSON files the shell reads from Settings: keys, values, defaults |
| [diagrams/window-layout.svg](diagrams/window-layout.svg) | Window, sidebar and grouped list geometry |
