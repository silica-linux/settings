// The system services Settings drives itself, next to silica-daemon: NetworkManager (nmcli),
// PipeWire (wpctl), systemd's timedated, hostnamed and localed (timedatectl, hostnamectl,
// localectl), BlueZ and the power profiles over the system bus, the default web browser
// (xdg-settings), the connected displays (/sys/class/drm) and the user accounts (passwd,
// group). [SystemTools] is what the panes use; [HostSystemTools] (tools_host.dart) is the real
// one, tests use a fake. Every call may fail: a missing tool or service is a normal case, and
// a refused change comes back as a [ToolError] the pane shows.

import 'package:flutter/foundation.dart';

/// Why a change did not happen.
@immutable
class ToolError {
  const ToolError(this.kind, [this.detail = '']);

  final ToolErrorKind kind;

  /// The tool's own message (stderr), for the details.
  final String detail;

  @override
  String toString() => '${kind.name}: $detail';
}

enum ToolErrorKind {
  /// The tool or the service is not on this system.
  missing,

  /// The system asked for an administrator's password and Silica has no authentication agent
  /// to ask for it yet.
  authentication,

  /// A wrong password or a network that refused the connection.
  refused,

  /// Anything else.
  failed,
}

/// A Wi-Fi network around, as NetworkManager scans it.
@immutable
class AccessPoint {
  const AccessPoint({
    required this.ssid,
    required this.strength,
    required this.security,
    required this.inUse,
  });

  final String ssid;
  final int strength;

  /// NetworkManager's security text (`WPA2`, `WPA1 WPA2`, `SAE`…); empty when open.
  final String security;
  final bool inUse;

  bool get secured => security.isNotEmpty && security != '--';
}

/// A network device (`nmcli device`).
@immutable
class NetworkDevice {
  const NetworkDevice({
    required this.name,
    required this.type,
    required this.state,
    required this.connection,
  });

  /// The interface (`wlp2s0`, `enp3s0`).
  final String name;

  /// `wifi`, `ethernet`, `bridge`, `wireguard`, `loopback`…
  final String type;

  /// `connected`, `disconnected`, `unavailable`, `connecting (…)`.
  final String state;
  final String connection;

  bool get connected => state == 'connected';
}

/// The addresses of a device (`nmcli device show`).
@immutable
class DeviceDetails {
  const DeviceDetails({
    this.hardwareAddress = '',
    this.ipv4 = const [],
    this.gateway = '',
    this.dns = const [],
    this.ipv6 = const [],
  });

  final String hardwareAddress;

  /// Addresses with their prefix (`192.168.1.20/24`).
  final List<String> ipv4;
  final String gateway;
  final List<String> dns;
  final List<String> ipv6;
}

/// A saved NetworkManager connection.
@immutable
class SavedConnection {
  const SavedConnection({
    required this.name,
    required this.type,
    required this.active,
    this.autoconnect = true,
  });

  final String name;

  /// `802-11-wireless`, `802-3-ethernet`, `vpn`, `wireguard`…
  final String type;
  final bool active;
  final bool autoconnect;

  bool get isVpn => type == 'vpn' || type == 'wireguard';
  bool get isWifi => type == '802-11-wireless' || type == 'wifi';
}

/// An audio device: an output (sink) or an input (source).
@immutable
class AudioDevice {
  const AudioDevice({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.volume,
    this.muted = false,
  });

  /// The PipeWire node id.
  final int id;
  final String name;
  final bool isDefault;

  /// 0–1 (PipeWire allows more; shown clamped).
  final double volume;
  final bool muted;
}

@immutable
class AudioDevices {
  const AudioDevices({this.outputs = const [], this.inputs = const []});
  final List<AudioDevice> outputs;
  final List<AudioDevice> inputs;

  AudioDevice? get defaultInput => inputs.where((d) => d.isDefault).firstOrNull;
}

/// Date, time and time zone (timedated).
@immutable
class ClockState {
  const ClockState({
    this.timezone = '',
    this.ntp = false,
    this.canNtp = false,
    this.synchronized = false,
  });

  final String timezone;

  /// Set the time automatically (systemd-timesyncd or chrony).
  final bool ntp;
  final bool canNtp;
  final bool synchronized;
}

/// The system language and formats (localed).
@immutable
class LocaleState {
  const LocaleState({this.language = '', this.formats = ''});

  /// `LANG` (`en_US.UTF-8`).
  final String language;

  /// `LC_TIME` when it differs from `LANG` (the region's formats); empty otherwise.
  final String formats;
}

/// A Bluetooth device BlueZ knows: paired, or found by a scan.
@immutable
class BluetoothPeer {
  const BluetoothPeer({
    required this.path,
    required this.address,
    required this.name,
    required this.icon,
    required this.paired,
    required this.connected,
    this.battery,
  });

