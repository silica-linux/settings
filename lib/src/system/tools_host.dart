// The real [SystemTools]: the command-line tools of NetworkManager, PipeWire and systemd, run
// as the user (polkit decides what they may change), and BlueZ, power-profiles-daemon, UPower
// and silica-daemon's notification history over D-Bus. The parsers are static and tested on
// sample outputs.

import 'dart:io';

import 'package:flutter/services.dart';

import 'dbus.dart';
import 'tools.dart';

/// What a program printed and how it ended.
class CommandResult {
  const CommandResult(this.exitCode, this.stdout, this.stderr);

  /// The program could not start (not installed).
  const CommandResult.missing() : exitCode = -1, stdout = '', stderr = '';

  final int exitCode;
  final String stdout;
  final String stderr;

  bool get ok => exitCode == 0;
  bool get missing => exitCode == -1;
}

typedef ProcessRunner =
    Future<CommandResult> Function(String executable, List<String> arguments);

Future<CommandResult> runProcess(
  String executable,
  List<String> arguments,
) async {
  try {
    final result = await Process.run(
      executable,
      arguments,
      // The tools' messages in English, whatever the session's language: they are parsed.
      environment: const {'LC_ALL': 'C'},
    );
    return CommandResult(
      result.exitCode,
      '${result.stdout}',
      '${result.stderr}',
    );
  } on ProcessException {
    return const CommandResult.missing();
  }
}

/// The error for a failed run: polkit's "interactive authentication required", a refusal
/// (wrong password, network not found), or anything else.
ToolError errorOf(CommandResult r) {
  if (r.missing) return const ToolError(ToolErrorKind.missing);
  final text = '${r.stderr}\n${r.stdout}'.trim();
  final lower = text.toLowerCase();
  if (lower.contains('authentication') ||
      lower.contains('not authorized') ||
      lower.contains('access denied') ||
      lower.contains('permission denied') ||
      lower.contains('insufficient privileges')) {
    return ToolError(ToolErrorKind.authentication, text);
  }
  if (lower.contains('secrets were required') ||
      lower.contains('no network with ssid') ||
      lower.contains('invalid') ||
      lower.contains('activation failed')) {
    return ToolError(ToolErrorKind.refused, text);
  }
  return ToolError(ToolErrorKind.failed, text);
}

/// The D-Bus errors of a refused change.
ToolError dbusError(PlatformException e) {
  final code = e.code;
  if (code.contains('ServiceUnknown') ||
      code.contains('UnknownObject') ||
      code.contains('UnknownMethod') ||
      code.contains('NotSupported')) {
    return ToolError(ToolErrorKind.missing, '${e.message ?? code}');
  }
  if (code.contains('AccessDenied') ||
      code.contains('InteractiveAuthorizationRequired') ||
      code.contains('NotAuthorized')) {
    return ToolError(ToolErrorKind.authentication, '${e.message ?? code}');
  }
  if (code.contains('AuthenticationFailed') ||
      code.contains('AuthenticationRejected') ||
      code.contains('AuthenticationCanceled')) {
    return ToolError(ToolErrorKind.refused, '${e.message ?? code}');
  }
  return ToolError(ToolErrorKind.failed, '${e.message ?? code}');
}

class HostSystemTools implements SystemTools {
  HostSystemTools({
    this.run = runProcess,
    DBus? bus,
    Map<String, String>? env,
    this.root = '',
  }) : _bus = bus,
       env = env ?? Platform.environment;

  final ProcessRunner run;
  final DBus? _bus;
  final Map<String, String> env;

  /// A folder standing for `/` (tests); empty for the machine.
  final String root;

  DBus get bus => _bus ?? DBus.instance;

  Future<ToolError?> _change(String executable, List<String> arguments) async {
    final r = await run(executable, arguments);
    return r.ok ? null : errorOf(r);
  }

  Future<String?> _out(String executable, List<String> arguments) async {
    final r = await run(executable, arguments);
    return r.ok ? r.stdout : null;
  }

  // Network ------------------------------------------------------------------------------

