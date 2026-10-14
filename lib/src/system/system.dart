// The system state and actions Settings changes, from silica-daemon
// (`dev.frascella.Silica.System1`, silica-desktop docs/daemon.md): Wi-Fi, Bluetooth, battery,
// audio, Do Not Disturb and the dark appearance. [SystemBackend] is the interface the panes
// use; [DaemonBackend] talks to the daemon over the embedder's silica/dbus channel, tests use
// a fake.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'dbus.dart';

const String systemName = 'dev.frascella.Silica';
const String systemPath = '/dev/frascella/Silica/System1';
const String systemInterface = 'dev.frascella.Silica.System1';

/// A snapshot of the system state. Missing sources have `available` false; [reachable] is
/// false when the daemon itself does not answer.
@immutable
class SystemState {
  const SystemState({
    this.reachable = false,
    this.wifiAvailable = false,
    this.wifiEnabled = false,
    this.wifiSsid = '',
    this.wifiStrength = 0,
    this.wired = false,
    this.bluetoothAvailable = false,
    this.bluetoothPowered = false,
    this.batteryPresent = false,
    this.batteryPercent = 0,
    this.batteryCharging = false,
    this.audioAvailable = false,
    this.volume = 0,
    this.muted = false,
    this.audioName = '',
    this.doNotDisturb = false,
    this.dark = false,
  });

  final bool reachable;
  final bool wifiAvailable;
  final bool wifiEnabled;
  final String wifiSsid;
  final int wifiStrength;
  final bool wired;
  final bool bluetoothAvailable;
  final bool bluetoothPowered;
  final bool batteryPresent;
  final double batteryPercent;
  final bool batteryCharging;
  final bool audioAvailable;
  final double volume;
  final bool muted;
  final String audioName;
  final bool doNotDisturb;
  final bool dark;

  /// From the daemon's `State()` dictionary (flat keys).
  static SystemState fromDict(Map<Object?, Object?> d) {
    bool flag(String key) => d[key] == true;
    double number(String key) {
      final value = d[key];
      return value is num && value.isFinite ? value.toDouble() : 0;
    }

    String text(String key) => d[key] is String ? d[key] as String : '';

    return SystemState(
      reachable: true,
      wifiAvailable: flag('wifi.available'),
      wifiEnabled: flag('wifi.enabled'),
      wifiSsid: text('wifi.ssid'),
      wifiStrength: number('wifi.strength').round().clamp(0, 100),
      wired: flag('wifi.wired'),
      bluetoothAvailable: flag('bluetooth.available'),
      bluetoothPowered: flag('bluetooth.powered'),
      batteryPresent: flag('battery.present'),
      batteryPercent: number('battery.percent').clamp(0, 100).toDouble(),
      batteryCharging: flag('battery.charging'),
      audioAvailable: flag('audio.available'),
      volume: number('audio.volume').clamp(0, 1).toDouble(),
      muted: flag('audio.muted'),
      audioName: text('audio.name'),
      doNotDisturb: flag('dnd'),
      dark: flag('appearance.dark'),
    );
  }
}

/// A Wi-Fi network as the daemon lists it.
@immutable
class WifiNetwork {
  const WifiNetwork({
    required this.ssid,
    required this.strength,
    required this.secured,
    required this.saved,
    required this.inUse,
  });

  final String ssid;
  final int strength;
  final bool secured;
  final bool saved;
  final bool inUse;
}

/// A paired Bluetooth device.
@immutable
class BluetoothDevice {
  const BluetoothDevice({
    required this.address,
    required this.name,
    required this.icon,
    required this.connected,
  });

  final String address;
  final String name;

  /// The BlueZ icon name (`audio-headphones`, `input-mouse`…).
  final String icon;
  final bool connected;
}

/// An audio output.
@immutable
class AudioOutput {
  const AudioOutput({
    required this.id,
    required this.name,
    required this.isDefault,
  });

  final int id;
  final String name;
  final bool isDefault;
}

/// What Settings reads and changes in the system.
abstract class SystemBackend {
  /// The current state, then every change.
  Stream<SystemState> get states;

  Future<SystemState> state();

  Future<void> setDark(bool dark);
  Future<void> setWifiEnabled(bool enabled);
  Future<List<WifiNetwork>> wifiNetworks();

  /// Only saved networks: a new network needs a password, which the daemon cannot take yet.
  Future<void> connectWifi(String ssid);
  Future<void> setBluetoothPowered(bool powered);
  Future<List<BluetoothDevice>> bluetoothDevices();
  Future<void> connectBluetooth(String address, {required bool connect});
  Future<void> setVolume(double volume);
  Future<void> setMuted(bool muted);
  Future<List<AudioOutput>> audioOutputs();
  Future<void> setAudioOutput(int id);
  Future<void> setDoNotDisturb(bool enabled);

  /// "Play interface sound effects" (`dev.frascella.Silica.Sound1`); null when the daemon
  /// has no sound service.
  Future<bool?> uiSoundsEnabled();
  Future<void> setUiSoundsEnabled(bool enabled);
}

/// silica-daemon over D-Bus. Errors (no daemon, a missing source) become an unreachable state
/// or empty lists: Settings shows what it can, never crashes.
class DaemonBackend implements SystemBackend {
  DaemonBackend({DBus? bus}) : _bus = bus ?? DBus.instance;

