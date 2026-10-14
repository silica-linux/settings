# Panes

Every pane of the reference settings app, in sidebar order, with its sections and
controls described in our own words. "Measured" is the state of the reference
measurements (`measured`, `partial`, `missing`); "Silica" is the state of our
implementation. The settings app has no code yet, so every pane is `missing` in Silica.

Rows marked "— not on the reference machine" are panes that only appear with hardware the
reference machine lacked.

## Window and navigation

| ID | Item | Measured | Silica |
| --- | --- | --- | --- |
| ST-NAV-01 | Window: fixed width, resizable height, toolbar with back / forward | measured | missing |
| ST-NAV-02 | Sidebar: icons, grouped rows, selection, account cell | measured | missing |
| ST-NAV-03 | Sidebar search with two-line results | measured | missing |
| ST-NAV-04 | Grouped list layout shared by all panes | measured | missing |
| ST-NAV-05 | Pane and sub-pane transition | missing | missing |

Details: [window.md](window.md).

## Sidebar panes

| ID | Pane | Sections and controls, in order | Measured | Silica |
| --- | --- | --- | --- | --- |
| ST-NET-01 | Wi-Fi | on/off card; the current network with its status and a details button; personal hotspots; known networks; other networks (rows with a lock, signal strength and a more button) plus "other…"; two pop-ups for asking to join networks and hotspots; an advanced button. The details sub-pane was not opened | partial | missing |
| ST-NET-02 | Bluetooth | on/off card with a note on visibility; my devices (rows with battery level and an info button); nearby devices with a progress spinner | measured | missing |
| ST-NET-03 | Network | Wi-Fi and firewall rows; other services (wired, bridges, tethered phone) with a coloured status dot each; a "…" menu for adding or ordering services | measured | missing |
| ST-NET-03 | VPN | empty state saying there is no VPN configuration; a VPN and privacy button; an add (+) menu | measured | missing |
| ST-PWR-01 | Energy | three switches: keep the computer awake when the display is off, wake for network access, start again after a power failure | measured | missing |
| ST-PWR-01 | Battery | — not on the reference machine | missing | missing |
| ST-GEN-01 | General | header card; navigation rows in groups: about; software update, storage; warranty; nearby sharing and device hand-off; sharing; date and time, startup disk, login items and extensions, autofill and passwords, language and region, backups; device management; transfer or reset | measured | missing |
| ST-GEN-02 | General › About | product card, specification table, displays, storage | measured | missing |
| ST-GEN-03 | General › other sub-panes | software update (status rows); storage (usage bar and category list); warranty; nearby sharing; sharing (switches with info buttons, computer name); date and time; startup disk (disk tile); login items (table, background-app switches, extension list with a segmented control); autofill and passwords; language and region (languages table, region pop-ups, radio groups); backups; device management; transfer or reset | partial | missing |
| ST-ACC-01, ST-ACC-02 | Accessibility | header card; then five groups of navigation rows. Vision: screen reader, zoom, larger text, display, motion, spoken content, audio descriptions. Physical: voice control, keyboard, pointer control, switch control. Hearing: audio, real-time text, captions, live captions, name recognition. Speech: live speech, personal voice, vocal shortcuts. General: the assistant, the accessibility shortcut | partial | missing |
| ST-APP-01..04 | Appearance | light / dark / automatic previews; glass preview card with an opacity slider; theme: accent colour, text highlight colour, icon and widget style, folder colour; windows: sidebar icon size, tint windows from the wallpaper, scroll bar visibility, click-in-scroll-bar behaviour | measured (ST-APP-02, -04 partial) | missing |
| ST-CCT-01 | Menu bar | auto-hide pop-up, menu bar background switch, number of recent items (stepper), suggestions switch; list of menu bar controls (checkbox, icon, name, a "show when active" pop-up each) with an "add controls…" button; per-app permission switches | measured | missing |
| ST-DSP-01..03 | Displays | arrangement thumbnails with an arrange button; use-as pop-up; resolution list (the panel's native mode is the default); show-all-resolutions switch; pop-ups for colour profile, refresh rate, rotation and TV mode; advanced and night colour buttons | measured | missing |
| ST-DSK-01..04 | Desktop and Dock | Dock (size and magnification sliders, three pop-ups, switches); desktop and window staging; widgets; default browser pop-up; windows; spaces overview (switches); shortcuts button; hot corners button | measured | missing |
| ST-WLP-01, ST-WLP-02, ST-SSV-01 | Wallpaper | current wallpaper card (preview, fill pop-up, all-spaces switch); display pop-up; screen saver and clock appearance buttons; one horizontal row of thumbnails per category, each with a "show all (n)" button | measured | missing |
| ST-SIR-01 | Assistant | header card; enable, language, voice, responses; an external model extension; visual search switch; app access | measured | missing |
| ST-SPT-01 | Search | header card; two switches; two reset buttons; results from apps (one app row with a switch each) | measured | missing |
| ST-NTF-01 | Notifications | header card; notification centre options (previews pop-up and three conditions); notification summaries; one row per app with its icon and a summary of its settings. The per-app sub-pane and the alert style were not opened | partial | missing |
| ST-SND-01 | Sound | sound effects (alert sound pop-up with a play button, output device pop-up, alert volume slider, three switches); output / input segmented control; device table (name, type); output volume slider with a mute checkbox | measured | missing |
| ST-FOC-01 | Focus | five modes as rows; add a mode; share-across-devices switch; focus status row | measured | missing |
| ST-SCT-01 | Screen time | groups of navigation rows: activity, limits, communication, restrictions; sharing and lock switches; family; app activity switch | measured | missing |
| ST-LCK-01 | Lock screen | two pop-ups (display off, password delay), three switches, login window radio group, one switch, accessibility options button | measured | missing |
| ST-PRV-01 | Privacy and security | header card; one row per permission with icon, name and count (location, …, local network, speech recognition, …). Sub-panes not opened | partial | missing |
| ST-USR-01 | Fingerprint and password | password row with a change button; a watch-unlock row with a switch | measured | missing |
| ST-USR-01 | Users and groups | user rows (32 pt photo, name, role, info button); guest user; add group / add user buttons; automatic login and network server rows | measured | missing |
| ST-ACN-01 | Internet accounts | one row per account (icon, name, services); add account button | partial | missing |
| ST-ACN-01 | Game service | profile card; friends, visibility, requests, activity and privacy groups; sign-out | partial | missing |
| ST-ACN-01 | Cloud account | storage card with a usage bar and a manage button; saved-to-cloud tiles (3 × 2); extra feature tiles; two rows | partial | missing |
| ST-ACN-01 | Payments | cards, autofill, payment details (pop-ups), hide-my-email switch, order tracking switch | partial | missing |
| ST-ACN-01 | Personal account | not opened (personal data) | missing | missing |
| ST-KBD-01..14 | Keyboard | key repeat and delay sliders; function key pop-up; keyboard navigation switch; shortcuts button; text input (input sources edit button, text replacements); dictation switch, language, microphone and shortcut pop-ups; set up keyboard button | measured (ST-KBD-02..13 partial) | missing |
| ST-INP-01 | Mouse | pointer speed slider, natural scrolling switch, secondary click pop-up, double-click speed and scroll speed sliders; advanced and wireless mouse set-up buttons | measured | missing |
| ST-INP-02 | Trackpad | — not on the reference machine | missing | missing |
| ST-PRT-01 | Printers and scanners | default printer and paper size pop-ups; device list (empty); add printer button | measured | missing |

## App settings windows used as layout references

| ID | Item | Measured | Silica |
| --- | --- | --- | --- |
| ST-APPSET-01..04 | File manager settings (general, tags, sidebar, advanced) | measured | belongs to the file manager |
| ST-APPSET-05..07 | Terminal settings (general, profiles, window groups, encodings) | partial | belongs to Terminal (`silica-linux/terminal`, `docs/spec/settings.md`) |

## Not measured yet

- The personal account pane, most sub-panes beyond General and seven accessibility
  sub-panes, sheets other than the night colour, hot corner and screen saver ones, pane
  transitions, and the dark appearance of most panes.
