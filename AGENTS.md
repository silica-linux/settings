# AGENTS.md

Settings is a Silica app: the rules of `silica-desktop/AGENTS.md` apply (clean-room, assets,
never crash, everything is a command, measured parity, English everywhere). On top of them:

## Clean-room

- Observations of the reference system live in the private repository `silica-reference`
  (`settings-panes.md`, `inventory/settings.md`), never here. The public spec is in
  `docs/spec/`, in our own words; code cites the inventory ids (ST-NAV-01, ST-KBD-01…).
- Interface texts are written in our own words, in English, with the Italian translation in
  `lib/l10n/app_it.arb`. No texts copied from the reference. The reference's panes for its own
  online services (assistant, game service, cloud account, payments) are left out.
- Measured numbers (sizes, colours, timings) can be used in code, with the id they come from;
  unmeasured ones are marked provisional.

## Never fake

- A setting is wired to the system or it is shown disabled, and its group's footer names the
  silica-os/settings issue that tracks the missing backend (`lib/src/model/issues.dart`).
  Nothing is saved for a component that does not read it yet. A change applied only later (the
  wallpaper at the next login) says so.
- Where Settings changes the system: `lib/src/system/` — silica-daemon over the embedder's
  `silica/dbus` channel (`system.dart`), the configuration files the shell watches in
  `$XDG_CONFIG_HOME/silica` (`config.dart`), the system's tools and services (`tools.dart`,
  `tools_host.dart`: nmcli, wpctl, timedatectl, hostnamectl, localectl, BlueZ, power profiles,
  xdg-settings), the machine (`host.dart`). A refused change shows why (`ui/errors.dart`).

## Work

- Before every commit: `dart format --set-exit-if-changed lib test`,
  `flutter analyze --fatal-infos`, `flutter test`, `tool/check_assets.sh`. One task per commit.
- Localization: every user-visible string goes in `lib/l10n/app_en.arb` (source) and
  `app_it.arb`; `flutter gen-l10n` regenerates `lib/l10n/gen/` (committed).
- For visual work: screenshots inside the Silica OS VM (`ui.screenshot`), compared with the
  spec; update the "Silica" column of `docs/spec/panes.md`.
- `silica_ui` is used from a tag (`ref` in `pubspec.yaml`); a widget other apps need goes into
  `silica-ui`, not here.
- Never crash: no daemon, a broken configuration file or a missing tool (`df`, `lpstat`) are
  normal cases.
- Issues and milestones: https://github.com/orgs/silica-os/projects/1.
