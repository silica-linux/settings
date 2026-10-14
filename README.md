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

A Flutter app for the [Silica desktop](https://github.com/silica-linux/silica-desktop), built on
[`silica_ui`](https://github.com/silica-linux/silica-ui). It drives the system through
silica-daemon (D-Bus) and the commands of Ossido. Panes and behaviors come from the 1:1
inventory measured in silica-reference (clean-room: nothing copied, texts and graphics are our
own). App id `dev.frascella.Settings`, icon `settings` from silica-icons.

## What works

Appearance (light and dark, accent colour), Wi-Fi (on/off, joining saved networks), Bluetooth
(on/off, connecting paired devices), Network status, Sound (output volume, mute, output
device), Focus (Do Not Disturb), Battery, Desktop and Dock (magnification, recent apps),
Wallpaper, Keyboard (key repeat rate and delay), Lock Screen choices, General › About, Storage,
Sharing, Date and Time, Language, Users and Printers (read-only where noted). Every other pane
is laid out as measured and marked "Not available yet". The state of each pane is in
[`docs/spec/panes.md`](docs/spec/panes.md).

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
