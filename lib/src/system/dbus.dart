// The embedder's silica/dbus channel: D-Bus calls and signals with JSON values (silica-desktop
// crates/embedder/src/dbus, docs/daemon.md). The client is silica_ui's SilicaDBus, shared with
// the library (the system look) and the shell: a channel has one signal handler.

import 'package:silica_ui/silica_ui.dart'
    show SilicaDBus, SilicaDBusBus, SilicaDBusSignal;

typedef DBus = SilicaDBus;
typedef DBusBus = SilicaDBusBus;
typedef DBusSignal = SilicaDBusSignal;
