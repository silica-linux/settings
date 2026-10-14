# Accessibility

Inventory items ST-ACC-01, ST-ACC-02; sheets SH-AX-01, SH-AX-02, SH-AX-06, SH-AX-08.
Light captured for the pane and seven sub-panes; the display options were also captured
in dark while on.

The pane's structure is in [panes.md](panes.md). The sub-panes opened were the screen
reader, zoom, display, motion, spoken content, audio and pointer control; their layout
follows the grouped list ([window.md](window.md)) and is not detailed further here.

## Display options and their effect

| Option | Effect measured |
| --- | --- |
| Reduce transparency | the menu bar becomes opaque, light **`#dadada`**, dark **`#202020`** (instead of the translucent tint over the wallpaper); the Dock becomes opaque, light `#aeafb3`, dark near black (≈ `#050508`); the settings sidebar and its selected row become solid, selection `#2565f1` |
| Increase contrast | the Dock fill darkens (light `#78797c`, dark `#48484b`); the menu bar is unchanged; switch off-tracks go from `#dddddd` to `#9f9f9f` with a darker 1 pt edge (`#9b9b9b`); separators and the selection darken |
| Show borders | only switches in the on state change, gaining a darker accent outline; off switches, rows and buttons are unchanged in this pane |

Switch geometry read in this pane: track **36 × 16**, knob **21** white.

## Accessibility shortcuts panel (SH-AX-06)

Opened with ⌥⌘F5.

| Item | Value |
| --- | --- |
| Panel | **500 × 1104**, floating, centred on the main display |
| Backdrop | a full-screen dimming layer: the mid-gray wallpaper `#7a7b80` drops to `#313134` (≈ 40 % brightness) |
| Content | a title and three grouped lists: vision (10 rows), physical (7), hearing (3); rows **37** tall with a switch each |
| Buttons | keyboard shortcuts…, settings…, Done |
