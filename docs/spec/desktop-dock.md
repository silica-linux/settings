# Desktop and Dock pane

Inventory items ST-DSK-01 to ST-DSK-04. Light and dark captured.

## Sections

1. **Dock**: size slider, magnification slider, three pop-ups (position, minimise effect,
   title-bar double-click action) and switches (minimise into the app icon, auto-hide,
   animate opening apps, show indicators of open apps, show suggested and recent apps).
2. **Desktop and window staging**: where to show desktop items, what a click on the
   wallpaper does, window staging on/off, recent apps and grouping in window staging.
3. **Widgets**: show on the desktop and in window staging, dim widgets.
4. **Default web browser** pop-up.
5. **Windows**.
6. **Spaces overview**: four switches (rearrange spaces by use, switch to a space with the
   app's windows, group windows by app, separate spaces per display) and a drag-to-top
   switch; a shortcuts button and a hot corners button.

## Values read on the reference machine

| Setting | Value |
| --- | --- |
| Dock size slider | 0.3839 on a 0–1 scale, giving 63 pt Dock cells |
| Magnification slider | 0.4286 (68 pt cell under the pointer) |
| Position | bottom |
| Minimise effect | the genie-style effect |
| Title-bar double-click | zoom |
| Minimise into the app icon | off |
| Auto-hide | off |
| Animate opening apps | on |
| Indicators of open apps | on |
| Suggested and recent apps | off |
| Click on the wallpaper shows the desktop | only in window staging |
| Window staging | off |
| Spaces: rearrange / switch / group by app / separate per display | on / on / off / on |

These are the reference machine's values, which are close to the factory defaults; Silica's
own defaults are decided in `silica-desktop`.

## Hot corners sheet (ST-DSK-04, SH-HC-02)

| Item | Value |
| --- | --- |
| Sheet | **711 × 193** |
| Layout | four pop-ups **269 × 24**, one per screen corner, around a 100 × 69 desktop preview with corner marks; a Done button |

- Each pop-up offers: spaces overview, app windows, show desktop, notifications, app
  launcher, quick note, start screen saver, disable screen saver, put the display to sleep,
  lock screen, and "none" (checked when the corner is unused). Separators group them.
- Holding modifier keys while the menu is open turns every action into a variant that only
  fires when the same modifiers (any combination of ⌘, ⌥, ⌃, ⇧) are held at the corner.