  final DBus _bus;
  StreamController<SystemState>? _controller;
  StreamSubscription<DBusSignal>? _signals;

  Future<List<Object?>> _call(
    String method, {
    String signature = '',
    List<Object?> args = const [],
  }) => _bus.call(
    destination: systemName,
    path: systemPath,
    interface: systemInterface,
    method: method,
    signature: signature,
    args: args,
  );

  @override
  Future<SystemState> state() async {
    try {
      final reply = await _call('State');
      final first = reply.isEmpty ? null : reply.first;
      return first is Map ? SystemState.fromDict(first) : const SystemState();
    } on PlatformException {
      return const SystemState();
    } on MissingPluginException {
      return const SystemState();
    }
  }

  @override
  Stream<SystemState> get states {
    final existing = _controller;
    if (existing != null) return existing.stream;
    late final StreamController<SystemState> controller;
    controller = StreamController<SystemState>.broadcast(
      onListen: () async {
        controller.add(await state());
        _signals = _bus
            .signals(
              sender: systemName,
              path: systemPath,
              interface: systemInterface,
              member: 'Changed',
            )
            .listen(
              (signal) {
                final first = signal.args.isEmpty ? null : signal.args.first;
                if (first is Map) controller.add(SystemState.fromDict(first));
              },
              onError: (Object _) {
                // No signals outside Silica: the snapshot read at the start stays.
              },
            );
      },
      onCancel: () async {
        await _signals?.cancel();
        _signals = null;
        _controller = null;
      },
    );
    _controller = controller;
    return controller.stream;
  }

  Future<void> _set(String method, String signature, Object? value) async {
    try {
      await _call(method, signature: signature, args: [value]);
    } on PlatformException {
      // A missing source: the state stays as the daemon reports it.
    } on MissingPluginException {
      // Outside Silica.
    }
  }

  Future<List<Object?>> _list(String method) async {
    try {
      final reply = await _call(method);
      final first = reply.isEmpty ? null : reply.first;
      return first is List ? first : const [];
    } on PlatformException {
      return const [];
    } on MissingPluginException {
      return const [];
    }
  }

  @override
  Future<void> setDark(bool dark) => _set('SetDark', 'b', dark);

  @override
  Future<void> setWifiEnabled(bool enabled) =>
      _set('SetWifiEnabled', 'b', enabled);

  @override
  Future<List<WifiNetwork>> wifiNetworks() async => [
    for (final row in await _list('WifiNetworks'))
      if (row is List && row.length >= 5)
        WifiNetwork(
          ssid: '${row[0]}',
          strength: row[1] is num ? (row[1] as num).round().clamp(0, 100) : 0,
          secured: row[2] == true,
          saved: row[3] == true,
          inUse: row[4] == true,
        ),
  ];

  @override
  Future<void> connectWifi(String ssid) => _set('ConnectWifi', 's', ssid);

  @override
  Future<void> setBluetoothPowered(bool powered) =>
      _set('SetBluetoothPowered', 'b', powered);

  @override
  Future<List<BluetoothDevice>> bluetoothDevices() async => [
    for (final row in await _list('BluetoothDevices'))
      if (row is List && row.length >= 4)
        BluetoothDevice(
          address: '${row[0]}',
          name: '${row[1]}',
          icon: '${row[2]}',
          connected: row[3] == true,
        ),
  ];

  @override
  Future<void> connectBluetooth(String address, {required bool connect}) async {
    try {
      await _call(
        'ConnectBluetooth',
        signature: 'sb',
        args: [address, connect],
      );
    } on PlatformException {
      // The device did not answer: the list shows its real state on the next read.
    } on MissingPluginException {
      // Outside Silica.
    }
  }

  @override
  Future<void> setVolume(double volume) =>
      _set('SetVolume', 'd', volume.clamp(0, 1).toDouble());

  @override
  Future<void> setMuted(bool muted) => _set('SetMuted', 'b', muted);

  @override
  Future<List<AudioOutput>> audioOutputs() async => [
    for (final row in await _list('AudioOutputs'))
      if (row is List && row.length >= 3 && row[0] is num)
        AudioOutput(
          id: (row[0] as num).toInt(),
          name: '${row[1]}',
          isDefault: row[2] == true,
        ),
  ];

  @override
  Future<void> setAudioOutput(int id) => _set('SetAudioOutput', 'u', id);

  @override
  Future<void> setDoNotDisturb(bool enabled) =>
      _set('SetDoNotDisturb', 'b', enabled);

  static const String _soundPath = '/dev/frascella/Silica/Sound1';
  static const String _soundInterface = 'dev.frascella.Silica.Sound1';

  @override
  Future<bool?> uiSoundsEnabled() async {
    try {
      final reply = await _bus.call(
        destination: systemName,
        path: _soundPath,
        interface: _soundInterface,
        method: 'UiSoundsEnabled',
      );
      final first = reply.isEmpty ? null : reply.first;
      return first is bool ? first : null;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<void> setUiSoundsEnabled(bool enabled) async {
    try {
      await _bus.call(
        destination: systemName,
        path: _soundPath,
        interface: _soundInterface,
        method: 'SetUiSoundsEnabled',
        signature: 'b',
        args: [enabled],
      );
    } on PlatformException {
      // No sound service: the switch reads the state again.
    } on MissingPluginException {
      // Outside Silica.
    }
  }
}