  /// The BlueZ object path (`/org/bluez/hci0/dev_AA_BB_…`).
  final String path;
  final String address;
  final String name;

  /// The BlueZ icon name (`audio-headphones`, `input-mouse`…).
  final String icon;
  final bool paired;
  final bool connected;

  /// Battery percentage, when the device reports it.
  final int? battery;
}

/// The power mode (power-profiles-daemon).
enum PowerProfile { powerSaver, balanced, performance }

@immutable
class PowerState {
  const PowerState({
    this.profiles = const [],
    this.active,
    this.secondsToEmpty = 0,
    this.secondsToFull = 0,
    this.capacity = 0,
  });

  /// The modes this machine offers; empty without power-profiles-daemon.
  final List<PowerProfile> profiles;
  final PowerProfile? active;

  /// UPower's estimates, 0 when unknown.
  final int secondsToEmpty;
  final int secondsToFull;

  /// The battery's health: its full charge against its design, 0–100; 0 when unknown.
  final double capacity;
}

/// An application that can open web pages.
@immutable
class AppEntry {
  const AppEntry({required this.id, required this.name});

  /// The desktop entry file name (`org.mozilla.firefox.desktop`).
  final String id;
  final String name;
}

/// A display connected to the machine (`/sys/class/drm`).
@immutable
class DisplayOutput {
  const DisplayOutput({
    required this.connector,
    required this.modes,
    this.enabled = true,
  });

  /// `eDP-1`, `HDMI-A-1`, `Virtual-1`.
  final String connector;

  /// The modes the display offers, best first (`2560x1440`).
  final List<String> modes;
  final bool enabled;
}

/// A user account (passwd).
@immutable
class UserAccount {
  const UserAccount({
    required this.login,
    required this.name,
    required this.uid,
    required this.admin,
  });

  final String login;
  final String name;
  final int uid;

  /// Member of `wheel` (or `sudo`).
  final bool admin;
}

/// An app that sent notifications, as silica-daemon's history knows it.
@immutable
class NotifyingApp {
  const NotifyingApp({required this.key, required this.name, this.icon = ''});

  /// The key the shell's notifications.json uses: the desktop entry, else the app name.
  final String key;
  final String name;
  final String icon;
}

/// What Settings changes in the system without silica-daemon.
abstract class SystemTools {
  // Network.
  Future<List<AccessPoint>> accessPoints({bool rescan = false});
  Future<List<NetworkDevice>> networkDevices();
  Future<DeviceDetails> deviceDetails(String device);
  Future<List<SavedConnection>> savedConnections();
  Future<ToolError?> joinWifi(String ssid, {String? password});
  Future<ToolError?> disconnect(String device);
  Future<ToolError?> forgetConnection(String name);
  Future<ToolError?> setAutoconnect(String name, bool enabled);
  Future<ToolError?> setConnectionActive(String name, bool active);

  // Audio.
  Future<AudioDevices> audioDevices();
  Future<ToolError?> setDefaultAudio(int id);
  Future<ToolError?> setAudioVolume(int id, double volume);
  Future<ToolError?> setAudioMuted(int id, bool muted);

  // Date and time.
  Future<ClockState> clock();
  Future<List<String>> timezones();
  Future<ToolError?> setTimezone(String zone);
  Future<ToolError?> setNtp(bool enabled);

  // Computer name.
  Future<String> computerName();
  Future<ToolError?> setComputerName(String name);

  // Language and region.
  Future<LocaleState> locale();
  Future<List<String>> locales();
  Future<ToolError?> setLocale({required String language, String formats});

  // Keyboard layouts (the input sources, written to keyboard.json).
  /// The X11 layouts (`localectl list-x11-keymap-layouts`): `us`, `it`…
  Future<List<String>> keymapLayouts();

  /// The variants of [layout] (`localectl list-x11-keymap-variants`): `nodeadkeys`…
  Future<List<String>> keymapVariants(String layout);

  /// Readable names, `it` → `Italian`, `it(winkeys)` → `Italian (Winkeys)`, from xkb's rules
  /// list when the system has it.
  Future<Map<String, String>> keymapNames();

  // Bluetooth.
  Future<List<BluetoothPeer>> bluetoothPeers();
  Future<ToolError?> setBluetoothDiscovery(bool discovering);
  Future<ToolError?> pairBluetooth(String path);
  Future<ToolError?> connectBluetooth(String path, bool connect);
  Future<ToolError?> forgetBluetooth(String path);

  // Power.
  Future<PowerState> power();
  Future<ToolError?> setPowerProfile(PowerProfile profile);

  // Default apps.
  Future<List<AppEntry>> browsers();
  Future<String> defaultBrowser();
  Future<ToolError?> setDefaultBrowser(String id);

  // Displays and accounts.
  Future<List<DisplayOutput>> displays();
  Future<List<UserAccount>> users();

  // Notifications.
  Future<List<NotifyingApp>> notifyingApps();
}