  /// Splits a line of `nmcli -t` on the colons that are not escaped (`\:`).
  static List<String> splitTerse(String line) {
    final fields = <String>[];
    final current = StringBuffer();
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == r'\' && i + 1 < line.length) {
        current.write(line[i + 1]);
        i++;
      } else if (c == ':') {
        fields.add(current.toString());
        current.clear();
      } else {
        current.write(c);
      }
    }
    fields.add(current.toString());
    return fields;
  }

  /// `nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list`: one row per network name, the
  /// strongest access point kept, hidden networks left out.
  static List<AccessPoint> parseAccessPoints(String text) {
    final byName = <String, AccessPoint>{};
    for (final line in text.split('\n')) {
      final f = splitTerse(line);
      if (f.length < 4 || f[1].isEmpty) continue;
      final ap = AccessPoint(
        ssid: f[1],
        strength: (int.tryParse(f[2]) ?? 0).clamp(0, 100),
        security: f[3] == '--' ? '' : f[3],
        inUse: f[0].trim() == '*',
      );
      final known = byName[ap.ssid];
      if (known == null ||
          ap.inUse ||
          (!known.inUse && ap.strength > known.strength)) {
        byName[ap.ssid] = ap;
      }
    }
    final list = byName.values.toList()
      ..sort((a, b) {
        if (a.inUse != b.inUse) return a.inUse ? -1 : 1;
        return b.strength.compareTo(a.strength);
      });
    return list;
  }

  @override
  Future<List<AccessPoint>> accessPoints({bool rescan = false}) async {
    final out = await _out('nmcli', [
      '-t',
      '-f',
      'IN-USE,SSID,SIGNAL,SECURITY',
      'device',
      'wifi',
      'list',
      '--rescan',
      rescan ? 'yes' : 'auto',
    ]);
    return out == null ? const [] : parseAccessPoints(out);
  }

  /// `nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device`.
  static List<NetworkDevice> parseDevices(String text) => [
    for (final line in text.split('\n'))
      if (splitTerse(line) case final f when f.length >= 4 && f[0].isNotEmpty)
        NetworkDevice(name: f[0], type: f[1], state: f[2], connection: f[3]),
  ];

  @override
  Future<List<NetworkDevice>> networkDevices() async {
    final out = await _out('nmcli', [
      '-t',
      '-f',
      'DEVICE,TYPE,STATE,CONNECTION',
      'device',
    ]);
    return out == null ? const [] : parseDevices(out);
  }

  /// `nmcli -t device show DEV`: `FIELD:value` lines (`IP4.ADDRESS[1]:…`).
  static DeviceDetails parseDetails(String text) {
    String hw = '', gateway = '';
    final ipv4 = <String>[], dns = <String>[], ipv6 = <String>[];
    for (final line in text.split('\n')) {
      final at = line.indexOf(':');
      if (at < 0) continue;
      final key = line.substring(0, at);
      final value = line.substring(at + 1).replaceAll(r'\:', ':').trim();
      if (value.isEmpty || value == '--') continue;
      if (key == 'GENERAL.HWADDR') hw = value;
      if (key.startsWith('IP4.ADDRESS')) ipv4.add(value);
      if (key == 'IP4.GATEWAY') gateway = value;
      if (key.startsWith('IP4.DNS')) dns.add(value);
      if (key.startsWith('IP6.ADDRESS') && !value.startsWith('fe80')) {
        ipv6.add(value);
      }
    }
    return DeviceDetails(
      hardwareAddress: hw,
      ipv4: ipv4,
      gateway: gateway,
      dns: dns,
      ipv6: ipv6,
    );
  }

  @override
  Future<DeviceDetails> deviceDetails(String device) async {
    final out = await _out('nmcli', ['-t', 'device', 'show', device]);
    return out == null ? const DeviceDetails() : parseDetails(out);
  }

  /// `nmcli -t -f NAME,TYPE,ACTIVE,AUTOCONNECT connection show`.
  static List<SavedConnection> parseConnections(String text) => [
    for (final line in text.split('\n'))
      if (splitTerse(line) case final f when f.length >= 4 && f[0].isNotEmpty)
        SavedConnection(
          name: f[0],
          type: f[1],
          active: f[2] == 'yes',
          autoconnect: f[3] != 'no',
        ),
  ];

  @override
  Future<List<SavedConnection>> savedConnections() async {
    final out = await _out('nmcli', [
      '-t',
      '-f',
      'NAME,TYPE,ACTIVE,AUTOCONNECT',
      'connection',
      'show',
    ]);
    return out == null ? const [] : parseConnections(out);
  }

  @override
  Future<ToolError?> joinWifi(String ssid, {String? password}) =>
      _change('nmcli', [
        'device',
        'wifi',
        'connect',
        ssid,
        if (password != null && password.isNotEmpty) ...['password', password],
      ]);

  @override
  Future<ToolError?> disconnect(String device) =>
      _change('nmcli', ['device', 'disconnect', device]);

  @override
  Future<ToolError?> forgetConnection(String name) =>
      _change('nmcli', ['connection', 'delete', 'id', name]);

  @override
  Future<ToolError?> setAutoconnect(String name, bool enabled) =>
      _change('nmcli', [
        'connection',
        'modify',
        'id',
        name,
        'connection.autoconnect',
        enabled ? 'yes' : 'no',
      ]);

  @override
  Future<ToolError?> setConnectionActive(String name, bool active) =>
      _change('nmcli', ['connection', active ? 'up' : 'down', 'id', name]);

  // Audio --------------------------------------------------------------------------------

  /// The `Sinks:` and `Sources:` of the `Audio` section of `wpctl status`; `*` marks the
  /// default, `[vol: 0.40 MUTED]` the volume.
  static AudioDevices parseWpctlStatus(String text) {
    final outputs = <AudioDevice>[], inputs = <AudioDevice>[];
    var inAudio = false;
    String section = '';
    final entry = RegExp(
      r'^(\*)?\s*(\d+)\.\s+(.*?)\s*(?:\[vol:\s*([\d.]+)(\s+MUTED)?\])?\s*$',
    );
    for (final line in text.split('\n')) {
      if (line.isEmpty) continue;
      if (!' │├└'.contains(line[0])) {
        inAudio = line.trim() == 'Audio';
        section = '';
        continue;
      }
      if (!inAudio) continue;
      final body = line.replaceFirst(RegExp(r'^[\s│├└─]+'), '');
      if (body.endsWith(':')) {
        section = body;
        continue;
      }
      if (section != 'Sinks:' && section != 'Sources:') continue;
      final m = entry.firstMatch(body);
      if (m == null) continue;
      final name = m.group(3)?.trim() ?? '';
      if (name.isEmpty) continue;
      final device = AudioDevice(
        id: int.parse(m.group(2)!),
        name: name,
        isDefault: m.group(1) != null,
        volume: (double.tryParse(m.group(4) ?? '') ?? 0).clamp(0, 1),
        muted: m.group(5) != null,
      );
      (section == 'Sinks:' ? outputs : inputs).add(device);
    }
    return AudioDevices(outputs: outputs, inputs: inputs);
  }

  @override
  Future<AudioDevices> audioDevices() async {
    final out = await _out('wpctl', ['status']);
    return out == null ? const AudioDevices() : parseWpctlStatus(out);
  }

  @override
  Future<ToolError?> setDefaultAudio(int id) =>
      _change('wpctl', ['set-default', '$id']);

  @override
  Future<ToolError?> setAudioVolume(int id, double volume) => _change('wpctl', [
    'set-volume',
    '$id',
    volume.clamp(0, 1).toStringAsFixed(2),
  ]);

  @override
  Future<ToolError?> setAudioMuted(int id, bool muted) =>
      _change('wpctl', ['set-mute', '$id', muted ? '1' : '0']);

  // Date and time ------------------------------------------------------------------------

  /// `timedatectl show`: `Key=value` lines.
  static ClockState parseTimedatectl(String text) {
    final v = _keyValues(text);
    return ClockState(
      timezone: v['Timezone'] ?? '',
      ntp: v['NTP'] == 'yes',
      canNtp: v['CanNTP'] == 'yes',
      synchronized: v['NTPSynchronized'] == 'yes',
    );
  }

  static Map<String, String> _keyValues(String text) => {
    for (final line in text.split('\n'))
      if (line.contains('='))
        line.substring(0, line.indexOf('=')).trim(): line
            .substring(line.indexOf('=') + 1)
            .trim(),
  };

  @override
  Future<ClockState> clock() async {
    final out = await _out('timedatectl', ['show']);
    return out == null ? const ClockState() : parseTimedatectl(out);
  }

  @override
  Future<List<String>> timezones() async {
    final cached = _timezones;
    if (cached != null) return cached;
    final list = await _listTimezones();
    // A failed read is not kept: the next ask tries again.
    if (list.isNotEmpty) _timezones = list;
    return list;
  }

  List<String>? _timezones;

  Future<List<String>> _listTimezones() async {
    final out = await _out('timedatectl', ['list-timezones']);
    return out == null
        ? const []
        : [
            for (final z in out.split('\n'))
              if (z.trim().isNotEmpty) z.trim(),
          ];
  }

  @override
  Future<ToolError?> setTimezone(String zone) =>
      _change('timedatectl', ['set-timezone', zone]);

  @override
  Future<ToolError?> setNtp(bool enabled) =>
      _change('timedatectl', ['set-ntp', enabled ? 'true' : 'false']);

  // Computer name -------------------------------------------------------------------------

  @override
  Future<String> computerName() async {
    final pretty = (await _out('hostnamectl', ['--pretty']))?.trim() ?? '';
    if (pretty.isNotEmpty) return pretty;
    final name = (await _out('hostnamectl', ['hostname']))?.trim() ?? '';
    if (name.isNotEmpty) return name;
    try {
      return File('$root/etc/hostname').readAsStringSync().trim();
    } on FileSystemException {
      return '';
    }
  }

  /// The host name for a computer name: lower case letters, digits and dashes.
  static String hostnameFor(String name) {
    final ascii = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return ascii.isEmpty
        ? 'silica'
        : ascii.substring(0, ascii.length.clamp(0, 63));
  }

  @override
  Future<ToolError?> setComputerName(String name) async {
    final pretty = await _change('hostnamectl', [
      'set-hostname',
      '--pretty',
      name,
    ]);
    if (pretty != null) return pretty;
    return _change('hostnamectl', [
      'set-hostname',
      '--static',
      hostnameFor(name),
    ]);
  }

  // Language and region ------------------------------------------------------------------

  /// `localectl status`: `System Locale: LANG=en_US.UTF-8` and the `LC_*` lines under it.
  static LocaleState parseLocalectl(String text) {
    final values = <String, String>{};
    for (final line in text.split('\n')) {
      final m = RegExp(r'(LANG|LC_[A-Z]+)=(\S+)').firstMatch(line);
      if (m != null) values[m.group(1)!] = m.group(2)!;
    }
    final language = values['LANG'] ?? '';
    final time = values['LC_TIME'] ?? '';
    return LocaleState(
      language: language,
      formats: time == language ? '' : time,
    );
  }

  @override
  Future<LocaleState> locale() async {
    final out = await _out('localectl', ['status']);
    return out == null ? const LocaleState() : parseLocalectl(out);
  }

  @override
  Future<List<String>> locales() async {
    final cached = _locales;
    if (cached != null) return cached;
    final list = await _listLocales();
    // A failed read is not kept: the next ask tries again.
    if (list.isNotEmpty) _locales = list;
    return list;
  }

  List<String>? _locales;

  Future<List<String>> _listLocales() async {
    final out = await _out('localectl', ['list-locales']);
    return out == null
        ? const []
        : [
            for (final l in out.split('\n'))
              if (l.trim().isNotEmpty && l.trim() != 'C.UTF-8') l.trim(),
          ];
  }

  /// The categories a region sets: dates and times, numbers, currency, measures, paper.
  static const List<String> formatCategories = [
    'LC_TIME',
    'LC_NUMERIC',
    'LC_MONETARY',
    'LC_MEASUREMENT',
    'LC_PAPER',
  ];

  @override
  Future<ToolError?> setLocale({
    required String language,
    String formats = '',
  }) => _change('localectl', [
    'set-locale',
    'LANG=$language',
    if (formats.isNotEmpty && formats != language)
      for (final c in formatCategories) '$c=$formats',
  ]);

  // Bluetooth (BlueZ on the system bus) ---------------------------------------------------

  static const String _bluez = 'org.bluez';

  Future<Map<Object?, Object?>> _bluezObjects() async {
    final reply = await bus.call(
      bus: DBusBus.system,
      destination: _bluez,
      path: '/',
      interface: 'org.freedesktop.DBus.ObjectManager',
      method: 'GetManagedObjects',
    );
    final first = reply.isEmpty ? null : reply.first;
    return first is Map ? first : const {};
  }

  /// The devices in BlueZ's managed objects (`Device1`, with `Battery1` when present).
  static List<BluetoothPeer> parseBluezObjects(Map<Object?, Object?> objects) {
    final peers = <BluetoothPeer>[];
    for (final MapEntry(:key, :value) in objects.entries) {
      if (value is! Map) continue;
      final device = value['org.bluez.Device1'];
      if (device is! Map) continue;
      final battery = value['org.bluez.Battery1'];
      final address = '${device['Address'] ?? ''}';
      final name = '${device['Alias'] ?? device['Name'] ?? ''}';
      peers.add(
        BluetoothPeer(
          path: '$key',
          address: address,
          name: name.isEmpty ? address : name,
          icon: '${device['Icon'] ?? ''}',
          paired: device['Paired'] == true,
          connected: device['Connected'] == true,
          battery: battery is Map && battery['Percentage'] is num
              ? (battery['Percentage'] as num).round()
              : null,
        ),
      );
    }
    peers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return peers;
  }

  @override
  Future<List<BluetoothPeer>> bluetoothPeers() async {
    try {
      return parseBluezObjects(await _bluezObjects());
    } on PlatformException {
      return const [];
    } on MissingPluginException {
      return const [];
    }
  }

  Future<String?> _adapter() async {
    try {
      final objects = await _bluezObjects();
      for (final MapEntry(:key, :value) in objects.entries) {
        if (value is Map && value['org.bluez.Adapter1'] is Map) return '$key';
      }
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
    return null;
  }

  Future<ToolError?> _bluezCall(
    String path,
    String interface,
    String method, {
    String signature = '',
    List<Object?> args = const [],
  }) async {
    try {
      await bus.call(
        bus: DBusBus.system,
        destination: _bluez,
        path: path,
        interface: interface,
        method: method,
        signature: signature,
        args: args,
      );
      return null;
    } on PlatformException catch (e) {
      return dbusError(e);
    } on MissingPluginException {
      return const ToolError(ToolErrorKind.missing);
    }
  }

  @override
  Future<ToolError?> setBluetoothDiscovery(bool discovering) async {
    final adapter = await _adapter();
    if (adapter == null) return const ToolError(ToolErrorKind.missing);
    return _bluezCall(
      adapter,
      'org.bluez.Adapter1',
      discovering ? 'StartDiscovery' : 'StopDiscovery',
    );
  }

  @override
  Future<ToolError?> pairBluetooth(String path) async {
    final paired = await _bluezCall(path, 'org.bluez.Device1', 'Pair');
    if (paired != null) return paired;
    // A paired device is trusted so it reconnects by itself, then connected.
    await _bluezCall(
      path,
      'org.freedesktop.DBus.Properties',
      'Set',
      signature: 'ssv',
      args: ['org.bluez.Device1', 'Trusted', true],
    );
    return _bluezCall(path, 'org.bluez.Device1', 'Connect');
  }

  @override
  Future<ToolError?> connectBluetooth(String path, bool connect) =>
      _bluezCall(path, 'org.bluez.Device1', connect ? 'Connect' : 'Disconnect');

  @override
  Future<ToolError?> forgetBluetooth(String path) async {
    final adapter = path.contains('/dev_')
        ? path.substring(0, path.indexOf('/dev_'))
        : await _adapter();
    if (adapter == null) return const ToolError(ToolErrorKind.missing);
    return _bluezCall(
      adapter,
      'org.bluez.Adapter1',
      'RemoveDevice',
      signature: 'o',
      args: [path],
    );
  }

  // Power -------------------------------------------------------------------------------

  static const String _profilesName = 'org.freedesktop.UPower.PowerProfiles';
  static const String _profilesPath = '/org/freedesktop/UPower/PowerProfiles';

  static PowerProfile? profileNamed(String name) => switch (name) {
    'power-saver' => PowerProfile.powerSaver,
    'balanced' => PowerProfile.balanced,
    'performance' => PowerProfile.performance,
    _ => null,
  };

  static String profileName(PowerProfile p) => switch (p) {
    PowerProfile.powerSaver => 'power-saver',
    PowerProfile.balanced => 'balanced',
    PowerProfile.performance => 'performance',
  };

  @override
  Future<PowerState> power() async {
    var profiles = <PowerProfile>[];
    PowerProfile? active;
    try {
      final props = await bus.getAll(
        bus: DBusBus.system,
        destination: _profilesName,
        path: _profilesPath,
        interface: _profilesName,
      );
      active = profileNamed('${props['ActiveProfile'] ?? ''}');
      final list = props['Profiles'];
      if (list is List) {
        profiles = [
          for (final p in list)
            if (p is Map) ?profileNamed('${p['Profile'] ?? ''}'),
        ]..sort((a, b) => a.index.compareTo(b.index));
      }
    } on PlatformException {
      // No power-profiles-daemon.
    } on MissingPluginException {
      // Outside Silica.
    }
    var toEmpty = 0, toFull = 0;
    var capacity = 0.0;
    try {
      final display = await bus.getAll(
        bus: DBusBus.system,
        destination: 'org.freedesktop.UPower',
        path: '/org/freedesktop/UPower/devices/DisplayDevice',
        interface: 'org.freedesktop.UPower.Device',
      );
      toEmpty = (display['TimeToEmpty'] as num?)?.toInt() ?? 0;
      toFull = (display['TimeToFull'] as num?)?.toInt() ?? 0;
      final reply = await bus.call(
        bus: DBusBus.system,
        destination: 'org.freedesktop.UPower',
        path: '/org/freedesktop/UPower',
        interface: 'org.freedesktop.UPower',
        method: 'EnumerateDevices',
      );
      final paths = reply.isEmpty ? null : reply.first;
      if (paths is List) {
        for (final path in paths) {
          if (!'$path'.contains('battery')) continue;
          final battery = await bus.getAll(
            bus: DBusBus.system,
            destination: 'org.freedesktop.UPower',
            path: '$path',
            interface: 'org.freedesktop.UPower.Device',
          );
          final c = battery['Capacity'];
          if (c is num && c > 0) capacity = c.toDouble().clamp(0, 100);
          break;
        }
      }
    } on PlatformException {
      // No UPower.
    } on MissingPluginException {
      // Outside Silica.
    }
    return PowerState(
      profiles: profiles,
      active: active,
      secondsToEmpty: toEmpty,
      secondsToFull: toFull,
      capacity: capacity,
    );
  }

  @override
  Future<ToolError?> setPowerProfile(PowerProfile profile) async {
    try {
      await bus.call(
        bus: DBusBus.system,
        destination: _profilesName,
        path: _profilesPath,
        interface: 'org.freedesktop.DBus.Properties',
        method: 'Set',
        signature: 'ssv',
        args: [_profilesName, 'ActiveProfile', profileName(profile)],
      );
      return null;
    } on PlatformException catch (e) {
      return dbusError(e);
    } on MissingPluginException {
      return const ToolError(ToolErrorKind.missing);
    }
  }

  // Default apps ------------------------------------------------------------------------

  List<String> get _applicationDirs {
    final home = env['HOME'] ?? '';
    final dataHome = env['XDG_DATA_HOME'] ?? '$home/.local/share';
    final dirs = env['XDG_DATA_DIRS'] ?? '/usr/local/share:/usr/share';
    return [
      '$dataHome/applications',
      for (final d in dirs.split(':'))
        if (d.isNotEmpty) '$d/applications',
      '$root/var/lib/flatpak/exports/share/applications',
      '$home/.local/share/flatpak/exports/share/applications',
    ];
  }

  /// A desktop entry's `[Desktop Entry]` keys.
  static Map<String, String> parseDesktopEntry(String text) {
    final keys = <String, String>{};
    var inEntry = false;
    for (final line in text.split('\n')) {
      final t = line.trim();
      if (t.startsWith('[')) {
        inEntry = t == '[Desktop Entry]';
        continue;
      }
      if (!inEntry || !t.contains('=') || t.startsWith('#')) continue;
      final key = t.substring(0, t.indexOf('=')).trim();
      keys.putIfAbsent(key, () => t.substring(t.indexOf('=') + 1).trim());
    }
    return keys;
  }

  @override
  Future<List<AppEntry>> browsers() async {
    final cached = _browsers;
    if (cached != null) return cached;
    final list = _listBrowsers();
    if (list.isNotEmpty) _browsers = list;
    return list;
  }

  List<AppEntry>? _browsers;

  List<AppEntry> _listBrowsers() {
    final found = <String, AppEntry>{};
    for (final dir in _applicationDirs) {
      try {
        final d = Directory(dir);
        if (!d.existsSync()) continue;
        for (final f in d.listSync()) {
          final id = f.path.split('/').last;
          if (f is! File || !id.endsWith('.desktop') || found.containsKey(id)) {
            continue;
          }
          final keys = parseDesktopEntry(f.readAsStringSync());
          final mime = keys['MimeType'] ?? '';
          if (keys['NoDisplay'] == 'true' || keys['Hidden'] == 'true') continue;
          if (!mime.contains('x-scheme-handler/http')) continue;
          found[id] = AppEntry(id: id, name: keys['Name'] ?? id);
        }
      } on FileSystemException {
        continue;
      }
    }
    return found.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  Future<String> defaultBrowser() async =>
      (await _out('xdg-settings', ['get', 'default-web-browser']))?.trim() ??
      '';

  @override
  Future<ToolError?> setDefaultBrowser(String id) =>
      _change('xdg-settings', ['set', 'default-web-browser', id]);

  // Displays and accounts -----------------------------------------------------------------

  @override
  Future<List<DisplayOutput>> displays() async {
    final outputs = <DisplayOutput>[];
    try {
      final drm = Directory('$root/sys/class/drm');
      if (!drm.existsSync()) return const [];
      final entries = drm.listSync().map((e) => e.path).toList()..sort();
      for (final path in entries) {
        final name = path.split('/').last;
        // card0-HDMI-A-1: a connector.
        final dash = name.indexOf('-');
        if (!name.startsWith('card') || dash < 0) continue;
        String read(String file) {
          try {
            return File('$path/$file').readAsStringSync().trim();
          } on FileSystemException {
            return '';
          }
        }

        if (read('status') != 'connected') continue;
        final modes = <String>[];
        for (final m in read('modes').split('\n')) {
          if (m.isNotEmpty && !modes.contains(m)) modes.add(m);
        }
        outputs.add(
          DisplayOutput(
            connector: name.substring(dash + 1),
            modes: modes,
            enabled: read('enabled') != 'disabled',
          ),
        );
      }
    } on FileSystemException {
      return outputs;
    }
    return outputs;
  }

  /// People's accounts in passwd (uid 1000–59999 with a login shell); administrators are the
  /// members of `wheel` or `sudo` in group.
  static List<UserAccount> parseUsers(String passwd, String group) {
    final admins = <String>{};
    for (final line in group.split('\n')) {
      final f = line.split(':');
      if (f.length >= 4 && (f[0] == 'wheel' || f[0] == 'sudo')) {
        admins.addAll(f[3].split(',').where((s) => s.isNotEmpty));
      }
    }
    return [
      for (final line in passwd.split('\n'))
        if (line.split(':') case final f
            when f.length >= 7 &&
                (int.tryParse(f[2]) ?? 0) >= 1000 &&
                (int.tryParse(f[2]) ?? 0) < 60000 &&
                !f[6].endsWith('nologin') &&
                !f[6].endsWith('false'))
          UserAccount(
            login: f[0],
            name: f[4].split(',').first.trim().isEmpty
                ? f[0]
                : f[4].split(',').first.trim(),
            uid: int.parse(f[2]),
            admin: admins.contains(f[0]),
          ),
    ];
  }

  @override
  Future<List<UserAccount>> users() async {
    String read(String path) {
      try {
        return File('$root$path').readAsStringSync();
      } on FileSystemException {
        return '';
      }
    }

    // passwd and group in /etc, and the image's own accounts in /usr/lib (bootc systems).
    return parseUsers(
      '${read('/etc/passwd')}\n${read('/usr/lib/passwd')}',
      '${read('/etc/group')}\n${read('/usr/lib/group')}',
    );
  }

  // Notifications -------------------------------------------------------------------------

  /// silica-daemon's history (`List() → a(ussssasysssbbti)`): one app per desktop entry (or
  /// name), newest first.
  static List<NotifyingApp> parseHistory(List<Object?> rows) {
    final apps = <String, NotifyingApp>{};
    for (final row in rows.reversed) {
      if (row is! List || row.length < 9) continue;
      final name = '${row[1]}';
      final icon = '${row[2]}';
      final entry = '${row[8]}';
      final key = entry.isNotEmpty ? entry : name;
      if (key.isEmpty) continue;
      apps.putIfAbsent(
        key,
        () =>
            NotifyingApp(key: key, name: name.isEmpty ? key : name, icon: icon),
      );
    }
    return apps.values.toList();
  }

  @override
  Future<List<NotifyingApp>> notifyingApps() async {
    try {
      final reply = await bus.call(
        destination: 'dev.frascella.Silica',
        path: '/dev/frascella/Silica/Notifications1',
        interface: 'dev.frascella.Silica.Notifications1',
        method: 'List',
      );
      final first = reply.isEmpty ? null : reply.first;
      return first is List ? parseHistory(first) : const [];
    } on PlatformException {
      return const [];
    } on MissingPluginException {
      return const [];
    }
  }
}
