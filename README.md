<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset=".github/silica-logo-dark.svg">
    <img alt="Silica" src=".github/silica-logo-light.svg" width="200">
  </picture>
</p>

<h1 align="center">Settings</h1>

<p align="center">
  <b>The settings app of Silica.</b><br>
  Every system preference in one place: appearance, displays, sound, network, Bluetooth, Dock, desktop, notifications, Focus, keyboard, accessibility and more.
</p>

<p align="center">
  <img alt="Flutter: app" src="https://img.shields.io/badge/Flutter-app-02569B?style=flat-square&logo=flutter">
  <img alt="license: MIT / Apache-2.0" src="https://img.shields.io/badge/license-MIT%20%2F%20Apache--2.0-3a3a3a?style=flat-square">
  <img alt="status: alpha" src="https://img.shields.io/badge/status-alpha-e0a030?style=flat-square">
</p>

A Flutter app for the [Silica desktop](https://github.com/silica-os/silica-desktop), built on
[`silica_ui`](https://github.com/silica-os/silica-ui). It drives the system through
silica-daemon (D-Bus) and the commands of Ossido. Panes and behaviors come from the 1:1
inventory measured in silica-reference (clean-room: nothing copied, texts and graphics are our
own). App id `dev.frascella.Settings`, icon `settings` from silica-icons.

## What works

Appearance (light, dark and automatic, accent colour, sidebar icon size, scroll bars), Wi-Fi (on/off,
scanning, joining with a password or a hidden network, details, auto-join, forgetting),
Bluetooth (on/off, scanning, pairing, connecting, forgetting), Network (services, addresses),
VPN (connecting), Battery and Energy (level, time left, health, power mode, low power mode),
Desktop & Dock (every Dock option the shell reads, default web browser), Menu Bar (status
items), Displays (resolution, refresh rate, scale, rotation with a keep-or-revert sheet,
night light), Wallpaper, Sound (output and input devices
and volumes, alert sound and volume, interface sounds), Notifications (per-app banners),
Focus (Do Not Disturb and Focus modes), General › About, Storage (empty the trash), Sharing
(computer name), Date & Time, Language & Region, Users & Groups (accounts), Keyboard (key
repeat, input sources, shortcuts), Mouse and Trackpad, Energy and Battery (display off, sleep)
and Printers (default printer). Every control that waits for a backend is disabled and its group names
the issue that tracks it. The state of each pane is in
[`docs/spec/panes.md`](docs/spec/panes.md).

Settings drives the system through silica-daemon (D-Bus), the configuration files the shell
watches in `$XDG_CONFIG_HOME/silica`, and the system's own tools: NetworkManager (`nmcli`),
PipeWire (`wpctl`), systemd (`timedatectl`, `hostnamectl`, `localectl`), BlueZ and
power-profiles-daemon over the system bus, `xdg-settings` and CUPS (`lpoptions`). Changes
polkit reserves to administrators go through silica-daemon's authentication agent, which
shows the system password dialog; the controls are enabled only while the agent is
registered (`Authentication1.Registered`), otherwise Settings says why.

## Building

```sh
flutter pub get
flutter test
cargo xtask bundle ~/silica/settings          # from silica-desktop
cargo xtask install-app ~/silica/settings     # the .desktop entry from linux/
```

The entrypoint takes a pane name as its first argument (`--dart-arg wifi` on the embedder)
to open that pane directly; Appearance otherwise.

## License

MIT OR Apache-2.0.
